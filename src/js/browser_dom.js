PK.browser_dom = new function()
{
  var id_prefix = "pk_", id_num = 0;

  this.generated_id = function()
  {
    return id_prefix + (++id_num)
  }

  this.get_object_by_id = function(id)
  {
    if (document.getElementById)
      return document.getElementById(id)
    assert(false, "document.getElementById() not supported!")
    return undefined
  }

  this.get_obj_position = function(obj)
  {
    var topValue = 0, leftValue = 0
    while(obj)
    {
      leftValue += obj.offsetLeft
      topValue += obj.offsetTop
      obj = obj.offsetParent
    }
    return [leftValue,topValue]
  }

  //----------------------------------------------------------------------------

  this.get_mouse_position = function()
  {
    var posx = 0, posy = 0, e = window.event;

    if (e.pageX || e.pageY)
    {
      posx = e.pageX
      posy = e.pageY
    }
    else if (e.clientX || e.clientY)
    {
      posx = e.clientX + document.body.scrollLeft
        + document.documentElement.scrollLeft
      posy = e.clientY + document.body.scrollTop
        + document.documentElement.scrollTop
    }
    return [posx, posy]
  }
}
