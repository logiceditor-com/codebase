//------------------------------------------------------------------------------
// log_system.js: Simple logging / error output system
// This file is a part of pk-core-js library
// Copyright (c) Alexander Gladysh <ag@logiceditor.com>
// Copyright (c) Dmitry Potapov <dp@logiceditor.com>
// See file `COPYRIGHT` for the license
//------------------------------------------------------------------------------

PK.log_system = new function()
{
  var default_gui_msg_printer_ = function(text, stack_trace)
  {
    text += "\n" + PK.Error.format_stack_trace(stack_trace);
    if (window.Ext)
    {
      if (Ext.isReady)
      {
        Ext.Msg.alert('Failure', text);
      }
    }
    else
    {
      alert(text);
    }
  }

  // ------------------ private --------------------------

  var events_ = new Array();

  var printer_ = default_gui_msg_printer_;

  // ------------------ public --------------------------

  this.GUI_EOL = "<br>"

  this.set_printer = function(printer)
  {
    printer_ = printer;
  }

  this.get_printer = function()
  {
    return printer_;
  }

  this.add = function(event)
  {
    events_[events_.length] = event;
  }

  this.list = function()
  {
    return events_;
  }
}

var LOG = PK.log_system.add

var GUI_ERROR = function(text)
{
  if (window.Ext)
  {
    if (Ext.isReady)
    {
      Ext.Msg.alert('Failure', text);
    }
    else
    {
      LOG('GUI ERROR: ' + text);
    }
  }
  else
  {
    var printer = PK.log_system.get_printer();
    if (printer) printer(text);
  }
}

/**
* Exception for critical errors.
*
* @param text
*/
PK.CriticalError = function (text)
{
  this.name = 'CRITICAL ERROR';
  this.message = text;
}
PK.CriticalError.prototype = Error.prototype;

/**
 * Error handler
 */
PK.Error = new function ()
{
  var instance_ = this;

  /**
   * Callback
   */
  var custom_error_handler_ = undefined;

  /**
   * Callback
   */
  var custom_error_text_wrapper_ = false;

  var log_error_ = function (error)
  {
    LOG(error.message);
    var printer = PK.log_system.get_printer();
    if (printer)
    {
      printer(error.message, error.stack_trace.slice());
    }
  }

  var format_date_time_ = function ()
  {
    var now = new Date(PK.Time.get_current_timestamp());
    var cur_date = now.getDate() + '-' + (now.getMonth() + 1) + '-' + now.getFullYear();
    return '[' + cur_date + ' ' + now.toLocaleTimeString() + '] ';
  }

  /**
   * Prevents recursive calling of critical_error
   */
  var critical_error_raised_ = false;

  this.critical_error = function (text)
  {
    if (critical_error_raised_)
    {
      LOG("\nCRITICAL ERROR: " + text);
      return;
    }
    critical_error_raised_ = true;

    throw new PK.CriticalError(text);
  }

  this.handle_error = function (callback, name)
  {
    try
    {
      callback();
    }
    catch (error)
    {
      error.stack_trace = PK.Error.get_stack_trace(error);

      if (custom_error_text_wrapper_)
      {
        error.message = custom_error_text_wrapper_(error.message);
      }
      error.message = format_date_time_() + "\n" + error.message;

      if (name)
      {
        error.message = "[" + name + "] " + error.message;
      }

      log_error_(error);

      if (custom_error_handler_)
      {
        custom_error_handler_(error);
      }
      else
      {
        throw error;
      }
    }
  }

  this.on_unhandled_error = function (message, file, line)
  {
    message = message + " in file '" + file + "' at line " + line;

    if (custom_error_handler_)
    {
      if (custom_error_text_wrapper_)
      {
        message = custom_error_text_wrapper_(message);
      }

      var error = new Error;
      error.message = format_date_time_() + "\n" + message;
      error.stack_trace = instance_.get_stack_trace();

      log_error_(error);

      custom_error_handler_(error);
      return true;
    }
    else
    {
      return false;
    }
  }

  /**
   * Set function to error handling process
   * callback = function (error) { ... }
   */
  this.set_custom_error_handler = function (callback)
  {
    custom_error_handler_= callback;
  }

  /**
   * Set function to add custom text to error message
   * callback = function (text) { ... return text }
   */
  this.set_custom_error_text_wrapper = function (callback)
  {
    custom_error_text_wrapper_= callback;
  }

  /**
   * Returns stack trace if printStackTrace function available
   *
   * @param error Error object
   */
  this.get_stack_trace = function (error)
  {
    if (window.printStackTrace)
    {
      var stack_lines = error ? window.printStackTrace(error) : window.printStackTrace();
      stack_lines.splice(0, 5); // Remove lines caused by call of printStackTrace(), get_stack_trace()
      return stack_lines;
    }
    else
    {
      return undefined;
    }
  }

  /**
   * Default stack trace format
   * @param stack_trace
   */
  this.format_stack_trace = function (stack_trace)
  {
    if (stack_trace)
    {
      var trace = stack_trace.slice();
      trace.unshift("********** Stack Trace **********");
      trace.push("**********************************");
      return trace.join("\n");
    }
    else
    {
      return "(Stack trace not available)\n";
    }
  }
}

var CRITICAL_ERROR = PK.Error.critical_error;
var handle_err = PK.Error.handle_error;

window.onerror = PK.Error.on_unhandled_error;
