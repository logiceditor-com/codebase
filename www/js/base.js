//------------------------------------------------------------------------------
//  Initialize pk admin library
//------------------------------------------------------------------------------

if (PKAdmin === undefined)
{
  var PKAdmin = new function()
  {
    this.check_namespace = function(name)
    {
      if (this[name] === undefined)
        this[name] = new Object
      return this[name]
    }
  }
}
