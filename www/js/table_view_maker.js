// Parameters:
//   title
//   tbar
//   height
//   width
//   per_page
//   displayMsg
//   emptyMsg
//   render_to
//   columns
//   filters
//   store
PK.make_grid_panel = function(params)
{
  var plugins
  if(params.filters)
    plugins = [params.filters];

  var panel = new Ext.grid.GridPanel({
    renderTo: params.render_to,
    //frame: false,
    //hidden: true,
    store: params.store,
    colModel: new Ext.grid.ColumnModel({
      defaults: {sortable: true},
      columns: params.columns
    }),
    loadMask: true,
    plugins: plugins,
    stripeRows: true,
    //autoExpandColumn: params.autoExpandColumn,
    height: params.height,
    width: params.width,
    title: params.title,
    iconCls: 'icon-grid',
    sm: new Ext.grid.RowSelectionModel({singleSelect:true}),
    viewConfig : {
      columnsText:  I18N('Columns'),
      sortAscText:  I18N('Sort asc'),
      sortDescText: I18N('Sort desc')
    },
    bbar: new Ext.PagingToolbar({
      store: params.store, // grid and PagingToolbar using same store
      displayInfo: true,
      pageSize: params.per_page,
      prependButtons: true,
      displayMsg: params.displayMsg,
      emptyMsg: params.emptyMsg
    }),
    tbar: params.tbar
  });

  if (params.store !== undefined)
  {
    //params.store.on("load", function() { panel.show(); } );
    params.store.load({ params: { start: 0, limit: params.per_page }});
  }

  return panel;
}


