//------------------------------------------------------------------------------
// Simple logging / error output system
//------------------------------------------------------------------------------

PK.log_system = new function()
{
  var default_gui_msg_printer_ = function(text)
  {
    if (window.Ext)
    {
      if (Ext.isReady)
        Ext.Msg.alert('Failure', text)
    }
    else
    {
      alert(text)
    }
  }

  // ------------------ private --------------------------

  var events_ = new Array();

  var printer_ = default_gui_msg_printer_;

  var custom_error_handlers = [];

  // ------------------ public --------------------------

  this.GUI_EOL = "<br>"

  this.set_printer = function(printer)
  {
    printer_ = printer
  };

  this.get_printer = function()
  {
    return printer_
  };

  this.add = function(event)
  {
    events_[events_.length] = event
  };

  this.list = function()
  {
    return events_
  }

  /**
   * Add function to critical error handling process
   * callback = function (text) { ... return text }
   */
  this.add_custom_error_handler = function (callback)
  {
    custom_error_handlers.push(callback);
  }

  /**
   * Get functions to critical error handling process
   */
  this.get_custom_error_handlers = function ()
  {
    return custom_error_handlers;
  }
}

var LOG = PK.log_system.add

var GUI_ERROR = function(text)
{
  if (window.Ext)
  {
    if (Ext.isReady)
      Ext.Msg.alert('Failure', text)
    else
      LOG('GUI ERROR: ' + text)
  }
  else
  {
    var printer = PK.log_system.get_printer()
    if(printer)
      printer(text)
  }
}

var CRITICAL_ERROR = function(text)
{
  var text_gui, text_log

  var custom_handlers = PK.log_system.get_custom_error_handlers();
  for (var i = 0; i < custom_handlers.length; i++)
  {
    text = custom_handlers[i](text);
  }

  if (window.printStackTrace)
  {
    var tb_lines = ["********** Stack Trace **********"]
    tb_lines = tb_lines.concat(window.printStackTrace())
    tb_lines.splice(1, 2) // Remove lines caused by call of printStackTrace()
    tb_lines.push("**********************************")

    text_log = text + "\n" + tb_lines.join("\n")
    text_gui = text + PK.log_system.GUI_EOL + tb_lines.join(PK.log_system.GUI_EOL)
  }
  else
  {
    text_log = text + "\n" + "(Stack trace not available)" + "\n\n"
    text_gui = text // + PK.log_system.GUI_EOL + "(Stack trace not available)"
  }

  LOG("\nCRITICAL ERROR: " + text_log)

  var printer = PK.log_system.get_printer()
  if(printer)
    printer(text_gui)
}
