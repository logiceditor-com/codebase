//------------------------------------------------------------------------------
// sselector: includes proper social net API interface
//------------------------------------------------------------------------------

(function() {
  var query_params = $.parseQuery()

  if (query_params['viewer_id'])
  {
    // internal vkontakte
    $.getScript("http://vkontakte.ru/js/api/xd_connection.js?2")
  }
  else if (query_params['vid'])
  {
    // internal mail.ru
    $.getScript("http://cdn.connect.mail.ru/js/loader.js");
  }
  else if (query_params['logged_user_id'])
  {
    // internal odnoklassniki
    $.getScript(query_params['api_server'] + 'js/fapi.js');
  }
  else
  {
    // no social net detected
    if (!query_params['disable_social_network_detector'])
    {
      $.getScript("http://vkontakte.ru/js/api/openapi.js");
      $.getScript("http://cdn.connect.mail.ru/js/loader.js");
    }
  }
}) ()
