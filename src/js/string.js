//------------------------------------------------------------------------------
// String functions
//------------------------------------------------------------------------------

/**
 * Prepend value with 0 if length < precision.
 *
 * @param value
 * @param precision
 */
PK.formatNumber = function(value, precision)
{
  value = Number(value);
  if (isNaN(value))
  {
    CRITICAL_ERROR("Wrong value!");
  }

  var parts = value.toString().split('.');
  var int_part = parts[0];
  if (parts.length > 1)
  {
    CRITICAL_ERROR("Can't format not integer number!");
  }

  if (precision === undefined)
  {
    precision = 4;
  }

  precision = Number(precision);
  if (isNaN(precision))
  {
    CRITICAL_ERROR("Wrong precision!");
  }

  if (precision < 1) {
    CRITICAL_ERROR("Can't format with precision < 1!");
  }

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

/**
 * Based on http://javascript.crockford.com/remedial.html
 *
 * @param s
 */
PK.entityify_and_escape_quotes = function (s)
{
  if (typeof(s) == "number")
  {
    return s;
  }
  //PKLILE.timing.start("entityify_and_escape_quotes")
  var result = s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  //PKLILE.timing.stop("entityify_and_escape_quotes")
  return result;
}

/**
 * Split using placeholders like '${1}', '${2}' .. '${n}' or '${key}' (from keys).
 *
 * @param source
 * @param keys
 */
PK.split_using_placeholders_old = function(source, keys)
{
  var result = [];
  var pattern = '(\\$\\{[0-9]+\\})';
  if (keys && keys.length)
  {
    for (var i = 0; i < keys.length; i++)
    {
      pattern += '|(\\$\\{'+keys[i]+'\\})';
    }

  }
  var pieces = source.split(new RegExp(pattern));
  for (var n = 0; n < pieces.length; n++)
  {
    if (pieces[n] != undefined && pieces[n] !== "")
    {
      var item = pieces[n];
      if (item.substr(0, 2) == '${' && item.substr(item.length - 1) == '}')
      {
        var key = item.substr(2, item.length - 3);
        var key_number = Number(key);
        if (!isNaN(key_number))
        {
          if (key_number == key_number.toFixed(0))
          {
            item = key_number;
          }
        }
      }
      result.push(item);
    }
  }
  return result;
}

/**
 * Split using placeholders like '${1}', '${2}' .. '${n}' or '${key}' (from keys).
 *
 * @param source
 * @param keys
 */
PK.split_using_placeholders = function(source, keys)
{
  var pieces = [];
  var need_split_with_prev = false;
  var push_to_pieces = function (item)
  {
    if (item != undefined && item !== "")
    {
      if (item.substr(0, 2) == '${' && item.substr(item.length - 1) == '}')
      {
        var key = item.substr(2, item.length - 3);
        var key_number = Number(key);
        if (!isNaN(key_number))
        {
          if (key_number == key_number.toFixed(0))
          {
            item = key_number;
          }
        }
        else if (keys && keys.length)
        {
          if (!PK.is_value_in_array(keys, key))
          {
            need_split_with_prev = true;
            if (pieces.length)
            {
              pieces[pieces.length - 1] += item;
            }
            else
            {
              pieces.push(item);
            }
            return;
          }
        }
      }
      else if (need_split_with_prev)
      {
        if (pieces.length)
        {
          pieces[pieces.length - 1] += item;
        }
        else
        {
          pieces.push(item);
        }
        need_split_with_prev = false;
        return;
      }
      pieces.push(item);
    }
  }
  var pos_from = 0;
  var pos_to = 0;
  var pos = 0;
  while (pos != -1)
  {
    pos_from = source.indexOf("${", pos);
    if (pos_from != -1)
    {
      push_to_pieces(source.substr(pos, pos_from - pos));
      pos_to = source.indexOf("}", pos_from + 2);
      if (pos_to != -1)
      {
        push_to_pieces(source.substr(pos_from, pos_to - pos_from + 1));
        pos = pos_to + 1;
      }
      else
      {
        push_to_pieces(source.substr(pos_from));
        pos = -1;
      }
    }
    else
    {
      push_to_pieces(source.substr(pos));
      pos = -1;
    }
  }
  return pieces;
}

/**
 * Fill placeholders with values.
 *
 * @param source
 * @param ivalues Array
 * @param values Object
 */
PK.fill_placeholders_old = function(source, ivalues, values)
{
  var keys = undefined;
  var placeholders_values = undefined;
  if (values)
  {
    keys = [];
    placeholders_values = {};
    for (var key in values)
    {
      keys.push(key);
      placeholders_values["${"+key+"}"] = values[key];
    }
  }
  var pieces = PK.split_using_placeholders_old(source, keys);
  var result = [];
  for (var n = 0; n < pieces.length; n++) {
    var item = pieces[n];
    if (placeholders_values)
    {
      if (placeholders_values[item])
      {
        item = placeholders_values[item];
        result.push(item);
        continue;
      }
    }
    if (typeof(item) == 'number' && ivalues)
    {
      var num = item - 1;
      if (ivalues.length > num)
      {
        item = ivalues[num];
        result.push(item);
        continue;
      }
      else
      {
        CRITICAL_ERROR(
          "Too big value placeholder number: " + ivalues.length + '<=' + num
        );
        if (window.console && console.log)
        {
          console.log("[PK.fill_placeholders] failed on data:", source, ivalues, pieces);
        }

        LOG("source: " + source);
        LOG("ivalues: " + JSON.stringify(ivalues, null, 4));
        LOG("Data: " + JSON.stringify(pieces, null, 4));
      }
    }
    result.push(item);
  }
  return result.join('');
}

/**
 * Fill placeholders with values.
 *
 * @param source
 * @param ivalues Array
 * @param values Object
 */
PK.fill_placeholders = function(source, ivalues, values)
{
  var keys = undefined;
  var placeholders_values = undefined;
  if (values)
  {
    keys = [];
    placeholders_values = {};
    for (var key in values)
    {
      keys.push(key);
      placeholders_values["${"+key+"}"] = values[key];
    }
  }
  var pieces = PK.split_using_placeholders(source, keys);
  var result = [];
  for (var n = 0; n < pieces.length; n++) {
    var item = pieces[n];
    if (placeholders_values)
    {
      if (placeholders_values[item])
      {
        item = placeholders_values[item];
        result.push(item);
        continue;
      }
    }
    if (typeof(item) == 'number' && ivalues)
    {
      var num = item - 1;
      if (ivalues.length > num)
      {
        item = ivalues[num];
        result.push(item);
        continue;
      }
      else
      {
        CRITICAL_ERROR(
          "Too big value placeholder number: " + ivalues.length + '<=' + num
        );
        if (window.console && console.log)
        {
          console.log("[PK.fill_placeholders] failed on data:", source, ivalues, pieces);
        }

        LOG("source: " + source);
        LOG("ivalues: " + JSON.stringify(ivalues, null, 4));
        LOG("Data: " + JSON.stringify(pieces, null, 4));
      }
    }
    result.push(item);
  }
  return result.join('');
}

/**
 * PK.formatString("some ${1} text ${2}", var_1, var_2) will replace ${1} by var_1 and ${2} by var_2 and etc.
 */
PK.formatString = function()
{
  if (arguments.length < 1)
  {
    return undefined;
  }

  var ivalues = Array.prototype.slice.call(arguments);
  var text = ivalues.shift();
  text = PK.fill_placeholders(text, ivalues);

  return text;
}
