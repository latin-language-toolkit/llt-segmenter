require 'sinatra/base'
require 'sinatra/respond_with'
require 'llt/segmenter'
require 'llt/core/api'

class Api < Sinatra::Base
  register Sinatra::RespondWith
  register LLT::Core::Api::VersionRoutes
  helpers LLT::Core::Api::Helpers

  get '/segment' do
    typecast_params!(params)
    text = extract_text(params)
    segmenter = LLT::Segmenter.new(params)
    sentences = segmenter.segment(text)

    respond_to do |f|
      f.xml { to_xml(sentences, params) }
    end
  end

  add_version_route_for('/segment', dependencies: %i{ Core Segmenter })
end
