//------------------------------------------------------------------------------
// Image
//------------------------------------------------------------------------------

PKEngine.Image = PKEngine.Control.extend(
{
  image: undefined,

  init: function(x, y, image)
  {
    this.x = x;
    this.y = y;
    //Note image resource can be loaded later
    this.image = image;
  },

  set_image: function(image)
  {
    assert(!image || typeof image == 'object', I18N("[PKEngine.Image.set_image]: Invalid type of given image!"))
    this.image = image;
  },

  draw: function()
  {
    PKEngine.GUI.Viewport.notify_control_draw_start()

    if (!this.visible || !this.image)
    {
      return;
    }

    DrawImage(this.image, this.x, this.y, this.anchor_x, this.anchor_y);
  }
})


//------------------------------------------------------------------------------


var DrawImage = function(image, x, y, anchor_x, anchor_y, transparency, clip_area, rotation_in_rad)
{
  if (transparency === undefined) transparency = 1

  if (!image)
  {
    PKEngine.ERROR(I18N('Tried to draw non-existing image!'))
    return
  }

  var tl_corner = PKEngine.Anchoring.calc_tl_corner(x, y, anchor_x, anchor_y, image.width, image.height)


  var preserved_properties = changeContextProperties({ globalAlpha: transparency })

  if (clip_area)
  {
    PKEngine.GUI.ClipArea.set(clip_area)
  }

  if (rotation_in_rad)
  {
    game_field_2d_cntx.save()
    game_field_2d_cntx.translate(tl_corner.x + image.width/2, tl_corner.y + image.height/2);
    game_field_2d_cntx.rotate(rotation_in_rad);

    tl_corner = { x: (-image.width/2), y: (-image.height/2)}
  }

  game_field_2d_cntx.drawImage(image, tl_corner.x, tl_corner.y);

  if (rotation_in_rad)
  {
    game_field_2d_cntx.restore()
  }

  if (clip_area)
  {
    PKEngine.GUI.ClipArea.restore()
  }

  changeContextProperties(preserved_properties)
}
