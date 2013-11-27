require_relative '../../api/api'
require 'rack/test'
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def app
    Sinatra::Application
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.include Rack::Test::Methods
end

describe "segmenter api" do
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
