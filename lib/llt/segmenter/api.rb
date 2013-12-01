require 'sinatra/base'
require 'sinatra/respond_with'
require 'llt/segmenter'

class Api < Sinatra::Base
  register Sinatra::RespondWith

  get '/segment' do
    text = h(params[:text])
    segmenter = LLT::Segmenter.new
    sentences = segmenter.segment(text)

    respond_to do |f|
      f.xml { to_xml(sentences, params) }
    end
  end

  def to_xml(elements, params = {})
    elements.each_with_object('') do |e, str|
      str << e.to_xml(*markup_params(params))
    end
  end

  module HtmlEscaper
    def h(text)
      Rack::Utils.escape_html(text)
    end

    def markup_params(params)
      []
    end
  end

  helpers HtmlEscaper
end
