// PK.clone = function(obj)
// {
//   // Note: Don't use Ext.encode() since it removes holes ('undefined') from arrays!
//   return Ext.decode(JSON.stringify(obj))
// }

// TODO: Critical thing, write tests!
PK.clone = function(obj)
{
  if (typeof(obj) != "object" || obj == null)
    return obj

  var clone = obj.constructor()
  for(var i in obj)
    clone[i] = PK.clone(obj[i])
  return clone
}
