class ConstraintSystem
  def initialize
    @vars = {}
    @number = 0
  end
  
  def new(name = "v#{@number}", value = nil)
    @number += 1
    return Variable.new(name, value)
  end
  
  def value(n)
    new("(#{n})", n)
  end
  
  def [](name)
    var = @vars[name]  
    var = @vars[name] = self.new if !var
    return var
  end
end

class Variable
  def initialize(name, val = nil)
    @name = name
    @dependencies = []
    @vars
    @value = val
    @bounds = []
  end

  attr_reader :name
  def to_s
    return name
  end
 
  def >=(other)
    #puts "#{self} >= #{other}"
    other.add_listener(self) if other.is_a?(Variable)
    @bounds << other
  end

  def +(other)
    var = Variable.new("p#{self.to_s}#{other.to_s}")
    #puts "#{var}=#{self.to_s}+#{other}"
    var.define(self, other) do |a, b|
      a + b
    end
  end
  
  def define(*vars, &block)
    @aggregate = vars[0].is_a?(Array) && vars.length == 1
    vars = vars[0] if @aggregate
    @vars = vars
    @vars.each do |v|
      v.add_listener(self) if v.is_a?(Variable)
    end
    #puts "#{vars}"
    @block = block
    evaluate 
    return self
  end
  
  def evaluate(path = [])
    raise "circular constraint #{path.collect(&:to_s)}" if path.include?(self)
    if @block
      path << self
      vals = @vars.collect do |var|
        if var.is_a?(Variable)
          var.evaluate(path)
        else
          var
        end
      end
      path.pop
      self.value = @aggregate ? @block.call(vals) : @block.call(*vals)
    end
    @bounds.each do |b|
      val = if b.is_a?(Variable) then b.value else b end
      @value = val if !@value || @value < val
    end
    #puts "EVAL #{@name}=#{@value}"
    @value
  end
  
  def add_listener(x)
    #puts "#{x.to_s} listening to #{self.to_s}"
    @dependencies << x
  end

  def notify
    @dependencies.each do |var|
      var.notify
    end
    #puts "CLEAR #{self.to_s}"
    @value = nil
  end
    
  def value
    evaluate unless @value
    return @value
  end
  
  def value=(x)
    notify
    @value = x
  end
end
  
