//------------------------------------------------------------------------------
// Font
//------------------------------------------------------------------------------

PKEngine.Fonts = new function()
{
  this.measureText = function(font, text)
  {
    var preserved_context_properties = getContextProperties([
        'font', 'shadowColor', 'shadowOffsetX', 'shadowOffsetY', 'shadowBlur', 'fillStyle', 'textAlign'
      ])

    setFontProperties(font);

    var size = game_field_2d_cntx.measureText("" + text).width;

    changeContextProperties(preserved_context_properties)

    return size;
  }
}
