//------------------------------------------------------------------------------
//  Ajax request helper
//------------------------------------------------------------------------------

var AjaxRequestHelper = new function()
{
  var service_urls_ = {};

  var service_name_by_request_name_ =
  {
    'config'                          : 'config',

    'infostats/self/info'             : 'infostats',
    'event/viral/new'                 : 'infostats',
    'event/viral/restrictions'        : 'infostats',

    'ratings'                         : 'ratings',

    'training/status'                 : 'training',
    'training/new'                    : 'training',
    'training/stop'                   : 'training',
    'training/turn'                   : 'training',

    'hiddenobject/buy'                : 'hogame',
    'hiddenobject/start'              : 'hogame',
    'hiddenobject/activate'           : 'hogame',
    'hiddenobject/turn'               : 'hogame',

    'billing/vk'                      : 'billing/vk'
  }

  var request_suffix_by_request_name_ = {
    'config'                          : "/config?",

    'infostats/self/info'             : "/self/info?",
    'event/viral/new'                 : "/event/viral/new",
    'event/viral/restrictions'        : "/event/viral/restrictions",

    'ratings'                         : "/raitings?",

    'training/status'                 : "/training/status?",
    'training/new'                    : "/training/new?",
    'training/stop'                   : "/training/stop?",
    'training/turn'                   : "/training/turn?",

    'hiddenobject/buy'                : "/hiddenobject/buy",
    'hiddenobject/start'              : "/hiddenobject/start",
    'hiddenobject/activate'           : "/hiddenobject/activate",
    'hiddenobject/turn'               : "/hiddenobject/turn",

    'billing/vk'                      : "/create_payment?"
  };

  function prepare_service_url_(url)
  {
    // Can be uncommented for the purpose of test
    //var url = url.replace("http://pk-hb-client-debug/", "/")

    if (typeof(url) === 'string')
    {
      //URL contains prefix like http://{1,2,3,4}.example.com
      var match = url.match(/{(.*?)}/);

      if (match)
      {
        var prefixes = match[1].split(',');
        var prefix = prefixes[PK.Math.random_int(0, prefixes.length)].trim();
        url = url.replace(match[0], prefix);
      }

      return url;
    }
    else if (url.length)
    {
      //Array of urls like ['http://1.example.com', 'http://2.example.com']
      return prepare_service_url_(url[PK.Math.random_int(0, url.length)]);
    }
    else
    {
      throw "URL can be either string or array of strings";
    }
  }

  this.set_config_url = function(config_url)
  {
    service_urls_['config'] = config_url;
  }

  this.set_service_urls = function(service_urls)
  {
    for (var service in service_urls)
    {
      if (service === 'billing')
      {
        var billing_urls = service_urls[service];
        for (var social_net in billing_urls)
        {
          var key = 'billing/' + social_net;
          service_urls_[key] = prepare_service_url_(billing_urls[social_net]);
        }
      }
      else
      {
        service_urls_[service] = prepare_service_url_(service_urls[service]);
      }
    }
  }

  this.formUrl = function (request_name)
  {
    // Note: Net config must be loaded first
    if(request_name == "net_config" || request_name == "social_net_config" || request_name == "hidden_object_config")
      return request_name

    var service_name = assert(
        service_name_by_request_name_[request_name],
        "No service url name for request: " + request_name
      );

    var service_url = service_urls_[service_name]
    assert(
        service_url == "" || service_url,
        "No service url: " + service_name
      );

    var request_suffix = assert(
        request_suffix_by_request_name_[request_name],
        "No request suffinx for request: " + request_name
      );

    //console.log(request_name, service_name, service_url, request_suffix)
    return service_url + request_suffix;
  }
}

PKEngine.check_namespace("Ajax")

PKEngine.Ajax.PRINT_RECEIVED_DATA = false

PKEngine.Ajax.do_request = function(name, type, post_data, event_maker, on_error)
{
  //console.log("Ajax name:", name)
  //console.log(window.printStackTrace().join("\n"))

  on_error = on_error || PKEngine.Ajax.default_error_handler;

  $.ajax(
      AjaxRequestHelper.formUrl(name),
      {
          'type' : type,
          'data' : post_data,
          //'dataType' : "json", // TODO: Hack (non-working, BTW), to be removed
          'success' : function(data_in, textStatus, jqXHR)
          {
            if (PKEngine.Ajax.PRINT_RECEIVED_DATA)
            {
              console.log("[Ajax.do_request]: " + name, PK.clone(data_in), textStatus, jqXHR)
            }

//             assert(
//                 typeof(data_in) == "object",
//                 I18N('Invalid format of server response for request "${1}"', name)
//               )
            // TODO: Hack, to be removed
            var data;
            try
            {
              data = (typeof(data_in) == "string") ? JSON.parse(data_in) : data_in;
            }
            catch (ex)
            {
              PKEngine.ERROR(I18N('Unable to parse server response for request "${1}"', name));
              return;
            }

            if(data)
            {
              if(event_maker)
              {
                PKEngine.EventQueue.push(event_maker(data));
              }
            }
            else
            {
              on_error(name, textStatus, jqXHR);
            }
          },
          'error' : function(jqXHR, textStatus, errorThrown)
          {
            if (
                 textStatus == "timeout"
                 || (jqXHR.readyState == 0 && jqXHR.responseText == "")
                 || jqXHR.status == 500 || jqXHR.status == 502
                 || jqXHR.status == 503 || jqXHR.status == 504
               )
            {
              LOG("ServerConnectionError = " + JSON.stringify(jqXHR));
              PKEngine.GUI.Viewport.show_screen(PKEngine.GUIControls.SCREEN_NAMES.ServerConnectionError);
              return;
            }
            on_error(name, textStatus, jqXHR);
          }
      }
    );
}

PKEngine.Ajax.default_error_handler = function(name, textStatus, jqXHR)
{
  var loc_text_status = I18N("Ajax error NULL")
  switch (textStatus)
  {
    case 'timeout'     : loc_text_status = I18N("Ajax error TIMEOUT"); break;
    case 'error'       : loc_text_status = I18N("Ajax ERROR"); break;
    case 'abort'       : loc_text_status = I18N("Ajax error ABORT"); break;
    case 'parsererror' : loc_text_status = I18N("Ajax error PARSERERROR"); break;
  }

  PKEngine.ERROR(
      I18N("Bad server answer!") + "<br>"
      + I18N("Request URL: ${1}", name) + "<br>"
      + I18N("Text error: ${1}", loc_text_status) + "<br>"
      + I18N("Response status: ${1}", jqXHR.status) + "<br>"
      + I18N("Response text: ${1}", jqXHR.responseText)
    );
};


PKEngine.Ajax.on_soft_error_received = function(name, error)
{
  assert(error)

  var error_text = error.id ? String(error.id) : JSON.stringify(error)

  PKEngine.ERROR(
      I18N("Bad server answer!") + "<br>"
      + I18N("Request URL: ${1}", name) + "<br>"
      + I18N("Text error: ${1}", error_text) + "<br>"
    );
};
