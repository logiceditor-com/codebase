//------------------------------------------------------------------------------
// Calculation of anchoring
//------------------------------------------------------------------------------

PKEngine.Anchoring = new function()
{
  this.calc_tl_corner = function(x, y, anchor_x, anchor_y, width, height)
  {
    if(x === undefined || x == "center")
    {
      // TODO: Note: behaviour differs from what we have for labels
      x = PKEngine.GUIControls.get_center().x - width / 2
    }
    else if (anchor_x == 'center')
    {
      x -= width / 2
    }
    else if (anchor_x == 'right')
    {
      x -= width
    }


    if(y === undefined || y == "center")
    {
      // TODO: Note: behaviour differs from what we have for labels
      y = PKEngine.GUIControls.get_center().y - height / 2
    }
    else if (anchor_y == 'center')
    {
      y -= height / 2
    }
    else if (anchor_y == 'bottom')
    {
      y -= height
    }

    return { x: x, y: y }
  }
}
