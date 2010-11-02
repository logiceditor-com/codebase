function SetGlobalSessionCookies()
{
  var MINUTES_TILL_EXPIRATION = 10;

  var uid = Get_Cookie("uid"), sid = Get_Cookie("sid"),
    username = Get_Cookie("username"), profile = Get_Cookie("profile");

  Delete_Cookie("uid", "/api/session");
  Delete_Cookie("sid", "/api/session");
  Delete_Cookie("username","/api/session");
  Delete_Cookie("profile", "/api/session");

  if (uid != null)
    Set_Cookie("uid",       uid,      MINUTES_TILL_EXPIRATION * 60, "/");

  if (sid != null)
    Set_Cookie("sid",       sid,      MINUTES_TILL_EXPIRATION * 60, "/");

  if (username != null)
    Set_Cookie("username",  username, MINUTES_TILL_EXPIRATION * 60, "/");

  if (profile != null)
    Set_Cookie("profile",   profile,  MINUTES_TILL_EXPIRATION * 60, "/");
}
