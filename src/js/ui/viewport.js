//------------------------------------------------------------------------------
// Viewport container
//------------------------------------------------------------------------------

PKEngine.check_namespace('GUI')

PKEngine.GUI.Viewport = new function()
{
  // NOTE: first element - last viewed screen
  //       list type - [{'screen':screen_name, 'params':param_1}, ...]
  this.screens_list_ = [];
  this.MAX_screens_list_LENGTH = 10;

  this.is_drawing_ = undefined;
  this.must_redraw_ = undefined;

  var instance_ = this;

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
    if (this.screens_list_.length == 0)
      return false

    return this.screens_list_[0].screen
  }

  this.get_current_screen_data = function()
  {
    if (this.screens_list_.length == 0)
      return false

    return this.screens_list_[0]
  }

  //----------------------------------------------------------------------------

  this.get_previous_screen = function()
  {
    if (this.screens_list_.length < 2)
      return false

    return this.screens_list_[1].screen
  }

  //----------------------------------------------------------------------------

  this.return_to_previous_screen = function()
  {
    this.screens_list_.shift();
    var screen_data = this.get_current_screen_data();
    show_screen_(screen_data.screen, screen_data.params);
  }

  //----------------------------------------------------------------------------

  this.show_screen = function(screen, param_1)
  {
    //console.log("[PKHB.GUIControls.Viewport.show_screen]", screen)

    this.screens_list_.unshift({'screen':screen, 'params':param_1})

    if (this.screens_list_.length > this.MAX_screens_list_LENGTH)
      for (var i=0; i<(this.screens_list_.length - this.MAX_screens_list_LENGTH); i++)
        this.screens_list_.pop()

    show_screen_(screen, param_1)

    //console.log("screen:", screen)
    //console.log(window.printStackTrace().join("\n"))
  }

  //----------------------------------------------------------------------------

  this.request_redraw = function(notify_current_screen_if_possible)
  {
    //console.log("[PKHB.GUIControls.Viewport.request_redraw]", notify_current_screen_if_possible)

    if(this.must_redraw_)
      return

    if (notify_current_screen_if_possible === undefined)
    {
      notify_current_screen_if_possible = true
    }

    this.must_redraw_ = true

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
    return this.is_drawing_
  }

  this.notify_control_draw_start = function()
  {
    assert(this.is_drawing_, I18N("Viewport: Tried to draw control outside of draw"))
  }

  //----------------------------------------------------------------------------

  this.draw = function()
  {
    if(!this.is_ready())
      return false

    assert(!this.is_drawing_, I18N("Viewport: Tried to call draw recursively"))

    if (!this.must_redraw_)
      return

    //console.log("[PKHB.GUI.Viewport.draw]")

    this.must_redraw_ = false

    this.is_drawing_ = true

    PKEngine.GUIControls.get_screen(this.get_current_screen()).draw()

    this.is_drawing_ = false
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
}
