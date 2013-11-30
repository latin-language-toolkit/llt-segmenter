ENV['RACK_ENV'] = 'test'

require 'spec_helper'
require_relative '../../api/api'
require 'rack/test'

def app
  Api
end

describe "segmenter api" do
  include Rack::Test::Methods

  describe '/segment' do
    context "with URI as input" do
      it "responds to GET" do
        get '/segment'
        last_response.should be_ok
      end
    end

    let(:text) {{text: "homo mittit. Marcus est."}}

    context "with text as input" do
      context "with accept header json" do
        it "segments the given sentences" do
          get '/segment', text,
            {"HTTP_ACCEPT" => "application/json"}
          last_response.should be_ok
          response = last_response.body
          parsed_response = JSON.parse(response)
          parsed_response.should have(2).items
        end
      end

      context "with accept header xml" do
        it "segments the given sentences" do
          get '/segment', text,
            {"HTTP_ACCEPT" => "application/xml"}
          last_response.should be_ok
          body = last_response.body
          body.should =~ /<s>homo mittit\.<\/s>/
          body.should =~ /<s>Marcus est\.<\/s>/
        end
      end
    end
  end
end
