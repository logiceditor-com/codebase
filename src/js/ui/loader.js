//------------------------------------------------------------------------------
// Loading of resources: check, draw
//------------------------------------------------------------------------------

// TODO: #3416 Must use a parameter for Loader.init() instead of this
PKEngine.CustomMainLoopActions = false

// TODO: #3416 Make a singleton, remove all global variables

var Loader_back_img
var Loader_line_img
var preloader_initialized_callback;
var preloader_resource_count = 0;

//------------------------------------------------------------------------------

// TODO: #3416 Many hardcoded names, think about moving them to loader's config
var InitLoader = function(img_path, lang, onload)
{
  $('<div id="resources" style="position: absolute; left: 10000px">')
      .appendTo($('#div_loader'));

  preloader_initialized_callback = onload;

  Loader_back_img = $('<img>',
      {
        id: 'preloader_background',
        src: img_path + "loader/preloader_" + lang + ".jpg"
      }
    ).load(check_preloader_ready)
    .error(
        function ()
        {
          CRITICAL_ERROR(I18N('Cant load loader background!'));
        }
    )
    .appendTo($('#div_loader'))[0];

  Loader_line_img = $('<img>',
      {
        id: 'preloader_progressbar',
        src: img_path + "loader/loader_line.png"
      }
    ).load(check_preloader_ready)
    .error(
        function ()
        {
          CRITICAL_ERROR(I18N('Cant load loader progress bar!'));
        }
    )
    .appendTo($('#resources'))[0];

  $('<img/>', { src: img_path + "spacer_top.png", id: "spacer_top" })
    .load(check_preloader_ready)
    .appendTo($('#resources'));
  $('<img/>', { src: img_path + "spacer_bottom.png", id: "spacer_bottom" })
    .load(check_preloader_ready)
    .appendTo($('#resources'));
  $('<img/>', { src: img_path + "error/" + lang + "/label_error.png", id: "error_label" })
    .load(check_preloader_ready)
    .appendTo($('#resources'));
  $('<img/>', { src: img_path + "buttons/" + lang + "/btn_close.png", id: "close_button" })
    .load(check_preloader_ready)
    .appendTo($('#resources'));
  $('<img/>', { src: img_path + "error/bg_window.jpg", id: "error_window_bg" })
    .load(check_preloader_ready)
    .appendTo($('#resources'));
}

//------------------------------------------------------------------------------

// TODO: #3416 Hardcoded name
var check_preloader_ready = function()
{
  preloader_resource_count += 1;

  if (preloader_resource_count > $('#resources img').length)
  {
    preloader_initialized_callback();
  }
}

//------------------------------------------------------------------------------

var switch_to_canvas = function()
{
  // Hide temporary div to prevent influence on layout
  // TODO: #3416 Hardcoded name
  $('#div_loader').hide();
  var game_field_2d_cntx = PKEngine.GUI.Context_2D.get();
  game_field_2d_cntx.drawImage(Loader_back_img, 0, 0);
  Loader_back_img.is_drawn = true;
  PKEngine.GUI.Viewport.show_game_field();
}

//------------------------------------------------------------------------------

var g_last_loading_progress = 0
var g_resources_loaded = false

function checkLoadedData()
{
  if (g_resources_loaded)
    return

  if (!Loader_back_img.is_drawn)
  {
    switch_to_canvas();
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

  if(loading_progress > g_last_loading_progress)
  {
    g_last_loading_progress = loading_progress

    var pb_width = Math.ceil(Loader_line_img.width * loading_progress / all_resources);
    if(pb_width > Loader_line_img.width){
      pb_width = Loader_line_img.width;
    }
    PKEngine.reset_shadow();
    var game_field_2d_cntx = PKEngine.GUI.Context_2D.get();
    game_field_2d_cntx.drawImage(
      Loader_line_img,
      0, 0,
      pb_width, Loader_line_img.height,
      PKEngine.GUIControls.get_loader_parameters().line_coords.x,
      PKEngine.GUIControls.get_loader_parameters().line_coords.y,
      pb_width, Loader_line_img.height
    );
  }

  if (loading_progress >= all_resources)
  {
    g_resources_loaded = true;
    // TODO: #3416 It seems custom_main_loop_actions must be a parameter for Loader.init()
    PKEngine.GameEngine.MainLoop.start(1000, PKEngine.CustomMainLoopActions);
    onResourceLoadingComplete()
    return;
  }

  setTimeout(checkLoadedData, 1000 / PKEngine.Const.MAXIMUM_FPS);
}


function ResourcesAreLoaded()
{
  return g_resources_loaded
}

//------------------------------------------------------------------------------

// TODO: #3416 Seems it should be a callback provided by user code
var onResourceLoadingComplete = function()
{
  PKEngine.iPadAdd2Home.show();
}
