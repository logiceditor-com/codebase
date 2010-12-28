//------------------------------------------------------------------------------
//  Initialize pk core js library
//------------------------------------------------------------------------------

if (PK === undefined)
{
  var PK = new function()
  {
    this.check_namespace = function(name)
    {
      if (this[name] === undefined)
        this[name] = new Object
      return this[name]
    }
  }
}