// Parameters:
//   title
//   primaryKey
//   displayMsg
//   emptyMsg
//   table_element_editor
//   server_handler_name
// Optional parameters:
//   store_maker
//   on_add_item
//   on_edit_item
//   on_successful_delete
//   add_request_params
PK.make_table_view_panel = function(
    panel_getter, title, columns, params, show_params
  )
{
  var PER_PAGE = 1000000; //20;

  var reader_fields = new Array;

  for(f in columns)
  {
    reader_fields[reader_fields.length] =
    {
      name: columns[f].dataIndex,
      convert: columns[f].convert
    }
  }

  var filters = new Ext.ux.grid.GridFilters({
    local: true, // false

    filters:[
      {dataIndex: params.primaryKey,   type: 'numeric'},
      {dataIndex: 'name',    type: 'string'}
//           {
//             dataIndex: 'risk',
//             type: 'list',
//             active:false,//whether filter value is activated
//             value:'low',//default filter value
//             options: ['low','medium','high'],
//             //if local = false or unspecified, phpMode has an effect
//             phpMode: false
//           }
    ]
  });



  if(params.store_maker)
  {
    store_ = params.store_maker(
        reader_fields, params.server_handler_name, PER_PAGE, show_params
      );
  }
  else
  {
    var request_params = undefined;
    if(params.add_request_params)
    {
      request_params = {};
      params.add_request_params(request_params, show_params);
    }

    store_ = PK.common_stores.make_store_with_custom_fields(
      reader_fields, params.primaryKey, params.server_handler_name + '/list',
      request_params, false
    );
  }

  function addItem()
  {
    if(params.on_add_item)
      params.on_add_item(params.table_element_editor, show_params);
    else
      PK.navigation.go_to_topic(params.table_element_editor, ["new"]);
  };

  function editItem(id)
  {
    if(!id && panel_getter().selModel.selections.keys.length > 0)
    {
      id = panel_getter().selModel.selections.keys[0];
    }

    if(id)
    {
      if(params.on_edit_item)
        params.on_edit_item(params.table_element_editor, show_params, id);
      else
        PK.navigation.go_to_topic(params.table_element_editor, [id]);
    }
  };

  function deleteItems()
  {
    var id = panel_getter().selModel.selections.keys[0];

    var request_url = PK.make_admin_request_url(
        params.server_handler_name + '/delete'
      );

    var request_params = {id: id};
    if(params.add_request_params)
      params.add_request_params(request_params, show_params);

    // TODO: Must render 'waitMsg' somehow
    Ext.Ajax.request({
      url: request_url,
      method: 'POST',
      params: PK.make_admin_request_params(request_params),

      //the function to be called upon failure of the request (404, 403 etc)
      failure:function(response,options)
      {
        PK.on_request_failure(request_url, response.status);
      },

      success:function(srv_raw_response,options)
      {
        var response = Ext.util.JSON.decode(srv_raw_response.responseText);
        if(response)
        {
          if(response.result /*&& response.result.count == 1*/)
          {
            store_.reload();
            if(params.on_successful_delete)
              params.on_successful_delete();
          }
          else
          {
            if(response.error)
            {
              PK.on_server_error(response.error.id);
            }
            else
            {
              CRITICAL_ERROR(
                  I18N('Sorry, please try again. Unknown server error.')
                  + ' ' + srv_raw_response.responseText
                );
            }
          }
        }
        else
        {
          CRITICAL_ERROR(
              I18N('Server answer format is invalid')
              + ': ' + srv_raw_response.responseText
            );
        }
      }
    });
  };

  function confirmDelete()
  {
    if(panel_getter().selModel.selections.keys.length > 0)
      Ext.Msg.confirm(
        I18N('Irreversible action'),
        I18N('Are you sure to delete selection?'),
        function(btn) { if(btn == 'yes') { deleteItems(); } }
      );
  };


  function onRowDblClick(grid, rowIndex, e)
  {
    var record = store_.getAt(rowIndex);
    var id = record[params.primaryKey];
    editItem(id);
    //This is an alternative way if the grid allows single selection only
    //editItem();
  };

  var tbar = [
    {
      text: I18N('Add'),
      tooltip: I18N('Click to add'),
      iconCls:'icon-add',
      handler: addItem
    }, '-', //add a separator
    {
      text: I18N('Delete'),
      tooltip: I18N('Click to delete'),
      iconCls:'icon-delete',
      handler: confirmDelete
    }
  ];

  if(params.custom_tbar)
  {
    for(var i = 0; i < params.custom_tbar.length; i++)
    {
      var tbar_item = params.custom_tbar[i];
      var handler = tbar_item.handler;
      tbar_item.handler = function() { return handler(panel_getter()); };
      tbar[tbar.length] = tbar_item;
    }
  }

  panel = PK.make_grid_panel({
      title: title,
      tbar: tbar,
      height: 550,
      width: 1010,
      per_page: PER_PAGE,
      displayMsg: params.displayMsg,
      emptyMsg: params.emptyMsg,
      render_to: 'main-module-panel',
      columns: columns,
      filters: filters,
      store: store_
    });

  panel.addListener('rowdblclick', onRowDblClick);

  return panel;
}

// Parameters:
//   title
//   primaryKey
//   columns
//   displayMsg
//   emptyMsg
//   table_element_editor
//   server_handler_name
// Optional parameters:
//   store_maker
//   on_add_item
//   on_edit_item
//   on_successful_delete
//   add_request_params
PK.make_table_view = function(params)
{
  return new function()
  {
    var panel_;
    var store_;

    var raw_init_ = function(columns, show_params)
    {
      if(typeof(params.title) == "function")
        this.title = params.title(show_params);
      else
        this.title = params.title;

      panel_ = PK.make_table_view_panel(
        function() { return panel_; },
        this.title,
        columns,
        params,
        show_params
      );

      LOG("created topic: table_view " + this.title);
    };

    this.init = function(show_params)
    {
      if(typeof(params.columns) == "function")
      {
        params.columns(function(columns) {raw_init_(columns, show_params);});
      }
      else
      {
        raw_init_(params.columns, show_params);
      }
    }

    this.show = function(show_params)
    {
      if(!panel_) { this.init(show_params); }
  //    panel_.show(show_params);
    };

    this.hide = function()
    {
      if(panel_)
      {
  //      panel_.hide();
        panel_.destroy();
        panel_ = undefined;
      }
    };
  };
};
