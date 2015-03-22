module BottleNumberFactory
  refine Fixnum do
    def to_bottle_number

      case self
      when 0
        num_containers    = ContainersOtherThanOneDescription.new
        bottle_name       = NoInventory.new
        amount_descriptor = ZeroAmountDescription.new
      when 1
        num_containers    = OneContainerDescription.new
        bottle_name       = SomeInventory.new(self, take_descriptor: TakeLastOne.new)
        amount_descriptor = MappedAmountDescription.new
      when 6
        num_containers    = OneSixPackDescription.new
        bottle_name       = SomeInventory.new(self, take_descriptor: TakeOneFromSixPack.new)
        amount_descriptor = SixPackAmountDescription.new
      else
        num_containers    = ContainersOtherThanOneDescription.new
        bottle_name       = SomeInventory.new(self, take_descriptor: TakeOneOfMany.new)
        amount_descriptor = MappedAmountDescription.new
      end

      BottleNumber.new(self,
                       bottle_name:       bottle_name,
                       num_containers:    num_containers,
                       amount_descriptor: amount_descriptor)
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
  def_delegators :bottle_name, :action, :successor
  def_delegators :num_containers, :container, :pronoun

  attr_reader :number, :bottle_name, :num_containers, :amount_descriptor

  def initialize(number, bottle_name:, num_containers:, amount_descriptor:)
    @number         = number
    @bottle_name    = bottle_name
    @num_containers = num_containers
    @amount_descriptor = amount_descriptor
  end

  def amount
    amount_descriptor.format(number)
  end

  def to_s
    "#{amount} #{container}"
  end
end

###############
class NoInventory
  def action
    "Go to the store and buy some more"
  end

  def successor
    99.to_bottle_number
  end
end

class SomeInventory
  attr_reader :number, :take_descriptor

  def initialize(number, take_descriptor:)
    @number = number
    @take_descriptor = take_descriptor
  end

  def action
    "Take #{take_descriptor.take} down and pass it around"
  end

  def successor
    (number - 1).to_bottle_number
  end
end


###############
class OneContainerDescription
  def container
    "bottle"
  end
end

class ContainersOtherThanOneDescription
  def container
    "bottles"
  end
end

class OneSixPackDescription
  def container
    "6-pack"
  end
end


###############
class ZeroAmountDescription
  def format(_)
    'no more'
  end
end

class MappedAmountDescription
  def format(number)
    number.to_s
  end
end

class SixPackAmountDescription
  def format(number)
    '1'
  end
end

###############
class TakeLastOne
  def take
    'it'
  end
end

class TakeOneOfMany
  def take
    'one'
  end
end

class TakeOneFromSixPack
  def take
    'a bottle'
  end
end
