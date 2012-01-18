/**
 * String functions.
 */

/**
 * Prepend value with 0 if length < precision.
 *
 * @param value
 * @param precision
 */
PK.formatNumber = function(value, precision)
{
  var parts = value.toString().split('.');
  var int_part = parts[0];
  if (parts.length > 1)
  {
    CRITICAL_ERROR("Can't format not integer number!");
  }

  if (precision === undefined)
    precision = 4;

  if (precision < 2)
    return value;

  if (int_part.length < precision)
  {
    return new Array(precision - int_part.length + 1).join('0') + int_part;
  }
  else if (int_part.length == precision)
  {
    return value;
  }
  else
  {
    CRITICAL_ERROR("Can't format big number!");
  }
}

// Based on http://javascript.crockford.com/remedial.html
PK.entityify_and_escape_quotes = function (s)
{
  if(typeof(s) == "number")
    return s
  //PKLILE.timing.start("entityify_and_escape_quotes")
  var result = s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
  //PKLILE.timing.stop("entityify_and_escape_quotes")
  return result
}

// TODO: Note:
//   1. 's' must contain no separators!
//   2. Very non-optimal, reduce to one iteration
PK.split_using_placeholders = function(s, keys)
{
  //PKLILE.timing.start("split_using_placeholders")
  var SEPARATOR = '{%_SEP_%}'

  var num_placehoders = 0, placeholder_found = true

  while (true)
  {
    num_placehoders++
    var placeholder = '${' + num_placehoders + '}'
    if( s.indexOf(placeholder) < 0 )
      break
    s = s.replace(placeholder, SEPARATOR + placeholder + SEPARATOR)
  }
  num_placehoders--

  if(keys)
  {
    for (var i = 0; i < keys.length; i++)
    {
      var placeholder = '${' + keys[i] + '}'
      if( s.indexOf(placeholder) >= 0 )
      {
        s = s.replace(placeholder, SEPARATOR + placeholder + SEPARATOR)
      }
    }
  }

  var splitted = s.split(SEPARATOR)

  //LOG("Splitting " + s + " using " + JSON.stringify(keys, null, 4) + " : " + JSON.stringify(splitted, null, 4))


  var result = []
  for(var i = 0; i < splitted.length; i++)
  {
    if (splitted[i].match(/\$\{\d+\}/g))
    {
      result.push(Number(splitted[i].replace(/[\$\{\}]/g, "")))
    }
    else if (splitted[i] != "")
    {
      result.push(splitted[i])
    }

  }

  //PKLILE.timing.stop("split_using_placeholders")
  return result
}


//TODO: Use 'values' also (and generate keys from them)
PK.fill_placeholders = function(s, ivalues)
{
  var keys = undefined, values = undefined
  var data_with_ph = PK.split_using_placeholders(s, keys)
  if (!data_with_ph)
    return s

  //PKLILE.timing.start("fill_placeholders")

  var result = []

  for(var i = 0; i < data_with_ph.length; i++)
  {
    if (typeof(data_with_ph[i]) == "number")
    {
      var num = data_with_ph[i] - 1
      if (ivalues.length > num)
      {
        result = result.concat(ivalues[num])
      }
      else
      {
        CRITICAL_ERROR(
            "Too big value placeholder number: " + ivalues.length + '<=' + num
          )
        if(window.console && console.log)
        {
          console.log("[PK.fill_placeholders] failed on data:", s, ivalues, data_with_ph)
        }

        LOG("s: " + s)
        LOG("ivalues: " + JSON.stringify(ivalues, null, 4))
        LOG("Data: " + JSON.stringify(data_with_ph, null, 4))
      }
    }
    else if (values && values[data_with_ph[i]] !== undefined)
    {
      result.push(values[data_with_ph[i]])
    }
    else
    {
      result.push(data_with_ph[i])
    }
  }

  var out = result.join('')
  //PKLILE.timing.stop("fill_placeholders")
  return out
}

// Note: PK.formatString("some ${1} text ${2}", var_1, var_2) will replace ${1} by var_1 and ${2} by var_2 and etc.
PK.formatString = function()
{
  if (arguments.length < 1)
    return undefined

  var ivalues = Array.prototype.slice.call(arguments)
  var text = ivalues.shift()
  text = PK.fill_placeholders(text, ivalues)

  return text
}
