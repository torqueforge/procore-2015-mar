module ContainerNumberFactory
  refine Fixnum do
    def to_container_number

      case self
      when 0
        inventory         = NoInventory.new

      when 1
        inventory         = SomeInventory.new(number:     self,
                                              container:  "bottle",
                                              quantity:   1,
                                              take:       "it")

      when lambda {|num| num % 24 == 0}
        inventory         = SomeInventory.new(number:     self,
                                              container:  "cases",
                                              quantity:   self / 24,
                                              take:       "a bottle")


      # when lambda {|num| num % 6 == 0}
      #   inventory         = SomeInventory.new(number:     self,
      #                                         container:  "6-packs",
      #                                         quantity:   self / 6,
      #                                         take:       "a bottle")

      when 6
        inventory         = SomeInventory.new(number:     self,
                                              container:  "6-pack",
                                              quantity:   1,
                                              take:       "a bottle")

      else
        inventory         = SomeInventory.new(number:     self,
                                              container:  "bottles",
                                              quantity:   self,
                                              take:       "one")
      end

      ContainerNumber.new(inventory: inventory)
    end
  end
end

using ContainerNumberFactory

class Bottles
  def song
    verses(99, 0)
  end

  def verses(upper, lower)
    upper.downto(lower).map { |i| verse(i) }.join("\n")
  end

  def verse(number)
    bottle_number      = number.to_container_number
    next_bottle_number = bottle_number.successor
    "#{bottle_number} of beer on the wall, ".capitalize +
    "#{bottle_number} of beer.\n" +
    "#{bottle_number.action}, " +
    "#{next_bottle_number} of beer on the wall.\n"
  end
end

require 'forwardable'

class ContainerNumber
  extend Forwardable
  def_delegators :inventory,
                    :action, :container, :amount, :next_verse_number

  attr_reader :inventory

  def initialize(inventory:)
    @inventory = inventory
  end

  def to_s
    "#{amount} #{container}"
  end

  def successor
    next_verse_number.to_container_number
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
  attr_reader :number, :containers, :quantity, :take

  def initialize(number:, container:, quantity: nil, amount: nil, take:)
    @number     = number
    @containers = container
    @quantity   = quantity
    @take       = take
  end

  def action
    "Take #{take} down and pass it around"
  end

  def amount
    quantity.to_s
  end

  def container
    quantity == 1 ? containers.gsub(/s$/, '') : containers
  end

  def next_verse_number
    number - 1
  end
end
