PKAdmin.client_settings = new function()
{
  // TODO: Generalize and move to pk-core-js
  var set_fields = function(object, data)
  {
    for (var i = 0; i < data.length; i++)
      object[data[i][0]] = data[i][1]
  }

  var DEFAULT_TABLE_COLUMN_SETTINGS = []

  set_fields(
      DEFAULT_TABLE_COLUMN_SETTINGS,
      [
        [ PK.table_element_types.STRING,           { hidden  : false, width   : 100 } ],
        [ PK.table_element_types.INT,              { hidden  : false, width   :  50 } ],
        [ PK.table_element_types.ENUM,             { hidden  : false, width   : 100 } ],
        [ PK.table_element_types.BOOL,             { hidden  : false, width   :  50 } ],
        [ PK.table_element_types.DATE,             { hidden  : false, width   : 150 } ],
        [ PK.table_element_types.PHONE,            { hidden  : false, width   : 100 } ],
        [ PK.table_element_types.MAIL,             { hidden  : false, width   : 100 } ],
        [ PK.table_element_types.DB_IDS,           { hidden  : false, width   :  50 } ],
        [ PK.table_element_types.BINARY_DATA,      { hidden  : false, width   :  50 } ],
        [ PK.table_element_types.MONEY,            { hidden  : false, width   :  50 } ],
        [ PK.table_element_types.SERIALIZED_LIST,  { hidden  : false, width   :  50 } ]
      ]
    )

  var table_column_settings_ = {}

  this.table_column = function(table_name, column_name, field_type)
  {
    if (!table_column_settings_[table_name])
      table_column_settings_[table_name] = {}

    if (!table_column_settings_[table_name][column_name])
    {
      table_column_settings_[table_name][column_name] = PK.clone(DEFAULT_TABLE_COLUMN_SETTINGS[field_type])

       var caption_width = Ext.util.TextMetrics.measure(
           Ext.get('navigator-menu-data'),
           I18N(column_name)
         ).width
         + 25


      table_column_settings_[table_name][column_name].width = Math.max(
          table_column_settings_[table_name][column_name].width,
          caption_width
        )
    }

    return table_column_settings_[table_name][column_name]
  }
}
