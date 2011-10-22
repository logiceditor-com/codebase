PK.i18n = new function()
{
  var language_packs_ = new Object
  var current_language_ = undefined

  //enum to use more strict typization after adding all languages
  this.language = new Object

  //----------------------------------------------------------------------------

  this.set_current_language = function(lang)
  {
    current_language_ = lang
  }

  this.get_current_language = function()
  {
    return current_language_
  }

  //----------------------------------------------------------------------------

  this.add_language_pack = function(lang, pack)
  {
    if (current_language_ === undefined)
    {
      this.set_current_language(lang)
    }

    language_packs_[lang] = pack
    this.language[lang] = lang
  }

  //----------------------------------------------------------------------------

  this.extend_language_pack = function(lang, pack)
  {
    if (language_packs_[lang] == undefined)
    {
      this.add_language_pack(lang, pack)
      return
    }

    for(var k in pack)
    {
      language_packs_[lang][k] = pack[k]
    }
  }

  //----------------------------------------------------------------------------

  this.text = function(s, return_false_if_not_found)
  {
    var loc_text = ""

    if (current_language_ === undefined)
    {
      CRITICAL_ERROR("Current language not set! Text: " + s)
      loc_text = '<' + s + '>';
    }
    else if (!language_packs_[current_language_])
    {
      CRITICAL_ERROR("No language pack for " + current_language_ + ". Text: " + s)
      loc_text = '<' + s + '>';
    }
    else
    {
      loc_text = language_packs_[current_language_][s];
    }

    if(loc_text === undefined)
    {
      if (return_false_if_not_found)
        return false
      //LOGG("'" + s + "' : '',");
      return '*' + s + '*';
    }

    // TODO: Not a very good idea to replace arguments[0]
    arguments[0] = loc_text
    loc_text = PK.formatString(arguments)

    return loc_text
  }
}

var I18N = PK.i18n.text
