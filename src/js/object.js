// Note: This method has a little use since we have JSON.stringify()
PK.serialize_object = function(object, br)
{
  if (br === undefined)
    br = "\n"

  if (typeof object == "string")
    return "'" + object + "'"

  var text = ""

  for (var prop in object)
    text += prop + ": "+ object[prop]+ br

  return text
}


PK.override_object_properties = function(properties, rules, data)
{
  if (!rules) return properties

  if (!properties)
  {
    properties = {}
  }

  for (var name in rules)
  {
    if (rules[name] === true) // just set field using data
    {
      if (data[name] !== undefined)
      {
        properties[name] = data[name]
      }
      else
      {
        CRITICAL_ERROR('No mandatory data for ' + name + '!')
      }
    }

    else if (typeof(rules[name]) == "function") //set and convert field using data
    {
      var value = rules[name](data[name])
      if(value !== undefined)
        properties[name] = value
    }

    else if (typeof(rules[name]) == "object") // set field to const
    {
      if (data[name] !== undefined)
      {
        properties[name] = data[name]
      }
      else if ( rules[name].default_value !== undefined ) // set default value if necessary
      {
        properties[name] = rules[name].default_value
      }
    }
  }

  return properties
}
