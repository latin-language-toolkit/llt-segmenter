require 'sinatra/base'
require 'sinatra/respond_with'
require 'llt/segmenter'
require 'llt/core/api'

class Api < Sinatra::Base
  register Sinatra::RespondWith
  helpers LLT::Core::Api::Helpers

  get '/segment' do
    text = params[:text].to_s
    segmenter = LLT::Segmenter.new(params)
    sentences = segmenter.segment(text)

    respond_to do |f|
      f.xml { to_xml(sentences, params) }
    end
  end
end
