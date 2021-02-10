function get_nested(dct, keys)
   for key in keys
      try
         dct = dct[key]
      catch KeyError
         return nothing
      end
   end
   return dct
end

function set_nested!(dct, dct_keys, value)
   for key in dct_keys[1:end-1]
      if key in keys(dct)
         dct = dct[key]
      else
         dct[key] = Dict()
         dct = dct[key]
      end
   end
   key = dct_keys[end]
   dct[key] = value
end

function traverse_nested(dct, keys=[], output=[], inter_keys=[])
   for (key, value) in dct
      temp_keys = copy(inter_keys)
      push!(temp_keys, key)
      if value isa AbstractDict
         traverse_nested(value, keys, output, temp_keys)
      else
         push!(output, value)
         push!(keys, temp_keys)
      end
   end
   return keys, output
end

function combine_nested!(primary_dct, secondary_dct)
   for (key,val) in secondary_dct
      # recurse if the primary dictionary already has the key and the value is a dictionary,
      # otherwise the value can be saved to the primary
      if (key in keys(primary_dct)) && (val isa AbstractDict)
         combine_nested!(primary_dct[key], val)
      else
         primary_dct[key] = val
      end
   end
end
