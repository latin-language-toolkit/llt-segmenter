require 'sinatra/base'
require 'cgi'
require_relative '../lib/llt/segmenter'

class Api < Sinatra::Base
  get '/segment' do
    # handle invalid texts
    text = CGI.unescape(params['text'].to_s)
    segmenter = LLT::Segmenter.new
    sentences = segmenter.segment(text).map(&:to_s)
    if request.env["HTTP_ACCEPT"] =~ /json/i
      "[\"#{sentences.join('", "')}\"]"
    else
      to_xml(sentences, 's')
    end
  end

  def to_xml(elements, tag)
    open = "<#{tag}>"
    close = "</#{tag}>"
    "#{open}#{elements.join(close + open)}#{close}"
  end
end
