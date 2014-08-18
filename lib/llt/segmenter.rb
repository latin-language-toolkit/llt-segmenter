require "llt/constants"
require "llt/core"
require "llt/logger"
require "llt/sentence"
require "llt/segmenter/version"
require "llt/segmenter/version_info"

module LLT
  class Segmenter
    include Constants::Abbreviations
    include Core::Serviceable

    uses_logger { Logger.new('Segmenter', default: :debug) }

    def self.default_options
      {
        indexing: true,
        newline_boundary: 2,
        xml: false
      }
    end

    # Abbreviations with boundary e.g. \bA
    #
    # This doesn't work in jruby (opened an issue at jruby/jruby#1269 ),
    # so we have to change things as long as this is not fixed.
    #
    # (?<=\s|^) can be just \b in MRI 2.0 and upwards
    #
    # Added > to the regex on Feb 11 2014 to treat a closing chevron as a kind
    # of word boundary.
    AWB = ALL_ABBRS_PIPED.split('|').map { |abbr| "(?<=\\s|^|>)#{abbr}" }.join('|')
    # the xml escaped characters cannot be refactored to something along
    # &(?:amp|quot); - it's an invalid pattern in the look-behind
    SENTENCE_CLOSER = /(?<!#{AWB})\.(?!\.)|[\?!:·]|((?<!&amp|&quot|&apos|&lt|&gt);)/
    DIRECT_SPEECH_DELIMITER = /['"”]|&(?:apos|quot);/
    TRAILERS = /\)|\s*<\/.*?>/

    def segment(string, add_to: nil, **options)
      setup(options)
      # dump whitespace at the beginning and end!
      string.strip!
      string = normalize_whitespace(string)
      sentences = scan_through_string(StringScanner.new(string))
      add_to << sentences if add_to.respond_to?(:<<)
      sentences
    end

    private

    def setup(options)
      @xml = parse_option(:xml, options)
      @indexing = parse_option(:indexing, options)
      @id = 0 if @indexing

      # newline_boundary is only active when we aren't working with xml!
      nl_boundary  = parse_option(:newline_boundary, options)

      @sentence_closer = build_sentence_closer_regexp(nl_boundary)
    end

    def build_sentence_closer_regexp(nl_boundary)
      @xml ? SENTENCE_CLOSER : Regexp.union(SENTENCE_CLOSER, /\n{#{nl_boundary}}/)
    end

    # Used to normalized wonky whitespace in front of or behind direct speech
    # delimiters like " (currently the only one supported).
    def normalize_whitespace(string)
      # in most cases there is nothing to do, then leave immediately
      return string unless string.match(/\s"\s/)

      scanner = StringScanner.new(string)
      reset_direct_speech_status
      string_with_normalized_whitespace(scanner)
    end

    def string_with_normalized_whitespace(scanner)
      new_string = ''
      until scanner.eos?
        if match = scanner.scan_until(/"/)
          new_string << normalized_match(scanner, match)
          toggle_direct_speech_status
        else
          new_string << scanner.rest
          break
        end
      end
      new_string
    end

    def surrounded_by_whitespace?(scanner)
      pos_before = scanner.pre_match[-1]
      pos_behind = scanner.post_match[0]
      pos_before == ' ' && (pos_behind == ' ' || pos_behind == nil) # end of string
    end

    def normalized_match(scanner, match)
      if surrounded_by_whitespace?(scanner)
        if direct_speech_open?
          # eliminate the whitespace in front of "
          match[0..-3] << '"'
        else
          # hop over the whitespace behind "
          scanner.pos = scanner.pos + 1
          match
        end
      else
        match
      end
    end

    def direct_speech_open?
      @direct_speech
    end

    def reset_direct_speech_status
      @direct_speech = false
    end

    def toggle_direct_speech_status
      @direct_speech = (@direct_speech ? false : true)
    end

    def scan_through_string(scanner, sentences = [])
      while scanner.rest?
        loop_guard = scanner.pos

        sentence = scan_until_next_sentence(scanner, sentences)


        raise if scanner.pos == loop_guard

        if @xml
          rebuild_xml_tags(scanner, sentence, sentences)
          take_all_closing_tags(scanner, sentence)
        end
        sentence << trailing_delimiters(scanner)

        sentence.strip!
        unless sentence.empty?
          curr_id = id
          @logger.log("Segmented #{curr_id} #{sentence}")
          sentences << Sentence.new(sentence, curr_id)
        end
      end
      sentences
    end

    def scan_to_first_real_text(scanner)
      scanner.scan_until(/<.*?>\s*(?=\w)/)
    end

    def scan_until_next_sentence(scanner, sentences)
      scanner.scan_until(@sentence_closer) ||
        rescue_no_delimiters(sentences, scanner)
    end

    def id
      if @indexing
        @id += 1
      end
    end

    # this is only needed when there is punctuation inside of xml tags
    def rebuild_xml_tags(scanner, sentence, sentences)
      if has_open_chevron?(sentence)
        sentence << scanner.scan_until(/>/)
        if inside_a_running_sentence?(sentence)
          sentence << scan_until_next_sentence(scanner, sentences)
        end
        rebuild_xml_tags(scanner, sentence, sentences)
      end
    end

    def has_open_chevron?(sentence)
      sentence.count('<') > sentence.count('>')
    end

    def inside_a_running_sentence?(sentence)
      ! sentence.match(/#{@sentence_closer}\s*<.*?>$/)
    end

    def take_all_closing_tags(scanner, sentence)
      if closing_tags_only?(scanner.rest)
        sentence << scanner.rest
        scanner.terminate
      end
    end

    def closing_tags_only?(str)
      str.match(/\A(\s*<\/.*?>\s*|\s*<.*?\/>\s*)+\z/)
    end


    def rescue_no_delimiters(sentences, scanner)
      if sentences.any?
        # broken off texts
        scanner.scan_until(/\Z/)
      else
        if scanner.eos? && @xml
          return ''
        end
        # try a simple newline as delimiter, if there was no delimiter
        scanner.reset
        @sentence_closer = /\n/
        if sent = scanner.scan_until(@sentence_closer)
          sent
        else
          # when there is not even a new line, return all input
          scanner.terminate
          scanner.string
        end
      end
    end

    def trailing_delimiters(scanner)
      trailers = [DIRECT_SPEECH_DELIMITER, TRAILERS]
      trailers.each_with_object('') do |trailer, str|
        str << scanner.scan(trailer).to_s # catches nil
      end
    end
  end
end
