//------------------------------------------------------------------------------
// Main loop
//------------------------------------------------------------------------------
PKEngine.check_namespace('GameEngine');

PKEngine.GameEngine.MainLoop = new function()
{
  var instance_ = this

  var can_process_events_ = true

  var custom_main_loop_actions_ = false


  //----------------------------------------------------------------------------
  // private methods
  //----------------------------------------------------------------------------

  var run_frame_ = function()
  {
    requestAnimFrame(run_frame_)

    try
    {
      // Handle events (from server)
      if (can_process_events_)
        PKEngine.EventQueue.run()

      if (custom_main_loop_actions_)
        custom_main_loop_actions_()


      // Note: It's useless to move it to separate callback since
      //       JS uses cooperative multitasking still
      if (PKEngine.GUI.Renderer)
      {
        PKEngine.GUI.Renderer.render()
      }
    }
    catch (e)
    {
      var err_msg = e.toString ? e.toString() : JSON.stringify(e,null,4)
      if (e && window.console && console.log) console.log("exception stack:", e.stack)
      CRITICAL_ERROR(I18N('[PKEngine.GameEngine.MainLoop] exception: ${1}', err_msg));
    }
  }


  //----------------------------------------------------------------------------
  // public methods
  //----------------------------------------------------------------------------


  this.allow_event_processing = function()
  {
    can_process_events_ = true
  }


  this.prohibit_event_processing = function()
  {
    can_process_events_ = false
  }


  this.start = function(start_delay, custom_main_loop_actions)
  {
    custom_main_loop_actions_ = custom_main_loop_actions

    // shim layer with setTimeout fallback
    window.requestAnimFrame = (function(){
      return  window.requestAnimationFrame       ||
              window.webkitRequestAnimationFrame ||
              window.mozRequestAnimationFrame    ||
              window.oRequestAnimationFrame      ||
              window.msRequestAnimationFrame     ||
              function(/* function */ callback, /* DOMElement */ element){
                window.setTimeout(callback, 1000 / MAXIMUM_FPS);
              };
    })();

    setTimeout(run_frame_, start_delay);
  }
}
