PK.common_stores = new function()
{
//------------------------------------------------------------------------------

  this.make_reader_fields = function(field_names)
  {
    var reader_fields = new Array;
    for(var i = 0; i < field_names.length; i++)
      reader_fields[reader_fields.length] = {name : field_names[i]};
    return reader_fields;
  };

//------------------------------------------------------------------------------

  this.make_store_with_custom_fields = function(
      fields, primary_key, request_url, request_params, autoLoad, on_no_items
    )
  {
    var reader = new Ext.data.JsonReader({
        root: 'result.item',
        totalProperty: 'result.total',
        //groupField: 'size',
        //sortInfo: {field: 'name', direction: 'ASC'},
        //remoteSort: true,
        id: primary_key,
        fields: fields
      });

    var proxy = new Ext.data.HttpProxy({
        url: PK.make_admin_request_url(request_url),
        method: 'POST'
      });

    if(on_no_items)
      proxy.on('exception', PK.make_common_proxy_request_error_handler(on_no_items));
    else
      proxy.on('exception', PK.common_proxy_request_error_handler);

    var baseParams;
    if(request_params)
      baseParams = request_params;
    else
      baseParams = {};

    var store = new Ext.data.Store(
    {
      autoLoad: autoLoad,
      proxy: proxy,
      baseParams: PK.make_admin_request_params(baseParams),
      reader: reader,
      sortInfo: { field: primary_key, direction: "ASC" }
    });

    store.on(
      'exception',
      function(proxy, type, action, response, arg)
      {
        if(type == 'response' && arg.status === 200)
        {
          var json = Ext.decode(arg.responseText);
          if(json && !json.error && json.result && json.result.total == 0)
            store.removeAll(false);
        }
      }
    );

   return store;
  }

//------------------------------------------------------------------------------

  this.make_common_store = function(
      field_names, primary_key, request_url, request_params, autoLoad
    )
  {
    return this.make_store_with_custom_fields(
        this.make_reader_fields(field_names),
        primary_key,
        request_url,
        request_params,
        autoLoad
      );
  }

//------------------------------------------------------------------------------

  this.load_store = function(store_name, max_elements)
  {
    if(this[store_name])
      this[store_name].load({ params: {start: 0, limit: max_elements} });
  }

};
