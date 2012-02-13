//-----------------------------------------------------------------------------
// error_window.js: Slightly customized error window (not a member of our control hierarchy)
//-----------------------------------------------------------------------------

PKEngine.initialize_error_window = function ()
{
  if (PK.check_is_image_loaded($('#error_window_bg')[0]) &&
    PK.check_is_image_loaded($('#error_label')[0]) &&
    PK.check_is_image_loaded($('#spacer_top')[0]) &&
    PK.check_is_image_loaded($('#spacer_bottom')[0]) &&
    PK.check_is_image_loaded($('#close_button')[0]))
  {
    $('.errorWindowInner').show();
  }
}
