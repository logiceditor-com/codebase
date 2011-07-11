PKAdmin.client_settings = new function()
{
  var DEFAULT_TABLE_COLUMN_SETTINGS =
  {
    hidden  : false,
    width   : 250
  }

  var table_column_settings_ = {}


  this.table_column = function(table_name, column_name)
  {
    if (!table_column_settings_[table_name])
      table_column_settings_[table_name] = {}

    if (!table_column_settings_[table_name][column_name])
    {
      table_column_settings_[table_name][column_name] = PK.clone(DEFAULT_TABLE_COLUMN_SETTINGS)

      //table_column_settings_[table_name][column_name].width =
      //  Ext.util.TextMetrics.measure(default_column, I18N(column_name).width)
    }

    return table_column_settings_[table_name][column_name]
  }
}
