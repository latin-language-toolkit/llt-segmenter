require 'spec_helper'

describe LLT::Segmenter do
  let(:segmenter) { LLT::Segmenter.new }
  describe "#segment" do
    it "returns an array of LLT::Sentence elements" do
      sentences = segmenter.segment("est.")
      sentences.should have(1).item
      sentences.first.should be_a LLT::Sentence
    end

    it "segments a paragraph of into sentences - easy" do
      txt = "Cicero est. Caesar est."
      sentences = segmenter.segment(txt)
      sentences.should have(2).items
      sentences[0].to_s.should == "Cicero est."
      sentences[1].to_s.should == "Caesar est."
    end

    it "segments a paragraph of into sentences - complex" do
      txt = "Cicero est; quis Caesar est? Marcus Antonius!"
      sentences = segmenter.segment(txt)
      sentences.should have(3).items
      sentences[0].to_s.should == "Cicero est;"
      sentences[1].to_s.should == "quis Caesar est?"
      sentences[2].to_s.should == "Marcus Antonius!"
    end

    it "handles abbreviated names" do
      txt = "C. Caesar est. M. Tullius Cicero est."
      sentences = segmenter.segment(txt)
      sentences.should have(2).items
      sentences[0].to_s.should == "C. Caesar est."
      sentences[1].to_s.should == "M. Tullius Cicero est."
    end

    it "handles abbreviated dates" do
      txt = "Is dies erat a. d. V Kal. Apr. L. Pisone, A. Gabinio consulibus."
      sentences = segmenter.segment(txt)
      sentences.should have(1).item
    end

    it "handles more dates" do
      txt = "Is dies erat a. d. V Ian. Non. Feb. L. App. Pisone ."
      sentences = segmenter.segment(txt)
      puts sentences
      sentences.should have(1).item
    end

    it "are only triggered when they have a leading word boundary" do
      # spec might seem strange, but this didn't work from the start on
      txt = "erat nauta. est."
      sentences = segmenter.segment(txt)
      sentences.should have(2).items
    end

    it "handles dates even with numbers that have an abbr dot" do
      pending('Not solved yet. Think of M.') do
        txt = "Is dies erat a. d. V. Kal. Apr. L. Pisone, A. Gabinio consulibus."
        sentences = segmenter.segment(txt)
        sentences.should have(1).item
      end
    end

    it "splits at :" do
      txt = 'iubent: fugere manus.'
      sentences = segmenter.segment(txt)
      sentences.should have(2).items
    end

    context "with embedded xml" do
      it "doesn't break up before xml closing tags" do
        txt = '<grc> text.</grc>'
        sentences = segmenter.segment(txt)
        sentences.should have(1).item
      end
    end

    context "new line (\\n) handling" do
      it "works when in between" do
        txt = "Filia est.\nFilius est."
        sentences = segmenter.segment(txt)
        sentences.should have(2).items
        sentences[0].to_s.should == "Filia est."
        sentences[1].to_s.should == "Filius est."
      end

      it "works when at the end of a text" do
        sentences = segmenter.segment("Marcus est.\n")
        sentences.should have(1).item
        sentences.first.to_s.should == 'Marcus est.'
      end

      it "works with newline and space in between and no new line at the end" do
        txt = "Fīlius rēgīnae erat.\n Rēgīnam aurō dōnābunt."
        sentences = segmenter.segment(txt)
        sentences.should have(2).items
        sentences[0].to_s.should == "Fīlius rēgīnae erat."
        sentences[1].to_s.should == "Rēgīnam aurō dōnābunt."
      end

      it "works with newline and space in between and new line at the end" do
        txt = "Fīlius rēgīnae erat nauta.\n Rēgīnam aurō dōnābunt.\n"
        sentences = segmenter.segment(txt)
        sentences.should have(2).items
        sentences[0].to_s.should == "Fīlius rēgīnae erat nauta."
        sentences[1].to_s.should == "Rēgīnam aurō dōnābunt."
      end
    end

    it "handles quantified texts" do
      txt = "Fēmina puellae pecūniam dabat.\n Fīlia poētae in viīs errābat.\n"
      sentences = segmenter.segment(txt)
      sentences.should have(2).item
    end

    it "is not disturbed by leading or trailing whitespace" do
      txt = '   Marcus est. Marcus est.   '
      sentences = segmenter.segment(txt)
      sentences.should have(2).item
    end

    context "with ellipsis punctuation" do
      it "handles them at the end of a sentence" do
        txt = 'Marcus ...'
        sentences = segmenter.segment(txt)
        sentences.should have(1).item
      end

      it "handles them in the midst of a sentence" do
        pending 'Tough to do'
      end
    end

    context "direct speech delimiter" do
      context "with '" do
        it "handles basic cases when on the outside of the punctuation" do
          txt = "'Marcus est.'"
          sentences = segmenter.segment(txt)
          sentences.should have(1).item
        end

        it "handles basic cases when on the inside of the punctuation" do
          txt = "'Marcus est'?"
          sentences = segmenter.segment(txt)
          sentences.should have(1).item
        end
      end

      context 'with "' do
        it "handles basic cases when on the outside of the punctuation" do
          txt = '"Marcus est."'
          sentences = segmenter.segment(txt)
          sentences.should have(1).item
        end

        it "handles basic cases when on the inside of the punctuation" do
          txt = '"Marcus est"?'
          sentences = segmenter.segment(txt)
          sentences.should have(1).item
        end
      end

      context 'with ” (attention: this is NOT the same as "' do
        it "handles basic cases when on the outside of the punctuation" do
          txt = '”Marcus est.”'
          sentences = segmenter.segment(txt)
          sentences.should have(1).item
        end

        it "handles basic cases when on the inside of the punctuation" do
          txt = '”Marcus est”?'
          sentences = segmenter.segment(txt)
          sentences.should have(1).item
        end
      end
    end

    it "catches trailing parenthesis" do
      txt = "Marcus est. (Marcus est.) Marcus est."
      sentences = segmenter.segment(txt)
      sentences.should have(3).items
      sentences[0].to_s.should == 'Marcus est.'
      sentences[1].to_s.should == '(Marcus est.)'
      sentences[2].to_s.should == 'Marcus est.'
    end

    it "treats an empty line as delimiter - might e.g. appear in book titles" do
      txt = "Marcus est\n\nMarcus est."
      sentences = segmenter.segment(txt)
      sentences.should have(2).item
    end

    it "handles broken off texts - the rest is an own sentence" do
      txt = "Marcus est. Marcus est"
      sentences = segmenter.segment(txt)
      sentences.should have(2).item
    end

    it "raises an argument error when there is no delimiter whatsoever" do
      txt = "Marcus est\nMarcus est"
      expect { segmenter.segment(txt) }.to raise_error ArgumentError
    end

    describe "takes an optional keyword argument add_to" do
      class ParagraphDummy
        attr_reader :sentences
        def initialize; @sentences = []; end
        def <<(sentences); @sentences += sentences; end
      end

      it "adds the result to the given object if #<< is implemented" do
        paragraph = ParagraphDummy.new
        s = segmenter.segment("", add_to: paragraph)
        paragraph.sentences.should == s
      end

      it "does nothing to the given object when #<< it does not respond to" do
        object = double(respond_to?: false)
        object.should_not receive(:<<)
        segmenter.segment("", add_to: object)
      end
    end
  end
end
