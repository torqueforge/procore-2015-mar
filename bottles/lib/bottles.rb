module BottleNumberFactory
  refine Fixnum do
    def to_bottle_number

      case self
      when 0
        inventory         = NoInventory.new

      when 1
        inventory         = SomeInventory.new(number:     self,
                                              container:  "bottle",
                                              amount:     "1",
                                              take:       "it")

      when 6
        inventory         = SomeInventory.new(number:     self,
                                              container:  "6-pack",
                                              amount:     "1",
                                              take:       "a bottle")

      else
        inventory         = SomeInventory.new(number:     self,
                                              container:  "bottles",
                                              amount:     self.to_s,
                                              take:       "one")
      end

      BottleNumber.new(inventory: inventory)
    end
  end
end

using BottleNumberFactory

class Bottles
  def song
    verses(99, 0)
  end

  def verses(upper, lower)
    upper.downto(lower).map { |i| verse(i) }.join("\n")
  end

  def verse(number)
    bottle_number      = number.to_bottle_number
    next_bottle_number = bottle_number.successor
    "#{bottle_number} of beer on the wall, ".capitalize +
    "#{bottle_number} of beer.\n" +
    "#{bottle_number.action}, " +
    "#{next_bottle_number} of beer on the wall.\n"
  end
end

require 'forwardable'

class BottleNumber
  extend Forwardable
  def_delegators :inventory, :action, :container, :amount, :next_verse_number

  attr_reader :inventory

  def initialize(inventory:)
    @inventory = inventory
  end

  def to_s
    "#{amount} #{container}"
  end

  def successor
    next_verse_number.to_bottle_number
  end
end

###############
class NoInventory
  attr_reader :container, :amount, :next_verse_number

  def initialize
    @container          = "bottles"
    @amount             = "no more"
    @next_verse_number  = 99
  end

  def action
    "Go to the store and buy some more"
  end
end

class SomeInventory
  attr_reader :container, :amount, :number, :take

  def initialize(container:, take:, amount:, number:)
    @number     = number
    @container  = container
    @amount     = amount
    @take       = take
  end

  def action
    "Take #{take} down and pass it around"
  end

  def next_verse_number
    number - 1
  end
end
