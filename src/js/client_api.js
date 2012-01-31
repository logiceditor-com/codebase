//------------------------------------------------------------------------------
// Server protocol description and checks
//------------------------------------------------------------------------------

PKHB.ClientAPI = new function()
{
  var supported_version_

  this.init = function(supported_version)
  {
    supported_version_ = supported_version
  }

  this.check_version = function(received_version)
  {
    if (
        received_version &&
        received_version.name == supported_version_.name &&
        (
          Number(received_version['1']) == supported_version_['1'] &&
          Number(received_version['2']) == supported_version_['2'] &&
          Number(received_version['3']) >= supported_version_['3']
        )
      )
    {
      return true
    }

    PKHB.ERROR( I18N(
        'Invalid API version: expected ${1}, got ${2}',
        JSON.stringify(supported_version_, null, 4),
        JSON.stringify(received_version, null, 4)
      ))

    return false
  }
}
