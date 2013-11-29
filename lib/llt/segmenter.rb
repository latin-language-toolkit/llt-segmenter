require "llt/constants"
require "llt/core"
require "llt/logger"
require "llt/sentence"

module LLT
  class Segmenter
    include Constants::Abbreviations
    include Core::Serviceable

    uses_logger { Logger.new('Segmenter', default: :debug) }

    # Abbreviations with boundary e.g. \bA
    #
    # This doesn't work in jruby (opened an issue at jruby/jruby#1269 ),
    # so we have to change things as long as this is not fixed.
    #
    # (?<=\s|^) can be just \b in MRI 2.0 and upwards
    AWB = ALL_ABBRS_PIPED.split('|').map { |abbr| "(?<=\\s|^)#{abbr}" }.join('|')
    SENTENCE_CLOSER = /(?<!#{AWB})\.(?!\.)|[;\?!:]|\n{2}/
    DIRECT_SPEECH_DELIMITER = /['"”]/
    TRAILERS = /\)|<\/.*?>/

    def segment(string, add_to: nil)
      # dump whitespace at the beginning and end!
      string.strip!
      sentences = scan_through_string(StringScanner.new(string))
      add_to << sentences if add_to.respond_to?(:<<)
      sentences
    end

    private

    def scan_through_string(scanner, sentences = [])
      while scanner.rest?
        sentence = scanner.scan_until(SENTENCE_CLOSER) ||
          handle_broken_off_texts_or_raise(sentences, scanner)
        sentence << trailing_delimiters(scanner)

        sentence.strip!
        @logger.log("#{'Segmented '.green} #{sentences.size.to_s.cyan} #{sentence}")
        sentences << Sentence.new(sentence) unless sentence.empty?
      end
      sentences
    end

    def handle_broken_off_texts_or_raise(sentences, scanner)
      if sentences.any?
        # broken off texts
        scanner.scan_until(/$/)
      else
        raise ArgumentError.new('No delimiters present!')
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
