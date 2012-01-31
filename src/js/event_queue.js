//------------------------------------------------------------------------------
// Queue of events which should be run
//------------------------------------------------------------------------------

PKEngine.EventQueue = new function()
{
  var queue_ = []

  this.push = function(event)
  {
    queue_.push(event)
  }

  this.run = function()
  {
    for (var i = 0; i < queue_.length; i++)
      queue_[i].run()
    queue_.length = 0
  }
}
