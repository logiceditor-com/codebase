PKAdmin.filters = new function()
{
  this.make_string_filter = function(field_name, field_title)
  {
    return {
      render: function()
      {
        // TODO: Implement
        return {
          xtype: 'panel',
          baseCls: 'x-plain',
          layout: 'hbox',
          bodyStyle: 'padding: 2px 2px 2px 2px',
          items:
          [
            {
              xtype: 'label',
              text: field_name + " :"
            },
            { xtype: 'spacer', width: 10 },
            {
              xtype: 'combo',
              store: new Ext.data.ArrayStore({
                id: 0,
                fields: ['id', 'title'],
                data: [
                  [1, '<= X <='],
                  [2, '=']
                ]
              }),
              value: 1,
              valueField: 'id',
              displayField: 'title',
              autoSelect: true,
              editable: false,
              typeAhead: true,
              mode: 'local',
              triggerAction: 'all',
              selectOnFocus: true,
              width: 70,
              //listeners: { select : addFilter }
            },
            { xtype: 'spacer', width: 10 },
            {
              xtype: 'textfield',
              fieldLabel: field_title,
              name: field_name
              //vtype: filter_type
            },
            { xtype: 'spacer', width: 10 },
            {
              xtype: 'textfield',
              fieldLabel: field_title,
              name: field_name
              //vtype: filter_type
            }
          ]
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
