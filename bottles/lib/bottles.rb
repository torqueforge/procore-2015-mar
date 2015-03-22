module BottleNumberFactory
  refine Fixnum do
    def to_bottle_number

      case self
      when 0
        bottle_name    = NoBottles.new
        num_containers = ZeroOrMoreThanOneContainers.new
      when 1
        bottle_name    = SomeBottles.new(self)
        num_containers = OneContainer.new
      else
        bottle_name    = SomeBottles.new(self)
        num_containers = ZeroOrMoreThanOneContainers.new
      end

      BottleNumber.new(self, bottle_name: bottle_name, num_containers: num_containers)
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
  def_delegators :bottle_name, :amount, :successor
  def_delegators :num_containers, :container, :pronoun

  attr_reader :number, :bottle_name, :num_containers

  def initialize(number, bottle_name:, num_containers:)
    @number         = number
    @bottle_name    = bottle_name
    @num_containers = num_containers
  end

  def to_s
    "#{amount} #{container}"
  end

  def action
    bottle_name.action(pronoun)
  end
end

###############
class NoBottles
  def amount
    'no more'
  end

  def action(_)
    "Go to the store and buy some more"
  end

  def successor
    99.to_bottle_number
  end
end

class SomeBottles
  attr_reader :number

  def initialize(number)
    @number = number
  end

  def amount
    number.to_s
  end

  def action(pronoun)
    "Take #{pronoun} down and pass it around"
  end

  def successor
    (number - 1).to_bottle_number
  end
end


###############
class OneContainer
  def container
    "bottle"
  end

  def pronoun
    "it"
  end
end

class ZeroOrMoreThanOneContainers
  def container
    "bottles"
  end

  def pronoun
    "one"
  end
end

