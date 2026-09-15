# frozen_string_literal: true

require 'json'
require 'optparse'

module AgentWorkflows
  # Retains only usage metadata; transcripts and cumulative counters are discarded.
  class CodexUsage
    attr_reader :responses, :versions, :gaps

    def initialize(files, turns, all_turns: false)
      @responses = {}
      @all_turns = all_turns
      @versions = []
      @gaps = []
      files.each { |file| read(file, turns) }
    end

    def self.discover
      identity = ENV.fetch('CODEX_THREAD_ID', nil)
      return [] unless identity&.match?(/\A[0-9a-f-]{36}\z/)

      home = ENV.fetch('CODEX_HOME', File.expand_path('~/.codex'))
      files = Dir.glob(File.join(home, 'sessions', '*', '*', '*', "*#{identity}.jsonl"))
      return [] unless files.one?

      metadata = JSON.parse(File.open(files.first, &:readline))
      matching_source?(metadata, identity) ? files : []
    rescue JSON::ParserError, SystemCallError, EOFError
      []
    end

    def self.matching_source?(metadata, identity)
      metadata.is_a?(Hash) && metadata['type'] == 'session_meta' &&
        metadata['payload'].is_a?(Hash) && metadata['payload']['id'] == identity
    end

    private_class_method :matching_source?

    private

    def read(file, turns)
      @context = {}
      @provider = nil
      @records = []
      File.foreach(file) { |line| consume(parse(line)) }
      selected = selected_turns(turns)
      @gaps << 'Unreadable or unidentifiable records' if @all_turns && selected.size != @records.size
      @records.select { |record| selected.include?(record['turn_id']) }.each { |record| count(record) }
    rescue SystemCallError
      @gaps << 'Unreadable or unidentifiable records'
    end

    def selected_turns(turns)
      turns = @records.map { |record| record['turn_id'] } if @all_turns
      selected = turns.empty? ? [@context['turn_id']] : turns
      selected.grep(String).reject { |turn| turn.strip.empty? }
    end

    def consume(record)
      return unless record

      payload = record['payload']
      case record['type']
      when 'session_meta'
        @provider = payload['model_provider']
        @versions << payload['cli_version']
      when 'turn_context' then @context = payload.slice('turn_id', 'model', 'effort')
      when 'token_usage_record' then @records << response(record)
      end
    end

    def response(record)
      payload = record['payload']
      settings = payload['turn_id'] == @context['turn_id'] ? @context : {}
      payload.slice('response_id', 'turn_id', 'usage').merge(
        'timestamp' => record['timestamp'],
        'configuration' => [@provider, settings['model'], 'UNKNOWN', settings['effort']]
      )
    end

    def count(record)
      identity = record['response_id']
      return @gaps << 'Unreadable or unidentifiable records' unless identity.is_a?(String) && !identity.empty?

      previous = @responses[identity]
      if previous && previous != record
        previous.merge!('usage' => {}, 'configuration' => [nil] * 4, 'timestamp' => nil, 'turn_id' => nil)
        @gaps << 'Conflicting response copies'
      end
      @responses[identity] ||= record
    end

    def parse(line)
      record = JSON.parse(line)
      return record if record.is_a?(Hash) && record['payload'].is_a?(Hash)

      @gaps << 'Unreadable or unidentifiable records'
      nil
    rescue JSON::ParserError
      @gaps << 'Unreadable or unidentifiable records'
      nil
    end
  end

  # Read-only reporting of Codex's per-response native records.
  class Usage
    FIELDS = %w[input_tokens cached_input_tokens output_tokens reasoning_output_tokens
                cache_write_input_tokens total_tokens].freeze

    def self.run(arguments)
      options = { files: [], turns: [] }
      parser(options).parse!(arguments)
      puts parser(options) if options[:help]
      return 0 if options[:help]

      raise OptionParser::InvalidArgument unless arguments.empty? && valid_mapping?(options)

      puts new(options).report
      0
    rescue OptionParser::ParseError
      warn 'sw usage: invalid options; use sw usage --help'
      1
    end

    def self.parser(options)
      OptionParser.new do |flags|
        flags.banner = 'Usage: sw usage --commit SHA[,SHA] --contribution NAME [options]'
        source_options(flags, options)
        flags.on('--commit SHA', 'Affected full commit SHAs, comma separated') { |v| options[:commit] = v }
        flags.on('--contribution NAME', 'Contribution category (see guide)') { |v| options[:contribution] = v }
        flags.on('-h', '--help') { options[:help] = true }
      end
    end

    def self.source_options(flags, options)
      flags.on('--file PATH', 'Native JSONL; repeat for contributors/resumes') { |v| options[:files] << v }
      flags.on('--all-turns', 'Only for sources dedicated to this task') { options[:all_turns] = true }
      flags.on('--turn ID', 'Select a native turn; repeat for a shared interval') { |v| options[:turns] << v }
    end

    def self.valid_mapping?(options)
      commits = options[:commit].to_s.split(',')
      !(options[:all_turns] && options[:turns].any?) &&
        !commits.empty? && commits.all? { |commit| commit.match?(/\A[0-9a-f]{40}\z/) } &&
        %w[implementation review integration shared-planning].include?(options[:contribution])
    end

    def initialize(options)
      @options = options
      @inferred = options[:files].empty?
      @options[:files] = CodexUsage.discover if @inferred
      @source = CodexUsage.new(@options[:files], @options[:turns], all_turns: options[:all_turns])
      @responses = @source.responses.values
    end

    def report
      <<~MARKDOWN
        Native usage is PARTIAL. #{count}. Scope: #{turn_scope}.
        External reviewer/tool-model usage: UNKNOWN. #{@source.gaps.uniq.join('; ')}

        <details>
        <summary>Native usage</summary>

        #{@options[:commit]} / #{@options[:contribution]}
        SHARED source interval: #{interval}. Snapshot through the last observed response.
        Source selection: #{@inferred ? 'host context' : 'explicit files'}.
        Codex source versions: #{versions}.

        | Provider | Configured model | Routed model | Effort | Input | Cached input | Output | Reasoning output | Cache writes | Native total |
        | --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
        #{rows}

        </details>
      MARKDOWN
    end

    private

    def turn_scope
      return 'all turns in selected sources' if @options[:all_turns]

      @options[:turns].empty? ? 'latest turn only per source; earlier turns excluded' : 'explicitly selected turns'
    end

    def rows
      @responses.group_by { |record| record['configuration'] }.map do |configuration, group|
        "| #{(configuration.map { |value| safe(value) } + totals(group)).join(' | ')} |"
      end.join("\n")
    end

    def totals(group)
      FIELDS.map do |field|
        values = group.map { |record| record['usage'].is_a?(Hash) ? record['usage'][field] : nil }
        values.all? { |value| value.is_a?(Integer) && value >= 0 } ? values.sum : 'UNKNOWN'
      end
    end

    def count
      @responses.empty? ? 'Responses: UNKNOWN (no readable per-response records)' : "#{@responses.size} responses"
    end

    def versions
      @source.versions.empty? ? 'UNKNOWN' : @source.versions.uniq.map { |version| safe(version) }.join(', ')
    end

    def interval
      timestamps = @responses.filter_map do |record|
        stamp = record['timestamp']
        stamp if stamp.is_a?(String) && stamp.match?(/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?Z\z/)
      end
      timestamps.empty? ? 'UNKNOWN' : timestamps.minmax.join(' through ')
    end

    def safe(value)
      value.is_a?(String) && value.match?(/\A[a-zA-Z0-9][a-zA-Z0-9._:-]{0,79}\z/) ? value : 'UNKNOWN'
    end
  end
end
