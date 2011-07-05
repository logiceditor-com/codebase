PKAdmin.filters = new function()
{
  var wrap_filter_params_ = function(items)
  {
    return {
      id: 'param_container',
      xtype: 'panel',
      baseCls: 'x-plain',
      flex: 1,
      //height: 50,
      layout: 'hbox',
      items: items
    }
  }

  var update_filter_ = function(single_filter_panel, items)
  {
    single_filter_panel.remove('param_container')
    single_filter_panel.add(wrap_filter_params_(items))
    single_filter_panel.doLayout()
  }


  this.make_string_filter = function(field_name, field_title)
  {
    var render_comparision_params = function()
    {
      return {
        xtype: 'textfield'
      }
    }

    var render_interval_params = function()
    {
      return [
        {
          xtype: 'textfield'
        },
        { xtype: 'spacer', width: 10 },
        { xtype: 'label', html: "&dash;" },
        { xtype: 'spacer', width: 10 },
        {
          xtype: 'textfield'
        }
      ]
    }

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
              text: field_title + " :"
            },
            { xtype: 'spacer', width: 10 },
            {
              xtype: 'combo',
              store: new Ext.data.ArrayStore({
                fields: ['title', 'params_renderer' ],
                data: [
                  [ '=', render_comparision_params ],
                  [ I18N('interval'), render_interval_params ]
                ]
              }),
              value: '=',
              valueField: 'title',
              displayField: 'title',
              autoSelect: true,
              editable: false,
              typeAhead: true,
              mode: 'local',
              triggerAction: 'all',
              selectOnFocus: true,
              width: 80,
              listeners: { select : function(el, item) {
                var items = item.data.params_renderer()
                var single_filter_panel = el.ownerCt
                update_filter_(single_filter_panel, items)
              }}
            },
            { xtype: 'spacer', width: 10 },
            wrap_filter_params_(render_comparision_params())
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
