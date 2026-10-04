module OBFS
  module Levenshtein
    extend self

    # Unit-cost edit distance over Unicode codepoints, without normalization.
    # With a maximum, return the exact distance capped at that maximum.
    def distance(str1, str2, max_distance = nil)
      unless max_distance.nil? ||
             (max_distance.is_a?(Integer) && max_distance >= 0)
        raise ArgumentError, 'max_distance must be a nonnegative Integer or nil'
      end
      return 0 if max_distance == 0

      left = str1.encode('UTF-8').each_codepoint.to_a
      right = str2.encode('UTF-8').each_codepoint.to_a
      return 0 if left == right

      # The shorter input determines the width of the two working rows.
      left, right = right, left if left.length < right.length
      if max_distance && left.length - right.length >= max_distance
        return max_distance
      end
      return left.length if right.empty?

      previous = (0..right.length).to_a
      left.each_with_index do |character, row|
        current = [row + 1]
        right.each_with_index do |other, column|
          current << [current[column] + 1,
                      previous[column + 1] + 1,
                      previous[column] + (character == other ? 0 : 1)].min
        end
        # Every path to the final cell crosses this row; costs cannot decrease.
        return max_distance if max_distance && current.min >= max_distance
        previous = current
      end

      max_distance ? [previous.last, max_distance].min : previous.last
    end
  end
end
