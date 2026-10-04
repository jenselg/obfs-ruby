require 'json'
require 'fileutils'

module OBFS

  class Store

    def initialize(attributes = {})
      @path = (attributes.keys.include? :path) ? attributes[:path] : File.join(Dir.home, '.obfs')
    end


    # ============================================================
    # REGULAR METHODS
    # ============================================================

    def method_missing(m, *args, &block)

      method_name = m.to_s
      dataA = args[0]
      dataB = args[1]


      # ----------------------------------------------------------
      # setter call
      #
      #   obfs.foo = 'bar'
      #   obfs['foo'] = 'bar'
      # ----------------------------------------------------------

      if method_name.end_with?('=')

        method_name = method_name.gsub('=', '')


        # bracket setter
        if method_name == "[]"

          method_name = validate_child_name!(dataA)
          data = dataB


        # dot setter
        else

          method_name = validate_child_name!(
            m.to_s.gsub('=', '')
          )

          data = args[0]

        end


        # delete
        if data == nil

          FileUtils.rm_rf(
            File.join(
              @path,
              method_name
            )
          )


        # write
        else

          child_path =
            File.join(
              @path,
              method_name
            )


          FileUtils.rm_rf(child_path) if File.exist?(child_path)

          FileUtils.mkpath @path if !File.directory? @path

          write(
            @path,
            method_name,
            data
          )

        end


      # ----------------------------------------------------------
      # bracket getter
      #
      #   obfs['foo']
      # ----------------------------------------------------------

      elsif method_name == "[]"

        method_name =
          dataA
            .to_s
            .gsub(/\["/, '')
            .gsub(/"\]/, '')


        method_name =
          validate_child_name!(
            method_name
          )


        child_path =
          File.join(
            @path,
            method_name
          )


        if !File.directory?(child_path) &&
           File.exist?(child_path)

          read(
            @path,
            method_name
          )

        else

          OBFS::Store.new({
            path: child_path
          })

        end


      # ----------------------------------------------------------
      # dot getter / recursive access
      #
      #   obfs.foo.bar
      # ----------------------------------------------------------

      else

        method_name =
          validate_child_name!(
            method_name
          )


        child_path =
          File.join(
            @path,
            method_name
          )


        if !File.directory?(child_path) &&
           File.exist?(child_path)

          read(
            @path,
            method_name
          )

        else

          OBFS::Store.new({
            path: child_path
          })

        end

      end

    end


    # ============================================================
    # SPECIAL METHODS
    # ============================================================


    # ------------------------------------------------------------
    # current path
    #
    #   obfs._path
    # ------------------------------------------------------------

    def _path
      @path
    end


    # ------------------------------------------------------------
    # directory contents
    #
    # Existing behavior preserved:
    #
    # - excludes "." and ".."
    # - includes dot-prefixed entries
    # - preserves filesystem ordering
    # - returns nil on failure
    #
    #   obfs._index
    #   obfs._keys
    # ------------------------------------------------------------

    def _index

      Dir.entries(@path).reject {
        |k| k == '.' || k == '..'
      } rescue nil

    end

    alias_method :_keys, :_index


    # ------------------------------------------------------------
    # one-level fuzzy search
    #
    # Existing signature and return type preserved:
    #
    #   obfs._find(term, records, tolerance)
    #
    # Returns an Array<String>, but now actually sorted by
    # relevance as originally intended.
    # ------------------------------------------------------------

    def _find(term = '', records = 1000, tolerance = 50)

      term = term.to_s


      search_space =
        Dir.entries(@path).reject {
          |k| k == '.' || k == '..'
        } rescue []


      results = []


      search_space.each do |search_space_term|

        distance =
          OBFS::Levenshtein.distance(
            search_space_term,
            term
          )


        similarity =
          OBFS::StringSimilarity.similarity(
            search_space_term,
            term
          )


        if distance <= tolerance &&
           similarity > 0.0

          results << {
            name: search_space_term,
            score: fuzzy_score(
              term,
              search_space_term
            )
          }

        end

      end


      results
        .sort_by {
          |result|

          [
            -result[:score],
            result[:name].downcase
          ]
        }
        .first(records)
        .map {
          |result|

          result[:name]
        }

    end


    # ------------------------------------------------------------
    # existing direct-child existence check
    #
    # Existing behavior preserved.
    #
    #   obfs._exist('foo')
    # ------------------------------------------------------------

    def _exist(term = '')

      exist_space =
        Dir.entries(@path).reject {
          |k|

          k != term.to_s ||
            k == '.' ||
            k == '..'
        } rescue nil


      if !exist_space.nil?

        if exist_space.length > 0
          true
        else
          false
        end

      else

        false

      end

    end


    # ------------------------------------------------------------
    # current node existence
    #
    #   obfs.foo.bar._exists
    #   obfs.foo.bar._exists?
    # ------------------------------------------------------------

    def _exists
      File.exist?(@path)
    end

    def _exists?
      _exists
    end


    # ------------------------------------------------------------
    # direct-child existence
    #
    #   obfs.foo._has('bar')
    #   obfs.foo._has?('bar')
    #
    # Unlike _exist, this uses File.exist? directly instead
    # of enumerating the current directory.
    # ------------------------------------------------------------

    def _has(term = '')

      child_name =
        validate_child_name!(
          term
        )


      File.exist?(
        File.join(
          @path,
          child_name
        )
      )


    rescue

      false

    end


    def _has?(term = '')
      _has(term)
    end


    # ------------------------------------------------------------
    # current node timestamp
    #
    #   obfs.foo._timestamp
    #
    # Returns nil when the node does not exist or cannot be read.
    # ------------------------------------------------------------

    def _timestamp

      File.mtime(@path)


    rescue

      nil

    end


    # ------------------------------------------------------------
    # recursive fuzzy directory search
    #
    #   obfs._search('nginx')
    #
    #   obfs.systems._search(
    #     'nginx certificate',
    #     {
    #       recursive: true,
    #       min_score: 0.6,
    #       limit: 10
    #     }
    #   )
    #
    # camelCase minScore is also accepted:
    #
    #   {
    #     minScore: 0.6
    #   }
    #
    # Defaults:
    #
    #   recursive: true
    #   min_score: 0.5
    #   limit:      unlimited
    #
    # Returns:
    #
    #   [
    #     {
    #       path: "services/nginx",
    #       score: 1.0
    #     },
    #     {
    #       path: "services/nginx/certificates",
    #       score: 0.9
    #     }
    #   ]
    #
    # Search:
    #
    # - is scoped to the current Store node
    # - searches directories only
    # - searches directory names and relative paths
    # - does not read file contents
    # - does not follow symbolic links
    # - ignores dot-prefixed entries
    # - returns relevance-sorted results
    # ------------------------------------------------------------

    def _search(term = '', options = {})

      return [] unless File.directory?(@path)


      term =
        term
          .to_s
          .strip


      return [] if term.empty?


      options = {} unless options.is_a?(Hash)


      recursive =
        search_option(
          options,
          [
            :recursive,
            'recursive'
          ],
          true
        )


      min_score =
        search_option(
          options,
          [
            :min_score,
            :minScore,
            'min_score',
            'minScore'
          ],
          0.5
        ).to_f


      limit =
        search_option(
          options,
          [
            :limit,
            'limit'
          ],
          nil
        )


      # clamp score to 0.0 - 1.0

      min_score = 0.0 if min_score < 0.0
      min_score = 1.0 if min_score > 1.0


      results = []


      search_directories(
        @path,
        '',
        term,
        recursive,
        min_score,
        results
      )


      results.sort_by! do |result|

        [
          -result[:score],
          result[:path].downcase
        ]

      end


        unless limit.nil? || (limit.respond_to?(:infinite?) && limit.infinite?)

            begin

                limit =
                Integer(limit)

            rescue

                return []

            end

            return [] if limit <= 0

            results = results.first(limit)

        end


      results

    end


    private


    # ============================================================
    # FILESYSTEM R/W
    # ============================================================


    # ------------------------------------------------------------
    # write
    #
    # Original behavior intentionally preserved.
    #
    # Hashes, Arrays, Strings, Numbers, Booleans, etc. continue
    # to be JSON serialized into a single file.
    # ------------------------------------------------------------

    def write(path, filename, data)

      curr_path =
        File.join(
          path,
          filename
        )


      File.write(
        curr_path,
        JSON.dump(data)
      )

    end


    # ------------------------------------------------------------
    # read
    #
    # Original behavior intentionally preserved.
    #
    # JSON is parsed when possible.
    # Otherwise raw file contents are returned.
    # ------------------------------------------------------------

    def read(path, filename)

      curr_path =
        File.join(
          path,
          filename
        )


      content =
        File.open(
          curr_path
        ).read


      begin

        JSON.parse(content)

      rescue

        content

      end

    end


    # ============================================================
    # SEARCH
    # ============================================================


    # ------------------------------------------------------------
    # recursively search directory structure
    # ------------------------------------------------------------

    def search_directories(
      path,
      relative_path,
      term,
      recursive,
      min_score,
      results
    )

      entries =
        Dir.entries(path).reject do |entry|

          entry == '.' ||
            entry == '..' ||
            entry.start_with?('.')

        end rescue []


      entries.each do |entry|

        full_path =
          File.join(
            path,
            entry
          )


        # do not follow symbolic links

        next if File.symlink?(full_path)


        # search directory structure only

        next unless File.directory?(full_path)


        child_relative_path =

          if relative_path.empty?

            entry

          else

            File.join(
              relative_path,
              entry
            )

          end


        name_score =
          fuzzy_score(
            term,
            entry
          )


        path_score =
          fuzzy_score(
            term,
            child_relative_path
          )


        score =
          [
            name_score,
            path_score
          ].max


        if score >= min_score

          results << {
            path: child_relative_path,
            score: score.round(6)
          }

        end


        if recursive

          search_directories(
            full_path,
            child_relative_path,
            term,
            recursive,
            min_score,
            results
          )

        end

      end

    end


    # ------------------------------------------------------------
    # calculate fuzzy relevance score
    #
    # Score range:
    #
    #   0.0 - 1.0
    #
    # Uses:
    #
    # - exact matches
    # - prefix matches
    # - substring matches
    # - token coverage
    # - OBFS Levenshtein distance
    # - normalized bigram/Dice similarity
    #
    # No additional dependencies required.
    # ------------------------------------------------------------

    def fuzzy_score(term, candidate)

      query =
        normalize_search_term(term)


      value =
        normalize_search_term(candidate)


      return 0.0 if query.empty? || value.empty?

      return 1.0 if query == value


      scores = []


      # ----------------------------------------------------------
      # prefix match
      # ----------------------------------------------------------

      scores << 0.95 if value.start_with?(query)


      # ----------------------------------------------------------
      # substring match
      # ----------------------------------------------------------

      scores << 0.90 if value.include?(query)


      # ----------------------------------------------------------
      # token coverage
      # ----------------------------------------------------------

      query_tokens =
        query.split(/\s+/)


      unless query_tokens.empty?

        matched_tokens =
          query_tokens.count do |token|

            value.include?(token)

          end


        coverage =
          matched_tokens.to_f /
          query_tokens.length.to_f


        scores << (
          coverage * 0.85
        )

      end


      # ----------------------------------------------------------
      # normalized Levenshtein similarity
      # ----------------------------------------------------------

      max_length =
        [
          query.length,
          value.length
        ].max


      if max_length > 0

        distance =
          OBFS::Levenshtein.distance(
            query,
            value
          ).to_f


        levenshtein_score =
          1.0 -
          (
            distance /
            max_length.to_f
          )


        levenshtein_score = 0.0 if levenshtein_score < 0.0
        levenshtein_score = 1.0 if levenshtein_score > 1.0


        scores << levenshtein_score

      end


      # ----------------------------------------------------------
      # normalized bigram/Dice similarity
      # ----------------------------------------------------------

      scores << OBFS::StringSimilarity.similarity(query, value)


      scores.empty? ? 0.0 : scores.max

    end


    # ------------------------------------------------------------
    # normalize text for fuzzy matching
    #
    # Examples:
    #
    #   "import-scenarios"
    #       =>
    #   "import scenarios"
    #
    #   "systems/nginx_errors"
    #       =>
    #   "systems nginx errors"
    # ------------------------------------------------------------

    def normalize_search_term(value)

      value
        .to_s
        .downcase
        .gsub(/[\\\/:_\-]+/, ' ')
        .gsub(/[^a-z0-9\s]/, '')
        .gsub(/\s+/, ' ')
        .strip

    end


    # ------------------------------------------------------------
    # retrieve option using symbol/string equivalents
    #
    # Presence testing is used rather than || so:
    #
    #   recursive: false
    #
    # works correctly.
    # ------------------------------------------------------------

    def search_option(
      options,
      keys,
      default_value
    )

      keys.each do |key|

        return options[key] if options.key?(key)

      end


      default_value

    end


    # ============================================================
    # PATH SAFETY
    # ============================================================


    # ------------------------------------------------------------
    # validates one OBFS object key
    #
    # An individual key represents exactly one filesystem node.
    #
    # Therefore:
    #
    #   obfs['foo']['bar']
    #
    # is valid, while:
    #
    #   obfs['foo/bar']
    #   obfs['../foo']
    #   obfs['foo/../../etc']
    #   obfs['..\\foo']
    #
    # are rejected.
    #
    # This prevents escaping the current OBFS hierarchy through
    # bracket notation or dynamically generated keys.
    # ------------------------------------------------------------

    def validate_child_name!(name)

      name =
        name.to_s


      if name.empty?

        raise "OBFS key cannot be empty"

      end


      if name == '.' ||
         name == '..' ||
         name.include?('/') ||
         name.include?('\\') ||
         name.include?("\0")

        raise "filesystem traversal is not allowed"

      end


      name

    end

  end

end