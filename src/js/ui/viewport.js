//------------------------------------------------------------------------------
// Viewport container
//------------------------------------------------------------------------------

PKEngine.check_namespace('GUI')

PKEngine.GUI.Viewport = new function()
{
  // NOTE: first element - last viewed screen
  //       list type - [{'screen':screen_name, 'params':param_1}, ...]
  var screens_list_ = []
  var MAX_SCREENS_LIST_LENGTH = 10

  var is_drawing_
  var must_redraw_

  var instance_ = this

  //----------------------------------------------------------------------------

  var show_screen_ = function(screen, param_1)
  {
    PKEngine.GUIControls.get_screen(screen).show(param_1)
    instance_.request_redraw(screen, param_1)
  }

  //----------------------------------------------------------------------------

  this.is_ready = function()
  {
    return !!this.get_current_screen()
  }

  this.get_current_screen = function()
  {
    if (screens_list_.length == 0)
      return false

    return screens_list_[0].screen
  }

  this.get_current_screen_data = function()
  {
    if (screens_list_.length == 0)
      return false

    return screens_list_[0]
  }

  //----------------------------------------------------------------------------

  this.get_previous_screen = function()
  {
    if (screens_list_.length < 2)
      return false

    return screens_list_[1].screen
  }

  //----------------------------------------------------------------------------

  this.return_to_previous_screen = function(do_additional_checks)
  {
    //console.log(
    //    "[PKHB.GUIControls.Viewport.return_to_previous_screen]",
    //    do_additional_checks, this.get_current_screen_data(), this.get_previous_screen()
    //  )

    if (do_additional_checks === undefined) do_additional_checks = true


    // NOTE: Return to game_field only when get training status. May be game was ended.
    if (do_additional_checks && this.get_previous_screen() == PKEngine.GUIControls.SCREEN_NAMES.GameScreen)
    {
      ajax_getTrainingStatus( function(game_state) {
          PKEngine.User.notify_training_data(game_state)

          if(game_state.error != undefined)
          {
            switch(game_state.error)
            {
              case "TRAINING_IN_PROGRESS":
                // Tried to start a new game, but a has a game in progress
                ajax_getTrainingStatus();
                return;

              case "NOT_AVAILABLE":
                PKEngine.GUI.Go_to_main_menu(false)
                return;

              case "NOT_ENOUGH_MONEY":
                GUI_ERROR(I18N('Not enough money, please, refill your account'));
                return;

              default:
                PKEngine.GUI.Go_to_main_menu(false)
            }

            PKEngine.Ajax.on_soft_error_received("training_status", game_state.error);
            return;
          }

          // TODO: A bit hakish, but we should remove current screen from history
          screens_list_.shift()

          PKEngine.GameEngine.GameInstance.on_received_training_status(game_state)
        })
      return
    }


    screens_list_.shift()

    var screen_data = this.get_current_screen_data()

    show_screen_(screen_data.screen, screen_data.params)
  }

  //----------------------------------------------------------------------------

  this.show_screen = function(screen, param_1)
  {
    //console.log("[PKHB.GUIControls.Viewport.show_screen]", screen)

    screens_list_.unshift({'screen':screen, 'params':param_1})

    if (screens_list_.length > MAX_SCREENS_LIST_LENGTH)
      for (var i=0; i<(screens_list_.length - MAX_SCREENS_LIST_LENGTH); i++)
        screens_list_.pop()

    show_screen_(screen, param_1)

    //console.log("screen:", screen)
    //console.log(window.printStackTrace().join("\n"))
  }

  //----------------------------------------------------------------------------

  this.request_redraw = function(notify_current_screen_if_possible)
  {
    //console.log("[PKHB.GUIControls.Viewport.request_redraw]", notify_current_screen_if_possible)

    if(must_redraw_)
      return

    if (notify_current_screen_if_possible === undefined)
    {
      notify_current_screen_if_possible = true
    }

    must_redraw_ = true

    if (this.is_ready() && notify_current_screen_if_possible)
    {
      var current_screen = PKEngine.GUIControls.get_screen(this.get_current_screen())
      if (current_screen && current_screen.request_redraw)
        current_screen.request_redraw()
    }
  }

  //----------------------------------------------------------------------------

  this.is_drawing = function()
  {
    return is_drawing_
  }

  this.notify_control_draw_start = function()
  {
    assert(is_drawing_, I18N("Viewport: Tried to draw control outside of draw"))
  }

  //----------------------------------------------------------------------------

  this.draw = function()
  {
    if(!this.is_ready())
      return false

    assert(!is_drawing_, I18N("Viewport: Tried to call draw recursively"))

    if (!must_redraw_)
      return

    //console.log("[PKHB.GUI.Viewport.draw]")

    must_redraw_ = false

    is_drawing_ = true

    PKEngine.GUIControls.get_screen(this.get_current_screen()).draw()

    is_drawing_ = false
  }

  //----------------------------------------------------------------------------

  this.on_mouse_down = function(x, y)
  {
    if(!this.is_ready())
      return false

    PKEngine.GUIControls.get_screen(this.get_current_screen()).on_mouse_down(x, y)
  }

  this.on_click = function(x, y)
  {
    if(!this.is_ready())
      return false

    PKEngine.GUIControls.get_screen(this.get_current_screen()).on_click(x, y)
  }

  this.on_mouse_move = function(x, y)
  {
    if(!this.is_ready())
      return false

    PKEngine.GUIControls.get_screen(this.get_current_screen()).on_mouse_move(x, y)
  }

  //----------------------------------------------------------------------------

  this.show_game_field = function()
  {
    $('#div_loader').hide();
    $('#game_field').show();
  }

  this.hide_game_field = function()
  {
    $('#div_loader').hide();
    $('#game_field').hide();
  }
}
