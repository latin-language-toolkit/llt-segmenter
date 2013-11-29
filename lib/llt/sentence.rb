require 'llt/core/containable'

module LLT
  class Sentence
    include Core::Containable

    xml_tag 's'
    container_alias :tokens
  end
end
