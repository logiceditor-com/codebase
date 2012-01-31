//------------------------------------------------------------------------------
//  Sound and music
//------------------------------------------------------------------------------

PKHB.SoundSystem = new function()
{
  var state_;

  this.STATE = { DISABLED : 0, ON : 1, OFF : 2 }

  this.IsDisabled = function() { return state_ == this.STATE.DISABLED }
  this.IsOn = function() { return state_ == this.STATE.ON }
  this.IsOff = function() { return state_ == this.STATE.OFF }

  this.Disable = function() { state_ = this.STATE.DISABLED }
  this.SwitchOn = function() { if (!this.IsDisabled()) state_ = this.STATE.ON }
  this.SwitchOff = function() { if (!this.IsDisabled()) state_ = this.STATE.OFF }

  this.ToggleState = function()
  {
    if (!this.IsDisabled())
    {
      if (this.IsOn())
        this.SwitchOff()
      else
        this.SwitchOn()
    }
  }

  // Initialization

  this.SwitchOn()
}

function hbe_returnSoundExtensionByBrowserSupport()
{
  var sound_types =
  [
    { ext: '.mp3', mime: 'audio/mpeg' },
    { ext: '.ogg', mime: 'audio/ogg; codecs=vorbis' }
  ]

  if (!window.Audio)
  {
    PKHB.SoundSystem.Disable();
    return;
  }

  var format = undefined;

  var audio = new Audio();
  for (var i = 0; i < sound_types.length; i++)
  {
    if( audio.canPlayType(sound_types[i].mime) )
    {
      format = sound_types[i].ext
      break;
    }
  }

  if (format == undefined)
  {
    PKHB.ERROR(I18N('Sound format undefined!'));
    PKHB.SoundSystem.Disable();
    return;
  }

  return format
}

function hbe_stopAndPlayAudio(sound, loop)
{
  if (!PKHB.SoundSystem.IsOn())
    return;

  var audio = PKHB.SoundStore.get(sound).handler;

  try
  {

    audio.pause();
    audio.currentTime = 0;

    if(loop)
    {
      if (audio.addEventListener)
      {
        audio.is_looped = true
        audio.addEventListener('ended', function()
            {
              if (this.is_looped)
              {
                this.currentTime = 0;
                this.play();
              }
            },
            false
          );
      }
    }

    audio.play();
  }
  catch(e)
  {
    PKHB.ERROR(I18N('Error pause and play audio: ${1}', audio.src));
  }
}

function hbe_stopAudioExcept(exceptions)
{
  if (!PKHB.SoundSystem.IsOn())
    return;

  var sounds = PKHB.SoundStore.get_all_sounds();

  for(var i = 0; i < sounds.length; i++)
  {
    if (exceptions.indexOf(sounds[i]) < 0) {
      PKHB.SoundStore.get(sounds[i]).handler.pause();
    }
  }
}

function hbe_stopAudio(sound)
{
  if (!PKHB.SoundSystem.IsOn())
    return;

  var audio = PKHB.SoundStore.get(sound).handler;
  if (!PKHB.SoundSystem.IsOn())
    return

  try
  {
    audio.is_looped = false
    audio.pause();
    audio.currentTime = 0;
  }
  catch(e)
  {
    PKHB.ERROR(I18N('Error pause and play audio: ${1}', audio.src));
  }
}
