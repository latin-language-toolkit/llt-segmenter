require "llt/constants"
require "llt/core"
require "llt/logger"
require "llt/sentence"

module LLT
  class Segmenter
    include Constants::Abbreviations
    include Core::Serviceable

    uses_logger { Logger.new('Segmenter', default: :debug) }

    # Abbreviations with boundary
    AWB = ALL_ABBRS_PIPED.split('|').map { |abbr| "\\b#{abbr}" }.join('|')
    SENTENCE_CLOSER = /(?<!#{AWB})\.(?!\.)|[;\?!:]|\n{2}/
    DIRECT_SPEECH_DELIMITER = /['"”]/
    TRAILERS = /\)/

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
        sentences << Sentence.new(sentence)
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
