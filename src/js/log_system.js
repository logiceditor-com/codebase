PK.log_system = new function()
{
  var events = new Array()

  // TODO: Can be uncommented - only for debug!
  //this.events = events

  this.add = function(event)
  {
    events[events.length] = event
  };

  this.list = function()
  {
    return events
  }
}

//var LOG = function(event) {}
var LOG = PK.log_system.add

var GUI_ERROR = function(text)
{
  if (Ext.isReady)
    Ext.Msg.alert('Failure', text)
  else
    LOG('GUI ERROR: ' + text)
}

var CRITICAL_ERROR = function(text)
{
  var text_gui, text_log

  if (window.printStackTrace)
  {
    var tb_lines = ["********** Stack Trace **********"]
    tb_lines = tb_lines.concat(window.printStackTrace())
    tb_lines.splice(1, 2) // Remove lines caused by call of printStackTrace()
    tb_lines.push("**********************************")

    text_log = text + "\n" + tb_lines.join("\n")
    text_gui = text + "<br>" + tb_lines.join("<br>")
  }
  else
  {
    text_log = text + "\n" + "(Stack trace not available)" + "\n\n"
    text_gui = text + "<br>" + "(Stack trace not available)"
  }

  LOG("\nCRITICAL ERROR: " + text_log)

  if (Ext.isReady)
    Ext.Msg.alert('Failure', text_gui)
}
