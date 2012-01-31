PKHB.Control = Class.extend(
{
  x: 0,
  y: 0,
  anchor_x: 0,
  anchor_y: 0,
  enabled: true,
  visible: true,

  init: function(x, y, origin)
  {
    this.x = x || 0;
    this.y = y || 0;
    this.set_origin(origin);
  },

  enable: function()
  {
    if(this.enabled)
      return;

    this.enabled = true;
    PKHB.GUI.Viewport.request_redraw();
  },

  disable: function()
  {
    if(!this.enabled)
      return;

    this.enabled = false;
    PKHB.GUI.Viewport.request_redraw();
  },

  set_anchor: function(anchor_x, anchor_y)
  {
    this.anchor_x = anchor_x || 0;
    this.anchor_y = anchor_y || 0;
  },

  get_anchor: function()
  {
    return [this.anchor_x, this.anchor_y];
  },

  on_mouse_down: function()
  {
  },

  on_click: function()
  {
  },

  on_mouse_move: function()
  {
  },

  is_visible: function()
  {
    return this.visible;
  },

  set_visible: function(visible)
  {
    this.visible = visible;
  },

  move: function(x, y)
  {
    this.x = x;
    this.y = y;
  },

  show: function()
  {
    if(this.visible)
      return;

    this.visible = true;
    PKHB.GUI.Viewport.request_redraw();
  },

  hide: function()
  {
    if(!this.visible)
      return;

    this.visible = false;
    PKHB.GUI.Viewport.request_redraw();
  },

  draw: function()
  {
  }
})
