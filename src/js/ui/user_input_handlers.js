//------------------------------------------------------------------------------
// Callbacks handling UI events: mouse, keyboard etc.
//------------------------------------------------------------------------------

PKEngine.UserInputHandlers = new function()
{
  var user_input_provider_;

  //  Core thing, should be moved into pk-core-js later
  var prepare_event_ = function(e)
  {
    if (e === undefined)
    {
      return window.event
    }
    return e
  }

  //  Core thing, should be moved into pk-core-js later
  var prevent_event_ = function(e)
  {
    if(e.preventDefault)
      e.preventDefault()
    else
      e.returnValue = false
  }

  //----------------------------------------------------------------------------

  // Must return 'true' if we can process user input now
  var additional_input_handling_preventor_;

  var input_handling_is_enabled_ = function()
  {
    if (!PKEngine.GUI.Viewport.is_ready())
      return false

    if (additional_input_handling_preventor_)
      return additional_input_handling_preventor_()

    return true
  }

  //----------------------------------------------------------------------------

  var get_cursor_coords_;

  var get_coords_shift_ = function()
  {
    return {
      x: (document.body.scrollLeft - user_input_provider_.offsetLeft),
      y: (document.body.scrollTop - user_input_provider_.offsetTop)
    }
  }

  //----------------------------------------------------------------------------

  this.init = function(platform_type, game_field)
  {
    user_input_provider_ = game_field;

    switch (platform_type)
    {
      case PKEngine.Platform.TYPE.IPAD:
        get_cursor_coords_ = function(e)
        {
          var coords_shift = get_coords_shift_();
          return {
            x: (e.changedTouches.item(e.changedTouches.length - 1).clientX + coords_shift.x),
            y: (e.changedTouches.item(e.changedTouches.length - 1).clientY + coords_shift.y)
          };
        }

        additional_input_handling_preventor_ = function()
        {
          if (window.orientation == 0 || window.orientation == 180)
            return false
          return true
        }

        user_input_provider_.ontouchstart = PKEngine.UserInputHandlers.on_mouse_down;
        user_input_provider_.ontouchend = PKEngine.UserInputHandlers.on_mouse_up;
        user_input_provider_.ontouchmove = PKEngine.UserInputHandlers.on_mouse_move;
      break;

      default:
        get_cursor_coords_ = function(e)
        {
          var coords_shift = get_coords_shift_();
          return {
            x: (e.clientX + coords_shift.x),
            y: (e.clientY + coords_shift.y)
          };
        }

        user_input_provider_.onmousedown = PKEngine.UserInputHandlers.on_mouse_down;
        user_input_provider_.onmouseup = PKEngine.UserInputHandlers.on_mouse_up;
        user_input_provider_.onmousemove = PKEngine.UserInputHandlers.on_mouse_move;
    }
  }

  //----------------------------------------------------------------------------

  this.on_mouse_down = function(e)
  {
    try
    {
      if(!input_handling_is_enabled_())
        return 0;
      e = prepare_event_(e)

      var mouse_coords = get_cursor_coords_(e);

      PKEngine.GUI.Viewport.on_mouse_down(mouse_coords.x, mouse_coords.y)

      prevent_event_(e)
    }
    catch (e)
    {
      var err_msg = e.toString ? e.toString() : JSON.stringify(e,null,4)
      if (e && window.console && console.log) console.log("exception stack:", e.stack)
      PKEngine.ERROR(I18N('[PKEngine.UserInputHandlers.on_mouse_down] exception: ${1}', err_msg));
    }

    return false;
  }

  //----------------------------------------------------------------------------

  this.on_mouse_up = function(e)
  {
    try
    {
      if(!input_handling_is_enabled_())
        return 0;
      e = prepare_event_(e)

      var mouse_coords = get_cursor_coords_(e);

      PKEngine.GUI.Viewport.on_click(mouse_coords.x, mouse_coords.y)

      prevent_event_(e)
    }
    catch (e)
    {
      var err_msg = e.toString ? e.toString() : JSON.stringify(e,null,4)
      if (e && window.console && console.log) console.log("exception stack:", e.stack)
      PKEngine.ERROR(I18N('[PKEngine.UserInputHandlers.on_mouse_up] exception: ${1}', err_msg));
    }

    return false;
  }

  //----------------------------------------------------------------------------

  this.on_mouse_move = function(e)
  {
    try
    {
      if(!input_handling_is_enabled_())
        return 0;
      e = prepare_event_(e)

      var mouse_coords = get_cursor_coords_(e);

      PKEngine.GUI.Viewport.on_mouse_move(mouse_coords.x, mouse_coords.y);

      prevent_event_(e)
    }
    catch (e)
    {
      var err_msg = e.toString ? e.toString() : JSON.stringify(e,null,4)
      if (e && window.console && console.log) console.log("exception stack:", e.stack)
      PKEngine.ERROR(I18N('[PKEngine.UserInputHandlers.on_mouse_move] exception: ${1}', err_msg));
    }

    return false;
  }
}
