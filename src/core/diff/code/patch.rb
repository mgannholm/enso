=begin

Apply a diff result conforming to delta schema as a patch script on an object

=end

class Patch

  def self.patch!(o, deltas)
    # accepts an object o conforming to schema
    # and deltas conforming to delta-schema
    # to produce an output o' conforming to schema

    if not o.kind_of?(CheckedObject)
      #if this is a primitive object apply the changes directly
      return patch_Primitive(o, deltas)
    else
    # apply changes to each of its fields
    schema_class = deltas.schema_class
    factory = Factory.new(o.schema_class.schema)

    schema_class.fields.each do |f| #TODO: refactor this big loop into many smaller function calls
      #get field value 
      d = deltas[f.name]
      #field is nil means it was not changed
      next if d.nil?
      if not f.many
        #check which type of change this was
        if DeltaTransform.isInsertChange?(d)
          o[f.name] = patch!(o[f.name], d)
        elsif DeltaTransform.isDeleteChange?(d)
          o[f.name] = nil
        elsif DeltaTransform.isModifyChange?(d)
          o[f.name] = patch!(o[f.name], d)
        elsif DeltaTransform.isClearChange?(d)
          #do nothing
        end
      else #many-valued field
        #group all changes up by position
        ladds = {}
        ldels = {}
        lmods = {}
        max_pos = -1
        d.each do |df|
          pos = df.pos
          if DeltaTransform.isInsertChange?(df)
            ladds[pos] = [] if ladds[pos].nil?
            ladds[pos] << df
          elsif DeltaTransform.isDeleteChange?(df)
            ldels[pos] = true
          elsif DeltaTransform.isModifyChange?(df)
            lmods[pos] = df
          end
        end
        #iterate along f, keeping track of old index and new index
        # old and new indices may diverge after insertion/deletion
        i = 0
        old_l = o[f.name].values
        #FIXME: need to clear o[f.name] here
        max_pos = old_l.length-1 
        for i in 0..max_pos
          if not ladds[i].nil? 
            #(sequentially) add new elements
            ladds[i].each do |x|
              o[f.name] << add_obj(x, factory)
            end
          end
          if not lmods[i].nil?
            #if modified, replace current copy with new object
            o[f.name] << patch!(old_l[i], lmods[i])
          elsif not ldels[i]
            #if not deleted, copy into new array 
            o[f.name] << old_l[i]
          end
        end
      end
    end
    end

    return o
  end


  
  #############################################################################
  #start of private section  
  private
  #############################################################################

  def self.patch_Primitive(o, delta)
    #FIXME: update value of o based on delta. assume that delta is a creational or update change
    return o
  end
  
  # create a new object based 
  def self.add_obj(delta, factory)
    classname = DeltaTransform.getObjectName(delta)
    
    #instantiate this object
    #FIXME: check if delta is the creation of a primitive class.
    # how to create primitive classes?
    if classname == "int"
      return 0
    elsif classname == "str"
      return ""
    end
    obj = factory[classname]
    
    if obj.schema_class.Primitive?
      #do nothing for now
    else 
      #fill in fields
      obj.schema_class.fields.each do |f|
        if not f.many
          obj[f.name] = add_obj(delta[f.name], factory)
        else
          obj[f.name] = []
          delta[f.name].each do |x|
            obj[f.name] << add_obj(x, factory)
          end
        end
      end
    end

    return obj
  end
    
end