//------------------------------------------------------------------------------
// Clip area for canvas 2D context
//------------------------------------------------------------------------------

PKEngine.check_namespace('GUI')

PKEngine.GUI.ClipArea = new function()
{
  var game_field_2d_cntx = PKEngine.GUI.Context_2D.get();
  this.set = function(area)
  {
    if (!area.length)
    {
      area = [ area ]
    }

    game_field_2d_cntx.save();
    game_field_2d_cntx.beginPath();

    for( var i = 0; i < area.length; i++)
    {
      game_field_2d_cntx.rect(
          area[i].left, area[i].top,
          area[i].right - area[i].left, area[i].bottom - area[i].top
        );
    }

    game_field_2d_cntx.clip();
  }

  this.restore = function()
  {
    game_field_2d_cntx.restore();
  }
}
