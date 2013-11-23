require 'llt/core/containable'

module LLT
  module Containers
    class Sentence
      include Containable

      container_alias :tokens
    end
  end
end
