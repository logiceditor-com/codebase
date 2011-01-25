PK.override_object_properties = function(properties, rules, data)
{
  if (!rules) return properties

  if (!properties)
  {
    properties = {}
  }

  for (name in rules)
  {
    if (rules[name] === true) // just set field using data
    {
      if (data[name] !== undefined)
        properties[name] = data[name]
    }

    else if (typeof(rules[name]) == "function") //set and convert field using data
    {
      var value = rules[name](data[name])
      if(value !== undefined)
        properties[name] = value
    }

    else if (typeof(rules[name]) == "object") // set field to const
    {
      if ( rules[name].value !== undefined ) // value setter or constant
      {
        if (typeof(rules[name].value) == "function") // value maker
        {
          var value = rules[name].value(data[name])
          if(value !== undefined)
            properties[name] = value
        }
        else // const value
        {
          properties[name] = rules[name].value
        }
      }
    }
  }

  return properties
}
