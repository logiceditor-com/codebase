//------------------------------------------------------------------------------
// Web Storage
//------------------------------------------------------------------------------

PK.WebStorage = new function()
{
  var available_ = false;

  this.available = function()
  {
    return available_;
  }

  this.init = function()
  {
    if (window.localStorage === undefined)
    {
      CRITICAL_ERROR('ERROR: no localStorage() support!');
      return false;
    }
    available_ = true;
    return true;
  }

  this.read_item = function(key)
  {
    if (!this.available())
      return;

    if (!key)
      return;

    return localStorage.getItem(key);
  }

  this.set_item = function(key, value)
  {
    if (!this.available())
      return;

    if (!key)
      return;

    try
    {
      localStorage.setItem(key, value);
    }
    catch (e)
    {
      if (e == QUOTA_EXCEEDED_ERR)
      {
        CRITICAL_ERROR('WebStorage ERROR: QUOTA_EXCEEDED_ERR');
        return false;
      }
    }
    return true;
  }

  this.remove_item = function(key)
  {
    if (!this.available())
      return;

    if (!key)
      return;

    return localStorage.removeItem(key);
  }
}
