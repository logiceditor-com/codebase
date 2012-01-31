//------------------------------------------------------------------------------
//  Functions useful for drawing on canvas
//------------------------------------------------------------------------------

var getContextProperties = function(properties)
{
  if (!properties || !properties.length)
    return

  var old_values = {};
  var game_field_2d_cntx = PKEngine.GUI.Context_2D.get();

  for(var i = 0; i < properties.length; i++)
    old_values[properties[i]] = game_field_2d_cntx[properties[i]]

  return old_values
}

//------------------------------------------------------------------------------

var changeContextProperties = function(properties)
{
  var old_values = {};
  var game_field_2d_cntx = PKEngine.GUI.Context_2D.get();

  for(var name in properties)
  {
    old_values[name] = game_field_2d_cntx[name]
    game_field_2d_cntx[name] = properties[name]
  }

  return old_values
}

//------------------------------------------------------------------------------

// TODO: Move out to separate file?
var ToggleSound = function()
{
  var audio_btn_state = 'off';

  if (!PKEngine.SoundSystem.IsDisabled())
  {
    if (PKEngine.SoundSystem.IsOn())
    {
      PKEngine.SoundSystem.SwitchOff();

      PKEngine.SoundSystem.stop_except(['Button']);
    }
    else
    {
      PKEngine.SoundSystem.SwitchOn();
      audio_btn_state = 'on';
      PKEngine.SoundSystem.stop_and_play('Button');
      if(PKEngine.GUI.Viewport.get_current_screen() == PKEngine.GUIControls.SCREEN_NAMES.GameScreen)
        PKEngine.SoundSystem.stop_and_play('Music', true);
    }
  }

  return audio_btn_state
}

//------------------------------------------------------------------------------

PKEngine.reset_shadow = function()
{
  var game_field_2d_cntx = PKEngine.GUI.Context_2D.get();
  game_field_2d_cntx.strokeStyle = 'rgba(0,0,0,0)';
  game_field_2d_cntx.shadowColor = 'rgba(0,0,0,0)';
  game_field_2d_cntx.shadowOffsetX = 0;
  game_field_2d_cntx.shadowOffsetY = 0;
  game_field_2d_cntx.shadowBlur = 0;
}
