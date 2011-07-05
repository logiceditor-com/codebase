PKAdmin.filters = new function()
{
  this.make_string_filter = function(field_name, field_title)
  {
    return {
      render: function()
      {
        // TODO: Implement
        return {
          xtype: 'textfield',
          fieldLabel: field_title,
          name: field_name
          //vtype: filter_type
        }
      }
    }
  }

  // TODO: Implement filters
  this.make_int_filter = this.make_string_filter
  this.make_enum_filter = this.make_string_filter
  this.make_bool_filter = this.make_string_filter
  this.make_date_filter = this.make_string_filter
  this.make_db_ids_filter = this.make_string_filter
  this.make_money_filter = this.make_string_filter


  this.make_filter = function(value_type, field_name, field_title, params)
  {
    switch (Number(value_type))
    {
      case PK.table_element_types.STRING:
        return this.make_string_filter(field_name, field_title)
        break

      case PK.table_element_types.INT:
        return this.make_int_filter(field_name, field_title, params ? params.precision : undefined)
        break

      case PK.table_element_types.ENUM:
        if(!params.enum_items)
        {
          CRITICAL_ERROR("Enum_items not defined for " + field_title)
          return undefined
        }
        return this.make_enum_filter(field_name, field_title, params.enum_items)
        break;

      case PK.table_element_types.BOOL:
        return this.make_bool_filter(field_name, field_title)
        break

      case PK.table_element_types.DATE:
        return this.make_date_filter(field_name, field_title, params.print_time)
        break

      case PK.table_element_types.PHONE:
      case PK.table_element_types.MAIL:
        return this.make_string_filter(field_name, field_title)
        break

      case PK.table_element_types.DB_IDS:
        return this.make_db_ids_filter(field_name, field_title)
        break

      case PK.table_element_types.BINARY_DATA:
        return undefined // No filter for binary data
        break

      case PK.table_element_types.MONEY:
        return this.make_money_filter(field_name, field_title);
        break;

      default:
        return undefined
    }
  }
}
