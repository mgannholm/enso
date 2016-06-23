module Schema
  def self.object_key(obj)
    obj[obj.schema_class.key.name]
  end
  
  #run DFS on obj's parent hierarchy and return first non-nil result
  #similar to find() from Ruby's Enumerable API
  def self.lookup(obj, &block)
    res = block.call(obj)
    if res
      res
    elsif obj.supers.empty?
      nil
    else
      obj.supers.find_first do |o|
        lookup(o, &block)
      end
    end
  end
  
  def self.subclass?(a, b)
    if a.nil? || b.nil?
      false
    elsif a.name == (b.is_a?(String) ? b : b.name)
      true
    else 
      a.supers.any? do |sup|
        subclass?(sup, b)
      end
    end
  end
  
  def self.class_minimum(a, b)
    if b.nil?
      a 
    elsif a.nil?
      b
    elsif subclass?(a, b)
      a
    elsif subclass?(b, a)
      b
    else
      nil
    end
  end
  
  def self.map(obj, &block)
    if obj.nil?
      nil
    else
      res = block.call(obj)
      obj.schema_class.fields.each do |f|
        if f.traversal and !f.type.Primitive?
          if !f.many
            map(obj[f.name], &block)
          else
            res[f.name].keys.each do |k|
              map(obj[f.name][k], &block)
            end
          end
        end
      end
      res
    end
  end
end
