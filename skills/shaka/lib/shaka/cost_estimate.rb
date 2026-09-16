# frozen_string_literal: true

module Shaka
  # Prices configured-model scenarios from disjoint per-response token categories.
  class CostEstimate
    VERIFIED = '2026-09-15'
    THRESHOLD = 272_000
    RATES = {
      'gpt-5.6-terra' => { credits: %w[50 5 300], api: %w[2 0.2 12] },
      'gpt-5.6-sol' => { credits: %w[100 10 500], api: %w[4 0.4 20] },
      'gpt-6-astra' => { credits: %w[250 25 1250], api: %w[10 1 50] }
    }.freeze

    def initialize(responses)
      @responses = responses
    end

    def report
      reasons = []
      rows = @responses.group_by { |record| record['configuration'] }.map do |configuration, group|
        row(configuration, group, reasons)
      end.join("\n")
      rows = '| UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |' if rows.empty?
      markdown(rows, reasons)
    end

    private

    def row(configuration, group, reasons)
      credits, credit_reason = total(group, :credits)
      api, api_reason = total(group, :api)
      reasons.concat([credit_reason, api_reason].compact)
      provider, model, _, effort = configuration
      "| #{[safe(provider), safe(model), safe(effort), show(credits, 'credits'), show(api, '$')].join(' | ')} |"
    end

    def markdown(rows, reasons)
      <<~MARKDOWN

        Cost estimates are PARTIAL configured-model scenarios for the selected native responses.
        Actual charge: UNKNOWN (routed model, billing mode, service tier, account terms, and external work unavailable).

        <details>
        <summary>Cost scenarios</summary>

        Standard Codex credit and Standard OpenAI API-equivalent rates verified #{VERIFIED};
        historical rates and account-specific terms may differ. Effort has no price multiplier.
        Cached input and reasoning output are subsets, not extra charges. API cache writes
        are included in input; Codex credit cache-write pricing is unavailable.
        The API scenario applies each request's 272K context threshold before summing.

        | Provider | Configured model | Effort | Codex credits estimate | API-equivalent USD estimate |
        | --- | --- | --- | ---: | ---: |
        #{rows}

        #{reasons.uniq.join('; ')}
        Sources: [Codex credit rates](https://learn.chatgpt.com/docs/pricing#token-rates),
        API prices for [Terra](https://developers.openai.com/api/docs/models/gpt-5.6-terra),
        [Sol](https://developers.openai.com/api/docs/models/gpt-5.6-sol), and
        [Astra](https://developers.openai.com/api/docs/models/gpt-6-astra),
        [prompt-cache accounting](https://developers.openai.com/api/docs/guides/prompt-caching).

        </details>
      MARKDOWN
    end

    def total(group, mode)
      amounts = group.map { |record| price(record, mode) }
      reason = amounts.map(&:last).compact.first
      [reason ? nil : amounts.sum { |amount, _| amount }, reason]
    end

    def price(record, mode)
      provider, model = record['configuration']
      rate = RATES.dig(model, mode) if provider == 'openai'
      return [nil, 'Unsupported provider or configured model'] unless rate

      tokens, reason = categories(record['usage'])
      return [nil, reason] if reason
      return [nil, 'Credit cache-write rate UNKNOWN'] if mode == :credits && tokens[2].positive?

      [bill(tokens, rate, mode) / 1_000_000, nil]
    end

    def categories(usage)
      return [nil, 'Incomplete billable token categories'] unless usage.is_a?(Hash)

      tokens = %w[input_tokens cached_input_tokens cache_write_input_tokens output_tokens].map { |field| usage[field] }
      return [nil, 'Incomplete billable token categories'] unless valid_counters?(tokens)

      input, cached, writes, output = tokens
      reasoning = usage['reasoning_output_tokens']
      return [nil, 'Inconsistent token subsets'] if cached + writes > input || invalid_reasoning?(reasoning, output)

      [tokens, nil]
    end

    def bill(tokens, rate, mode)
      large = mode == :api && tokens[0] > THRESHOLD
      (input_bill(tokens, rate, mode) * (large ? 2 : 1)) +
        (tokens[3] * Rational(rate[2]) * (large ? Rational(3, 2) : 1))
    end

    def input_bill(tokens, rate, mode)
      input, cached, writes = tokens
      input_rate, cached_rate = rate.first(2).map { |value| Rational(value) }
      amount = ((input - cached - writes) * input_rate) + (cached * cached_rate)
      mode == :api ? amount + (writes * input_rate * Rational(5, 4)) : amount
    end

    def valid_counters?(tokens)
      tokens.all? { |value| value.is_a?(Integer) && value >= 0 }
    end

    def invalid_reasoning?(reasoning, output)
      reasoning.is_a?(Integer) && (reasoning.negative? || reasoning > output)
    end

    def show(amount, unit)
      return 'UNKNOWN' unless amount

      formatted = format('%.6f', amount)
      unit == '$' ? "#{unit}#{formatted}" : "#{formatted} #{unit}"
    end

    def safe(value)
      value.is_a?(String) && value.match?(/\A[a-zA-Z0-9][a-zA-Z0-9._:-]{0,79}\z/) ? value : 'UNKNOWN'
    end
  end
end
