//------------------------------------------------------------------------------
// integrity.js: check PKEngine integrity
// This file is a part of pk-engine-js library
// Copyright (c) Alexander Gladysh <ag@logiceditor.com>
// Copyright (c) Dmitry Potapov <dp@logiceditor.com>
// See file `COPYRIGHT` for the license
//------------------------------------------------------------------------------

PKEngine.Integrity = new function()
{
  var INTEGRITY_CHECK_TIMEOUT_ = 500; // in ms.

  var custom_checker_;

  var must_check_integrity_ = true;

  var check_integrity_timer_;

  //----------------------------------------------------------------------------

  this.init = function(custom_checker)
  {
    custom_checker_ = custom_checker;

    check_integrity_timer_ = PK.Timer.make();

    check_integrity_timer_.start(INTEGRITY_CHECK_TIMEOUT_);
  }

  //----------------------------------------------------------------------------

  this.check = function()
  {
    if (!must_check_integrity_ || !check_integrity_timer_.is_complete())
      return false;

    must_check_integrity_ = false;

    if (!PKEngine.UserInputHandlers.check_integrity())
    {
       // TODO: localize
       CRITICAL_ERROR(I18N("Integrity check failed! Click 'close' to reload the game!"));
    }

    if (custom_checker_)
    {
      custom_checker_();
    }

    must_check_integrity_ = true;
    check_integrity_timer_.start(INTEGRITY_CHECK_TIMEOUT_);
  }
}
