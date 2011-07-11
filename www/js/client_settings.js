PKAdmin.client_settings = new function()
{
  var DEFAULT_TABLE_COLUMN_SETTINGS =
  {
    hidden  : false,
    width   : 100
  }

  var table_column_settings_ = {}

  this.table_column = function(table_name, column_name)
  {
    if (!table_column_settings_[table_name])
      table_column_settings_[table_name] = {}

    if (!table_column_settings_[table_name][column_name])
    {
      table_column_settings_[table_name][column_name] = PK.clone(DEFAULT_TABLE_COLUMN_SETTINGS)

      table_column_settings_[table_name][column_name].width =
       Ext.util.TextMetrics.measure(
           Ext.get('navigator-menu-data'),
           I18N(column_name)
         ).width
         + 25
    }

    return table_column_settings_[table_name][column_name]
  }
}
