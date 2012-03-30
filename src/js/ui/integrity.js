//------------------------------------------------------------------------------
// integrity.js: check PKEngine integrity
// This file is a part of pk-engine-js library
// Copyright (c) Alexander Gladysh <ag@logiceditor.com>
// Copyright (c) Dmitry Potapov <dp@logiceditor.com>
// See file `COPYRIGHT` for the license
//------------------------------------------------------------------------------

PKEngine.Integrity = new function()
{
  var callback_;

  var check_integrity_ = true;
  var check_integrity_timer_;
  var platform_type_;
  var user_input_provider_;

  //----------------------------------------------------------------------------

  this.init = function(platform_type, user_input_provider, callback)
  {
    platform_type_ = platform_type;
    user_input_provider_ = user_input_provider;

    if (typeof callback == "function")
    {
      callback_ = callback;
    }
  }

  //----------------------------------------------------------------------------

  this.check = function()
  {
    if (!check_integrity_)
      return false;

    if (!check_integrity_timer_)
    {
      check_integrity_timer_ = PK.Timer.make();
      check_integrity_timer_.start(500);
    }

    if (!check_integrity_timer_.is_complete())
      return false;

    if
      (
        platform_type_ == PKEngine.Platform.TYPE.IPAD
        && (
                !user_input_provider_.ontouchstart
             || !user_input_provider_.ontouchend
             || !user_input_provider_.ontouchmove
           )
      )
    {
       check_integrity_ = false;

       if (typeof callback_ == "function")
         callback_();

       // TODO: localize
       CRITICAL_ERROR(I18N("Game has wrong state! Click on close button for reloading game!"));

       // NOTE: reinitialize input handlers
       //PKEngine.UserInputHandlers.init();
    }
  }
}
