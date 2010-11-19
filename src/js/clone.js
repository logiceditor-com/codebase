PK.clone = function(obj)
{
  // Note: Don't use Ext.encode() since it removes holes ('undefined') from arrays!
  return Ext.decode(JSON.stringify(obj))
}