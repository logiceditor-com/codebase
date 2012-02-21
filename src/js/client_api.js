//------------------------------------------------------------------------------
// client_api.js: Server protocol description and checks
// This file is a part of pk-engine-js library
// Copyright (c) Alexander Gladysh <ag@logiceditor.com>
// Copyright (c) Dmitry Potapov <dp@logiceditor.com>
// See file `COPYRIGHT` for the license
//------------------------------------------------------------------------------

PKEngine.ClientAPI = new function()
{
  var supported_version_;
  var received_version_;

  this.init = function(supported_version)
  {
    supported_version_ = supported_version;
  }

  this.get_client_version = function()
  {
    return supported_version_;
  }

  this.get_server_version = function()
  {
    return received_version_;
  }

  this.check_version = function(received_version)
  {
    received_version_ = received_version;

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
      return true;
    }

    CRITICAL_ERROR( I18N(
        'Invalid API version: expected ${1}, got ${2}',
        JSON.stringify(supported_version_, null, 4),
        JSON.stringify(received_version, null, 4)
      ));

    return false;
  }
}
