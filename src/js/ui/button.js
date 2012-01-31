//------------------------------------------------------------------------------
// Button
//------------------------------------------------------------------------------

PKEngine.Button = PKEngine.Control.extend(
{
  pressed_: false,

  //----------------------------------------------------------------------------

  states: {},
  state: 'off',

  init: function(x, y, states)
  {
    this.x = x;
    this.y = y;
    this.states = states;
  },

  get_width: function()
  {
    var image = this.states[this.state];

    return image.width;
  },

  get_height: function()
  {
    var image = this.states[this.state];

    return image.height;
  },

  set_states: function(states)
  {
    this.states = states;
  },

  set_state: function(state)
  {
    if (this.state === state)
      return
    this.state = state;

    PKEngine.GUI.Viewport.request_redraw();
  },

  get_state: function()
  {
    return this.state;
  },

  on_mouse_down: function(x, y)
  {
    if (!this.is_on_control_(x, y))
    {
      if (this.pressed_)
      {
        this.pressed_ = true;
        PKEngine.GUI.Viewport.request_redraw();
      }
      return false;
    }

    this.pressed_ = true;
    PKEngine.GUI.Viewport.request_redraw();

    hbe_stopAndPlayAudio('Button');

    return true;
  },

  on_click: function(x, y)
  {
    var is_on_me = this.is_on_control_(x, y);

    // Don't react if was not pressed before
    if (!this.pressed_)
      return false;

    this.pressed_ = false;
    PKEngine.GUI.Viewport.request_redraw();

    return is_on_me;
  },

  draw: function()
  {
    PKEngine.GUI.Viewport.notify_control_draw_start();

    if (!this.visible)
    {
      return;
    }

    var image = this.states[this.state];

    if (this.pressed_ && this.states['pressed'])
      image = this.states['pressed'];

    if (!image.complete)
    {
      // Cannot draw image until it was loaded
      return;
    }

    DrawImage(image, this.x, this.y, this.anchor_x,  this.anchor_y);
  },

  is_on_control_: function(x, y)
  {
    // FIXME Move method to Control
    if (!this.enabled || !this.visible)
    {
      return false;
    }

    var image = this.states[this.state];

    var tl_corner = PKEngine.Anchoring.calc_tl_corner(
      this.x, this.y,
      this.anchor_x, this.anchor_y,
      image.width, image.height
    );

    return (
      x >= tl_corner.x && x <= tl_corner.x + image.width &&
      y >= tl_corner.y && y <= tl_corner.y + image.height
    )
  }
})
