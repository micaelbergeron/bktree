require 'text/levenshtein'
require 'yaml'

module BK
  # Paul Battley 2007
  # See http://blog.notdot.net/archives/30-Damn-Cool-Algorithms,-Part-1-BK-Trees.html
  # and http://www.dcc.uchile.cl/~gnavarro/ps/spire98.2.ps.gz

  class LevenshteinDistancer
    def call(a, b)
      Text::Levenshtein.distance(a, b)
    end
  end

  class Node
    attr_reader :term, :children
    attr_accessor :data

    def initialize(term, distancer, data=nil)
      @term = term
      @children = {}
      @distancer = distancer
      @data = data
    end

    def add(term, data=nil)
      score = distance(term)
      if child = children[score]
        child.add term, data
      else
        children[score] = Node.new(term, @distancer, data)
      end
    end

    def query(term, threshold, collected)
      distance_at_node = distance(term)

      if distance_at_node <= threshold
        collected[self.term] = { dist: distance_at_node,
                                 data: self.data }
      end
      # TODO: remove this recursion
      (-threshold..threshold).each do |d|
        child = children[distance_at_node + d] or next
        child.query term, threshold, collected
      end
    end

    def distance(term)
      @distancer.call term, self.term
    end
  end

  class Tree
    def initialize(distancer = LevenshteinDistancer.new)
      @root = nil
      @distancer = distancer
    end

    def add(term, data=nil)
      if @root
        @root.add term, data
      else
        @root = Node.new(term, @distancer, data)
      end
    end

    def query(term, threshold)
      collected = {}
      @root.query term, threshold, collected
      return collected
    end

    def export(stream)
      stream.write YAML.dump(self)
    end

    def self.import(stream)
      YAML.load(stream.read)
    end
  end
end
