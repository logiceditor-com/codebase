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


  this.make_common_filter = function(value_type, ordered, field_name, field_title, params)
  {
    var render_comparision_params = function()
    {
      return PK.common_custom_editors.make_form_field_editor(
        value_type, params
      )
    }

    var render_interval_params = function()
    {
      return [
        PK.common_custom_editors.make_form_field_editor(
          value_type, params
        ),
        { xtype: 'spacer', width: 10 },
        { xtype: 'label', html: "&dash;" },
        { xtype: 'spacer', width: 10 },
        PK.common_custom_editors.make_form_field_editor(
          value_type, params
        ),
      ]
    }


    var filter_types = [ [ '=', render_comparision_params ] ]

    if (ordered)
    {
      //TODO: Add <, <=, >, >= comparators

      filter_types.push([ I18N('interval'), render_interval_params ])
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
                data: filter_types
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


  this.make_filter = function(value_type, field_name, field_title, params)
  {
    switch (Number(value_type))
    {
      case PK.table_element_types.STRING:
      case PK.table_element_types.INT:
      case PK.table_element_types.DATE:
      case PK.table_element_types.PHONE:
      case PK.table_element_types.MAIL:
      case PK.table_element_types.DB_IDS:
      case PK.table_element_types.MONEY:
        return this.make_common_filter(value_type, true, field_name, field_title, params)
        break

      case PK.table_element_types.BOOL:
      case PK.table_element_types.ENUM:
        return this.make_common_filter(value_type, false, field_name, field_title, params)
        break

      case PK.table_element_types.BINARY_DATA:
        return undefined // No filter for binary data
        break

      default:
        return undefined
    }
  }
}
