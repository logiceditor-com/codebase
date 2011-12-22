//----------------------------------------------------------------------------
// Cookies
//----------------------------------------------------------------------------
// Note: jQuery required
//

PK.check_namespace('Cookies');

PK.Cookies.set_longlive_cookie = function(key, value, options)
{
  options = options || {};
  options.expires = 365;
  $.cookie(key, value, options);
}
