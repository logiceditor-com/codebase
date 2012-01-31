//------------------------------------------------------------------------------
// Initialization of base project things
//------------------------------------------------------------------------------

if (PKEngine === undefined)
{
  var PKEngine = new function()
  {
    this.check_namespace = function(name)
    {
      if (this[name] === undefined)
        this[name] = new Object
      return this[name]
    }
  }
}
