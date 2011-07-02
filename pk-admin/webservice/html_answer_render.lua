--------------------------------------------------------------------------------
-- html_answer_render.lua: helpers for raw handlers
--------------------------------------------------------------------------------

local arguments,
      optional_arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments',
        'method_arguments'
      }

local make_concatter
      = import 'lua-nucleo/string.lua'
      {
        'make_concatter'
      }

local make_loggers
      = import 'pk-core/log.lua'
      {
        'make_loggers'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers("webservice/html_answer_render", "HAR")

--------------------------------------------------------------------------------

local REGISTRATION_FAILURE =
{
  NO_MANDATORY_FIELD    = 1;
  PASSWORDS_DONT_MATCH  = 2;
  CAPTCHA_CHECK_FAILED  = 3;
  LOGIN_EXISTED         = 4;
  EMAIL_EXISTED         = 5;
  LOGIN_STOPPED         = 6;
  VALIDATE_EMAIL_FAILED = 7;
}

--------------------------------------------------------------------------------

local cat_cookie = function(cat, name, value)
  local date = os.date("!%a, %d-%Y-%b %H:%M:%S GMT", os.time() + 24*60*60)
  --local domain = ""
  --local path = "/"

  cat [[<META HTTP-EQUIV="SET-COOKIE" CONTENT="]] (name) "=" (value)
    ";expires=" (date)
    --";domain=" (domain)
    --";path=" (path)
    --";secure"
    '">'
end

--------------------------------------------------------------------------------

local render_login_answer_ok = function(STATIC_URL, uid, sid, username, profile)
  local cat, concat = make_concatter()

  --TODO: Move to config?
  local JS_URL = STATIC_URL .. "/js"

  cat [[<html><head>]]

  cat [[<script type="text/javascript" src="]] (JS_URL) [[/core/cookies.js"></script>]] "\n"
  cat [[<script type="text/javascript" src="]] (JS_URL) [[/core/notify_user_logged_in.js"></script>]] "\n"

  cat [[<META HTTP-EQUIV="Refresh" CONTENT="0; URL=/">]]

  cat_cookie(cat, "uid", uid)
  cat_cookie(cat, "sid", sid)
  cat_cookie(cat, "username", username)
  cat_cookie(cat, "profile", profile)

  cat [[</head><body onLoad=SetGlobalSessionCookies()></body></html>]]

  return concat()
end

local render_login_answer_unregistered = function(STATIC_URL)
  local cat, concat = make_concatter()

  --TODO: Move to config?
  local JS_URL = STATIC_URL .. "/js"

  cat [[<html><head>]]

  cat [[<script type="text/javascript" src="]] (JS_URL) [[/core/cookies.js"></script>]] "\n"
  cat [[<script type="text/javascript" src="]] (JS_URL) [[/core/notify_user_logged_in.js"></script>]] "\n"

  cat [[<META HTTP-EQUIV="Refresh" CONTENT="0; URL=/">]]

  cat_cookie(cat, "server_answer_error", "unregistered user")

  cat [[</head><body onLoad=SetGlobalSessionCookies()></body></html>]]
  return concat()
end

--------------------------------------------------------------------------------

local render_register_answer_failed = function(STATIC_URL, err_code)
  local cat, concat = make_concatter()

  --TODO: Move to config?
  local JS_URL = STATIC_URL .. "/js"

  cat [[<html><head>]]

  cat [[<script type="text/javascript" src="]] (JS_URL) [[/core/cookies.js"></script>]] "\n"
  cat [[<script type="text/javascript" src="]] (JS_URL) [[/core/notify_user_logged_in.js"></script>]] "\n"

  cat [[<META HTTP-EQUIV="Refresh" CONTENT="0; URL=/">]]

  cat_cookie(cat, "server_answer_error", "registration failed " .. err_code)

  cat [[</head><body onLoad=SetGlobalSessionCookies()></body></html>]]
  return concat()
end

--------------------------------------------------------------------------------

return
{
  REGISTRATION_FAILURE = REGISTRATION_FAILURE;
  render_login_answer_ok = render_login_answer_ok;
  render_login_answer_unregistered = render_login_answer_unregistered;
  render_register_answer_failed = render_register_answer_failed;
}
