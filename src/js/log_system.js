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

/**
 * Error handler
 */
PK.Error = new function ()
{
  var custom_error_handler_ = undefined;

  this.critical_error = function (text)
  {
    var text_gui, text_log;

    if (custom_error_handler_)
    {
      text = custom_error_handler_(text);
    }

    var now = new Date(PK.Time.get_current_timestamp());
    var cur_date = now.getDate() + '-' + (now.getMonth() + 1) + '-' + now.getFullYear();
    var date = '[' + cur_date + ' ' + now.toLocaleTimeString() + ']';

    text = date + '<br>' + text;

    if (window.printStackTrace)
    {
      var tb_lines = ["********** Stack Trace **********"];
      tb_lines = tb_lines.concat(window.printStackTrace());
      tb_lines.splice(1, 2); // Remove lines caused by call of printStackTrace()
      tb_lines.push("**********************************");

      text_log = text + "\n" + tb_lines.join("\n");
      text_gui = text + PK.log_system.GUI_EOL + tb_lines.join(PK.log_system.GUI_EOL);
    }
    else
    {
      text_log = text + "\n" + "(Stack trace not available)" + "\n\n";
      text_gui = text; // + PK.log_system.GUI_EOL + "(Stack trace not available)"
    }

    LOG("\nCRITICAL ERROR: " + text_log);

    var printer = PK.log_system.get_printer();
    if (printer)
    {
      printer(text_gui);
    }
  }

  /**
   * Set function to critical error handling process
   * callback = function (text) { ... return text }
   */
  this.set_custom_error_handler = function (callback)
  {
    custom_error_handler_= callback;
  }
}

var CRITICAL_ERROR = PK.Error.critical_error;
