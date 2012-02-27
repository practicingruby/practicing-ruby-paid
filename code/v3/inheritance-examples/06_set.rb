require "set"
require "pstore"

class PersistentSet 
  def initialize(filename)
    self.store = PStore.new(filename)

    store.transaction { store[:data] ||= Set.new }
  end

  def method_missing(name, *args, &block)
    store.transaction do 
      store[:data].send(name, *args, &block)
    end
  end

  private

  attr_accessor :store
end


set = PersistentSet.new("sample.store")
set.add(121)

require "forwardable"

class ImmutableSet
  def initialize(set)
    self.data = set
  end

  include Enumerable

  def member?(element)
    data.member?(element)
  end

  def each
    data.each { |e| yield(e) }
  end

  # any other non-modifying operations can be exposed here.

  private

  attr_accessor :data
end
