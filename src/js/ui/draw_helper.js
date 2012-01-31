//------------------------------------------------------------------------------
//  Functions useful for drawing on canvas
//------------------------------------------------------------------------------

var getContextProperties = function(properties)
{
  if (!properties || !properties.length)
    return

  var old_values = {}

  for(var i = 0; i < properties.length; i++)
    old_values[properties[i]] = game_field_2d_cntx[properties[i]]

  return old_values
}

//------------------------------------------------------------------------------

var changeContextProperties = function(properties)
{
  var old_values = {}

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

  if (!PKHB.SoundSystem.IsDisabled())
  {
    if (PKHB.SoundSystem.IsOn())
    {
      PKHB.SoundSystem.SwitchOff();

      hbe_stopAudioExcept(['Button']);
    }
    else
    {
      PKHB.SoundSystem.SwitchOn();
      audio_btn_state = 'on';
      hbe_stopAndPlayAudio('Button');
      if(PKHB.GUI.Viewport.get_current_screen() == PKHB.GUIControls.SCREEN_NAMES.GameScreen)
        hbe_stopAndPlayAudio('Music', true);
    }
  }

  return audio_btn_state
}

//------------------------------------------------------------------------------

function hbe_resetShadow()
{
  game_field_2d_cntx.strokeStyle = 'rgba(0,0,0,0)';
  game_field_2d_cntx.shadowColor = 'rgba(0,0,0,0)';
  game_field_2d_cntx.shadowOffsetX = 0;
  game_field_2d_cntx.shadowOffsetY = 0;
  game_field_2d_cntx.shadowBlur = 0;
}
