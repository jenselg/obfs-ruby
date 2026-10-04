module OBFS
  module StringSimilarity
    extend self

    # Dice overlap of character-bigram multisets. Repeated pairs count separately.
    # Case, path separators and whitespace are normalized before comparison.
    # Empty text has no evidence of similarity; equal nonempty text scores 1.0.
    def similarity(str1, str2)
      left = normalize(str1)
      right = normalize(str2)
      return 0.0 if left.empty? || right.empty?
      return 1.0 if left == right

      left_pairs = bigrams(left)
      right_pairs = bigrams(right)
      total = left_pairs.values.inject(0, :+) + right_pairs.values.inject(0, :+)
      return 0.0 if total == 0

      overlap = left_pairs.inject(0) do |sum, entry|
        pair, count = entry
        sum + [count, right_pairs[pair]].min
      end
      2.0 * overlap / total
    end

    private

    def normalize(value)
      value.to_s.encode('UTF-8').downcase
        .gsub(/[\\\/:_\-]+/, ' ')
        .gsub(/\s+/, ' ').strip
    end

    def bigrams(value)
      counts = Hash.new(0)
      characters = value.each_codepoint.to_a
      characters.each_cons(2) { |pair| counts[pair] += 1 }
      counts
    end
  end
end
