
require 'core/system/utils/paths'
require 'core/schema/code/factory'

class FromXML
  include Paths

  def self.load(schema, doc)
    self.new(schema).load(doc).finalize
  end

  def initialize(schema)
    if schema.class == ManagedData::Factory
      @schema = schema.schema
      @fact = schema
    else
      @schema = schema
      @fact = ManagedData::Factory.new(schema)
    end
  end

  def load(doc)
    @fixes = []
    root = make(doc.root)
    fixup(root)
    return root
  end
    
  private

  def make(elt)
    obj = @fact[elt.name]
    elt.attributes.each do |name, value|
      begin; obj[name] = value_of(elt.name, name, value); rescue; end
    end
    elt.elements.each do |field|
      set(obj, elt.name, field)
    end
    return obj
  end

  def set(obj, klass, field_elt)
    meta_class = @schema.classes[klass]
    field = meta_class.fields[field_elt.name]
    if field.traversal then
      if field.many then
        field_elt.elements.each do |elt|
          obj[field.name] << make(elt)
        end
      else
        obj[field.name] = make(field_elt.elements[1])
      end
    else
      refs = field_elt.get_text.value.strip.split.map do |ref|
        Path.parse(ref)
      end
      @fixes << Fix.new(obj, field, refs)
    end
  end

  def value_of(klass, field, value)
    f = @schema.classes[klass].fields[field]
    case f.type.name
    when 'str' then value
    when 'int' then value.to_i
    when 'bool' then value == 'true' ? true : false
    when 'real' then value.to_f
    when 'atom' then value # we don't know really
    else
      raise "Unsupported primitive: #{f.type.name}"
    end
  end

  def fixup(root)
    # todo: ordering
    @fixes.each do |fix|
      fix.apply(root)
    end
  end

  class Fix
    def initialize(obj, field, refs)
      @obj = obj
      @field = field
      @refs = refs
    end

    def apply(root)
      if @field.many then
        @refs.each do |ref|
          @obj[@field.name] << ref.deref(root)
        end
      else
        raise "Too many refs" if @refs.length > 1
        @obj[@field.name] = @refs.first.deref(root) unless @refs.length==0
      end
    end
  end
end



if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/schema/tools/print'
  require 'rexml/document'
  include REXML

  ss = Loader.load('schema.schema')
  l = FromXML.new(ss)

  x = l.load(Document.new(File.read('core/system/boot/schema_schema.xml')))
 
  if Equals.equals(ss, x)
    puts "Success!"
  else
    Print.print(x)
    puts "====="
    Print.print(ss)
    puts "Error: Loaded XML and original schema schema are different"
  end
end
