require 'spec_helper'

describe LLT::Segmenter do
  def load_fixture(filename)
    File.read(File.expand_path("../../../fixtures/#{filename}", __FILE__))
  end

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

    it "creates indices by default" do
      txt = "Cicero est; quis Caesar est? Marcus Antonius!"
      sentences = segmenter.segment(txt)
      sentences.map(&:id).should == [1, 2, 3]
    end

    it "indices can be turned off" do
      txt = "Cicero est; quis Caesar est? Marcus Antonius!"
      sentences = segmenter.segment(txt, indexing: false)
      sentences.map(&:id).should == [nil, nil, nil]
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

    it "doesn't create empty sentences" do
      txt = "text.\n\n\ntext."
      sentences = segmenter.segment(txt)
      sentences.should have(2).items
    end

    context "with embedded xml" do
      it "doesn't break up before xml closing tags" do
        txt = '<grc> text.</grc>'
        sentences = segmenter.segment(txt, xml: true)
        sentences.should have(1).item
      end

      it "doesn't break with punctuation in element names I" do
        txt = '<grc.test>text.</grc.test>'
        sentences = segmenter.segment(txt, xml: true)
        sentences.should have(1).item
      end

      it "doesn't break with punctuation in element names II" do
        txt = '<grc.test>text.</grc.test> text 2.'
        sentences = segmenter.segment(txt, xml: true)
        sentences.should have(2).items
        sentences[0].to_s.should == '<grc.test>text.</grc.test>'
        sentences[1].to_s.should == 'text 2.'
      end

      it "doesn't break with punctuation in element names III" do
        txt = '<grc.test>text</grc.test> resumed. text 2.'
        sentences = segmenter.segment(txt, xml: true)
        sentences.should have(2).items
        sentences[0].to_s.should == '<grc.test>text</grc.test> resumed.'
        sentences[1].to_s.should == 'text 2.'
      end

      it "doesn't break with attribute values containing punctuation" do
        txt = '<grc no="1.1"> text.</grc> text 2.'
        sentences = segmenter.segment(txt, xml: true)
        sentences.should have(2).items
        sentences[1].to_s.should == 'text 2.'
      end

      it "doesn't break when a random newline leads the last tag" do
        txt = "<grc> text.\n</grc>"
        sentences = segmenter.segment(txt, xml: true)
        sentences.should have(1).item
      end

      it "handles abbreviation of Marcus (M.) at the beginning of a new paragraph" do
        txt = "<p>qui facere poterat.</p>\n<p>\n<milestone/>\nM. Cicero inter Catilinas detestatur!"
        sentences = segmenter.segment(txt, xml: true)
        sentences.should have(2).items
      end

      it "treats an xml tag like a word boundary" do
        # M. would not be recognized as abbreviation otherwise
        txt = "<p>M. Cicero est.</p>"
        sentences = segmenter.segment(txt, xml: true)
        sentences.should have(1).item
      end

      it "doesn't fall with multiple closing tags at the end" do
        txt = '<div type="div1" xml:id="c097"> <l>Numen inest vati, vatum mens consona caelo est, </l> <l n="100">Nec certus scit fallere Apollo. </l>  </div>'
        sentences = segmenter.segment(txt, xml: true)
        puts sentences
        sentences.should have(1).item
      end

      it "doesn't fall with empty tags" do
        txt = '<div type="div1" xml:id="c097"> <l>Numen inest vati, vatum mens consona caelo est, </l> <l n="100">Nec certus scit fallere Apollo. </l> <milestone unit="page" n="210"/> </div>'
        sentences = segmenter.segment(txt, xml: true)
        sentences.should have(1).item
      end

      it "doesn't fall for complex documents" do
        txt = <<-EOF
          <tei:TEI xmlns:tei="http://www.tei-c.org/ns/1.0">
            <tei:text xml:lang="grc">
              <tei:body>
               <tei:div type="line">
                  <milestone ed="P" unit="para"/>μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος</tei:div>
            </tei:body>
            </tei:text>
          </tei:TEI>
        EOF
        sentences = segmenter.segment(txt, xml: true)
        sentences.should have(1).item
      end

      it "doesn't fall for complex documents II" do
        txt = <<-EOF
          <tei:TEI xmlns:tei="http://www.tei-c.org/ns/1.0">
            <tei:text xml:lang="grc">
              <tei:body>
               <tei:div type="line">
                  <milestone ed="P" unit="para"/>Arma virum. Test.</tei:div>
            </tei:body>
            </tei:text>
          </tei:TEI>
        EOF
        sentences = segmenter.segment(txt, xml: true)
        sentences.should have(2).item
      end

      it "doesn't fall for complex documents III" do
        txt = <<-EOF
          <tei:TEI xmlns:tei="http://www.tei-c.org/ns/1.0">
            <tei:text xml:lang="grc">
              <tei:body>
               <tei:div type="line">
                  <milestone ed="P" unit="para"/>Arma virum. Test</tei:div>
            </tei:body>
            </tei:text>
          </tei:TEI>
        EOF
        sentences = segmenter.segment(txt, xml: true)
        sentences.should have(2).item
      end

      it "doesn't fall for complex documents IV" do
        txt = <<-EOF
          <TEI xmlns="http://www.tei-c.org/ns/1.0">
            <text xml:lang="grc">
              <body>
                <div1 type="Book" n="1">
                  <l n="1">
                    <milestone ed="P" unit="para"/>
                    μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος
                  </l>
                </div1>
                <div1 type="Book" n="1">
                  <l n="2">οὐλομένην, ἣ μυρίʼ Ἀχαιοῖς ἄλγεʼ ἔθηκε,</l>
                </div1>
                <div1 type="Book" n="1">
                  <l n="3">πολλὰς δʼ ἰφθίμους ψυχὰς Ἄϊδι προΐαψεν</l>
                </div1>
                <div1 type="Book" n="1">
                  <l n="4">ἡρώων, αὐτοὺς δὲ ἑλώρια τεῦχε κύνεσσιν</l>
                </div1>
                <div1 type="Book" n="1">
                  <l n="5">οἰωνοῖσί τε πᾶσι, Διὸς δʼ ἐτελείετο βουλή,</l>
                </div1>
                <div1 type="Book" n="1">
                  <l n="6">ἐξ οὗ δὴ τὰ πρῶτα διαστήτην ἐρίσαντε</l>
                </div1>
                <div1 type="Book" n="1">
                  <l n="7">Ἀτρεΐδης τε ἄναξ ἀνδρῶν καὶ δῖος Ἀχιλλεύς.</l>
                </div1>
                <div1 type="Book" n="1">
                  <l n="8">
                    <milestone ed="P" unit="Para"/>
                    τίς τʼ ἄρ σφωε θεῶν ἔριδι ξυνέηκε μάχεσθαι;
                  </l>
                </div1>
                <div1 type="Book" n="1">
                  <l n="9">Λητοῦς καὶ Διὸς υἱός· ὃ γὰρ βασιλῆϊ χολωθεὶς</l>
                </div1>
                <div1 type="Book" n="1">
                  <l n="10">νοῦσον ἀνὰ στρατὸν ὄρσε κακήν, ὀλέκοντο δὲ λαοί,</l>
                </div1>
              </body>
            </text>
          </TEI>
        EOF
        sentences = segmenter.segment(txt, xml: true)
        sentences.should have(4).item
      end

      it "doesn't fall for complex documents V" do
        txt = <<-EOF
          <TEI xmlns="http://www.tei-c.org/ns/1.0">
            <text xml:lang="grc">
              <body>
                <div1 type="Book" n="1">
                  <l n="1">
                    <milestone ed="P" unit="para"/>
                    μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος
                  </l>
                </div1>
              </body>
            </text>
          </TEI>
        EOF
        sentences = segmenter.segment(txt, xml: true)
        sentences.should have(1).item
      end
    end

    context "with xml escaped characters" do
      it "doesn't split when it shouldn't" do
        txt = '&quot;text&quot; resumed. success.'
        sentences = segmenter.segment(txt)
        sentences.should have(2).item
        sentences[1].to_s.should == 'success.'
      end

      it "acknowledges &quot; as potentially trailing delimiter" do
        txt = '&quot;text.&quot; success.'
        sentences = segmenter.segment(txt)
        sentences.should have(2).item
        sentences[1].to_s.should == 'success.'
      end

      it "acknowledges &apos; as potentially trailing delimiter" do
        txt = '&apos;text.&apos; success.'
        sentences = segmenter.segment(txt)
        sentences.should have(2).item
        sentences[1].to_s.should == 'success.'
      end

      describe "when CGI.unescaping HTML characters" do
        it "acknowledges &apos; as potentially trailing delimiter" do
          txt = '&apos;text.&apos; success.'
          unescaped = CGI.unescapeHTML(txt)
          sentences = segmenter.segment(unescaped)
          sentences.should have(2).item
          sentences[1].to_s.should == 'success.'
        end
      end
    end

    context "newline (\\n) handling" do
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

      it "treats an empty line as delimiter - might e.g. appear in book titles" do
        txt = "Marcus est\n\nMarcus est."
        sentences = segmenter.segment(txt)
        sentences.should have(2).item
      end

      it "number of newlines that count as sentence boundary can be given as option" do
        txt1 = "Marcus est\n\nMarcus est."
        txt2 = "Marcus est\n\n\nMarcus est."
        sentences1 = segmenter.segment(txt1, newline_boundary: 3)
        sentences2 = segmenter.segment(txt2, newline_boundary: 3)
        sentences1.should have(1).item
        sentences2.should have(2).item
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

    it "handles broken off texts - the rest is an own sentence" do
      txt = "Marcus est. Marcus est"
      sentences = segmenter.segment(txt)
      sentences.should have(2).item
    end

    context "with no delimiters present" do
      it "tries to fallback to single newline boundary" do
        txt = "Marcus est\nMarcus est"
        segmenter.segment(txt).should have(2).items
      end

      it "returns the whole input as segment when there are no newlines" do
        txt = "Marcus est"
        segmenter.segment(txt).should have(1).item
      end
    end

    context "with badly whitespaced direct speech delimiters" do
      it "normalizes whitespace and knows to which sentence a \" belongs" do
        txt = '"Marcus est. " Cicero est. " Iulius est. "'
        sentences = segmenter.segment(txt)
        #sentences.should have(3).items
        sentences.map!(&:to_s)
        sentences[0].should == '"Marcus est."'
        sentences[1].should == 'Cicero est.'
        sentences[2].should == '"Iulius est."'
      end
    end

    context "with full TEI files" do
      it "doesn't go into an endless loop when something is wrong" do
        txt = load_fixture('petrov_eleg01_with_endless_loop.xml')
        sentences = segmenter.segment(txt, xml: true)
        sentences.should_not be_empty
        sentences.should have(60).items
      end

      it "example II" do
        txt = load_fixture('petrov_eleg01_with_endless_loop_no_xml_header.xml')
        sentences = segmenter.segment(txt, xml: true)
        sentences.should_not be_empty
        sentences.should have(60).items
      end

      it "example III" do
        txt = load_fixture('petrov_eleg01_cleaned.xml')
        sentences = segmenter.segment(txt, xml: true)
        sentences.should_not be_empty
        sentences.should have(60).items
      end

      it "example IV" do
        txt = load_fixture('petrov_eleg02_with_internal_error.xml')
        sentences = segmenter.segment(txt, xml: true)
        sentences.should_not be_empty
        sentences.should have(74).items
      end
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
