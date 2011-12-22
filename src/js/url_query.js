//----------------------------------------------------------------------------
// URL query parameters
//----------------------------------------------------------------------------
//
// Note: jQuery required
//

PK.Query = new function()
{
  var query_params_

  this.init = function(query_patcher)
  {
    query_params_ = $.parseQuery()

    // TODO: FIXME: Remove when correct implementation of parseQuery would be used
    //              Current implementation returns {"":"undefined"} on empty query
    if (PK.count_properties(query_params_) == 1 && query_params_[""] == "undefined")
    {
      query_params_ = {}
    }

    if (query_patcher)
      query_patcher(query_params_)

    return query_params_
  }


  this.get = function(name)
  {
    if (!query_params_)
      return undefined
    return query_params_[name]
  }


  this.get_bool = function(name)
  {
    if (!query_params_)
      return false

    return (
           query_params_[name] == '1'
        || query_params_[name] == 'yes'  || query_params_[name] == 'YES'
        || query_params_[name] == 'on'   || query_params_[name] == 'ON'
        || query_params_[name] == 'true' || query_params_[name] == 'TRUE'
      )
  }
}
