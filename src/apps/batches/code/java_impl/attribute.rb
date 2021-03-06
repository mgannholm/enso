include Java

$CLASSPATH<<'lib/runtime-1.0-SNAPSHOT.jar'

require "lib/runtime-1.0-SNAPSHOT.jar"
require "lib/mysql-connector-java-5.1.10.jar"

include_class Java::batch.sql.schema.IAttribute
include_class Java::batch.DataType

require 'apps/batches/code/java_impl/entitytype'
require 'apps/batches/code/java_impl/member'

class Attribute_Enso < Member_Enso
  include IAttribute

  #@field : CheckedObject

  def initialize(field)
    @field = field
    super(field)
  end

  #public DataType getType();
  def getType()
    if @field.type.name == "int"
      DataType.Integer
    elsif @field.type.name == "bool"
      DataType.Boolean
    elsif @field.type.name == "str"
      DataType.String
    elsif @field.type.name == "real"
      DataType.Float
    else
      raise "Unable to convert primitive type #{@field.type} to batches"
    end
  end

  #public boolean isKey();
  def isKey()
    return @field.key
  end

end
