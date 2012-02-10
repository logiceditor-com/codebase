//------------------------------------------------------------------------------
// Loading of resources: check, draw
//------------------------------------------------------------------------------

/**
 * Loader
 */
PKEngine.Loader = new function ()
{
  this.loader_back_img = undefined;
  this.loader_line_img = undefined;
  this.preloader_resource_count = 0;

  /**
   * Callback
   */
  this.custom_main_loop_actions = undefined;

  /**
   * Callback
   */
  this.on_preloader_initialized = undefined;

  /**
   * Callback
   */
  this.on_resource_loading_complete = undefined;

  this.img_path = '';
  this.lang = undefined;

  this.last_loading_progress = 0;
  this.resources_loaded = false;

  /**
  * Dom ids
  */
  this.loader_id = 'div_loader';
  this.resources_id = 'resources';
}

/**
 * Set loader params
 *
 * @param params (Object)
 */
PKEngine.Loader.set_params = function (params)
{
  if (params.custom_main_loop_actions)
  {
    this.custom_main_loop_actions = params.custom_main_loop_actions;
  }
  if (params.on_preloader_initialized)
  {
    this.on_preloader_initialized = params.on_preloader_initialized;
  }
  if (params.on_resource_loading_complete)
  {
    this.on_resource_loading_complete = params.on_resource_loading_complete;
  }
  if (params.img_path)
  {
    this.img_path = params.img_path;
  }
  if (params.lang)
  {
    this.lang = params.lang;
  }
  if (params.loader_id)
  {
    this.loader_id = params.loader_id;
  }
  if (params.resources_id)
  {
    this.resources_id = params.resources_id;
  }
}

/**
 * Initialize loader with params
 *
 * @param params (Object)
 *  - custom_main_loop_actions
 *  - on_preloader_initialized
 *  - on_resource_loading_complete
 *  - img_path
 *  - lang
 *  - loader_id
 *  - resources_id
 */
PKEngine.Loader.init = function (params)
{
  PKEngine.Loader.set_params(params);

  $('<div id="'+PKEngine.Loader.resources_id+'" style="position: absolute; left: 10000px">')
      .appendTo($('#' + PKEngine.Loader.loader_id));

  PKEngine.Loader.loader_back_img = $('<img>',
      {
        id: 'preloader_background',
        src: PKEngine.Loader.img_path + "loader/preloader_" + PKEngine.Loader.lang + ".jpg"
      }
    ).load(PKEngine.Loader.check_preloader_ready)
    .error(
        function ()
        {
          PKEngine.ERROR(I18N('Cant load loader background!'));
        }
    )
    .appendTo($('#' + PKEngine.Loader.loader_id))[0];

  PKEngine.Loader.loader_line_img = $('<img>',
      {
        id: 'preloader_progressbar',
        src: PKEngine.Loader.img_path + "loader/loader_line.png"
      }
    ).load(PKEngine.Loader.check_preloader_ready)
    .error(
        function ()
        {
          PKEngine.ERROR(I18N('Cant load loader progress bar!'));
        }
    )
    .appendTo($('#' + PKEngine.Loader.resources_id))[0];

  $('<img/>', { src: PKEngine.Loader.img_path + "spacer_top.png", id: "spacer_top" })
    .load(PKEngine.Loader.check_preloader_ready)
    .appendTo($('#' + PKEngine.Loader.resources_id));
  $('<img/>', { src: PKEngine.Loader.img_path + "spacer_bottom.png", id: "spacer_bottom" })
    .load(PKEngine.Loader.check_preloader_ready)
    .appendTo($('#' + PKEngine.Loader.resources_id));
  $('<img/>', { src: PKEngine.Loader.img_path + "error/" + PKEngine.Loader.lang + "/label_error.png", id: "error_label" })
    .load(PKEngine.Loader.check_preloader_ready)
    .appendTo($('#' + PKEngine.Loader.resources_id));
  $('<img/>', { src: PKEngine.Loader.img_path + "buttons/" + PKEngine.Loader.lang + "/btn_close.png", id: "close_button" })
    .load(PKEngine.Loader.check_preloader_ready)
    .appendTo($('#' + PKEngine.Loader.resources_id));
  $('<img/>', { src: PKEngine.Loader.img_path + "error/bg_window.jpg", id: "error_window_bg" })
    .load(PKEngine.Loader.check_preloader_ready)
    .appendTo($('#' + PKEngine.Loader.resources_id));
}

/**
 * Check if preloader ready
 */
PKEngine.Loader.check_preloader_ready = function ()
{
  PKEngine.Loader.preloader_resource_count += 1;

  if (PKEngine.Loader.preloader_resource_count > $('#' + PKEngine.Loader.resources_id + ' img').length)
  {
    if (PKEngine.Loader.on_preloader_initialized)
    {
      PKEngine.Loader.on_preloader_initialized();
    }
  }
}

/**
 * Switch to canvas, show game field
 */
PKEngine.Loader.switch_to_canvas = function ()
{
  // Hide temporary div to prevent influence on layout
  $('#' + PKEngine.Loader.loader_id).hide();
  var game_field_2d_cntx = PKEngine.GUI.Context_2D.get();
  game_field_2d_cntx.drawImage(PKEngine.Loader.loader_back_img, 0, 0);
  PKEngine.Loader.loader_back_img.is_drawn = true;
  PKEngine.GUI.Viewport.show_game_field();
}

/**
 * Check loaded data
 */
PKEngine.Loader.check_loaded_data = function ()
{
  if (PKEngine.Loader.resources_loaded) return;

  if (!PKEngine.Loader.loader_back_img.is_drawn)
  {
    PKEngine.Loader.switch_to_canvas();
  }

  // graphics

  var loading_progress = PKEngine.GraphicsStore.count_loaded();
  var all_resources = PKEngine.GraphicsStore.count_total();

  // audio

  if (!PKEngine.SoundSystem.IsDisabled())
  {
    loading_progress += PKEngine.SoundStore.count_loaded();
    all_resources += PKEngine.SoundStore.count_total();
  }

  if(loading_progress > PKEngine.Loader.last_loading_progress)
  {
    PKEngine.Loader.last_loading_progress = loading_progress;

    var pb_width = Math.ceil(PKEngine.Loader.loader_line_img.width * loading_progress / all_resources);
    if (pb_width > PKEngine.Loader.loader_line_img.width)
    {
      pb_width = PKEngine.Loader.loader_line_img.width;
    }
    PKEngine.reset_shadow();
    var game_field_2d_cntx = PKEngine.GUI.Context_2D.get();
    game_field_2d_cntx.drawImage(
      PKEngine.Loader.loader_line_img,
      0, 0,
      pb_width, PKEngine.Loader.loader_line_img.height,
      PKEngine.GUIControls.get_loader_parameters().line_coords.x,
      PKEngine.GUIControls.get_loader_parameters().line_coords.y,
      pb_width, PKEngine.Loader.loader_line_img.height
    );
  }

  if (loading_progress >= all_resources)
  {
    PKEngine.Loader.resources_loaded = true;
    PKEngine.GameEngine.MainLoop.start(1000, PKEngine.Loader.custom_main_loop_actions);
    if (PKEngine.Loader.on_resource_loading_complete)
    {
      PKEngine.Loader.on_resource_loading_complete();
    }
    return;
  }

  setTimeout(PKEngine.Loader.check_loaded_data, 1000 / MAXIMUM_FPS);
}

/**
 * Returns if resources are loaded
 */
PKEngine.Loader.resources_are_loaded = function ()
{
  return PKEngine.Loader.resources_loaded;
}
