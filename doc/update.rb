require 'erb'
require 'net/http'
require 'rexml/document'

class Documenter
  def example(url)
    uri = URI(url)
    response = Net::HTTP.get(uri)
    doc = REXML::Document.new(response)
    xml = ""
    doc.write(xml, 1)
    "[#{url}](#{url})\n\n```xml\n#{xml}\n```"
  end

  def write
    directory = File.dirname(__FILE__)
    template = File.open(directory + "/examples.md.erb", 'r').read
    erb = ERB.new(template)
    File.open(directory + "/examples.md", 'w+') do |file|
      file.write(erb.result(binding))
    end
  end
end

Documenter.new.write
