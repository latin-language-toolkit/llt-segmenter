require 'llt/core/containable'

module LLT
  class Sentence
    include Core::Containable

    container_alias :tokens
  end
end
