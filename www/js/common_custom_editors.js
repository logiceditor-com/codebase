PK.common_custom_editors = new function()
{
  this.make_enum_editor_maker = function(my_enum)
  {
    return function()
    {
      return new Ext.grid.GridEditor(new Ext.form.ComboBox({
        // if we enable typeAhead it will be querying database
        // so we may not want typeahead consuming resources
        typeAhead: true,
        triggerAction: 'all',
        editable: false,

        mode: 'local',

        // By enabling lazyRender this prevents the combo box
        // from rendering until requested
        lazyRender: true, // should always be true for editor

        store: new Ext.data.ArrayStore({
            fields: ['id', 'text'],
            data: my_enum
          }),
        displayField: 'text',
        valueField: 'id'
      }));
    };
  };

  this.make_bool_editor =
    this.make_enum_editor_maker([[0, I18N('no')], [1, I18N('yes')]]);

  this.make_number_editor = function()
  {
    return new Ext.grid.GridEditor(new Ext.form.NumberField({
        selectOnFocus: true,
        allowBlank: true,
        style:'text-align:left;'
      }));
  };

  this.make_money_editor = function()
  {
    return new Ext.grid.GridEditor(new Ext.form.NumberField({
        selectOnFocus: true,
        allowBlank: true,
        style:'text-align:left;',
        allowDecimals: false,
        allowNegative: false
      }));
  };

  this.make_date_editor = function()
  {
    return new Ext.grid.GridEditor(new Ext.form.DateField({
        format: 'd.m.Y',
        selectOnFocus: true
      }));
  };

  this.make_profile_editor = function()
  {
    return new Ext.grid.GridEditor(new Ext.form.ComboBox({
      // if we enable typeAhead it will be querying database
      // so we may not want typeahead consuming resources
      typeAhead: false,
      triggerAction: 'all',

      // By enabling lazyRender this prevents the combo box
      // from rendering until requested
      lazyRender: true, // should always be true for editor

      store: PK.stores.admin_profiles,

      displayField: 'title',
      valueField: 'id'
    }));
  };

  this.make_password_editor = function()
  {
    var grid_editor = new Ext.grid.GridEditor(
        new Ext.form.TextField({allowBlank: false})
      );

    grid_editor.on(
        'beforecomplete',
        function(this_ge, value, startValue)
        {
          if(value && value != startValue && value.length > 0)
          {
            //this_ge.setValue(Ext.util.MD5(value));
            this_ge.setValue(value);
          }
          return true;
        }
      );

    return grid_editor;
  };


  this.make_editor_maker = function(value_type, params)
  {
    switch (Number(value_type))
    {
      case PK.table_element_types.STRING:
        return undefined;
        break;

      case PK.table_element_types.INT:
        return this.make_number_editor;
        break;

      case PK.table_element_types.ENUM:
        if(!params.enum_items)
          return undefined;
        return this.make_enum_editor_maker(params.enum_items);
        break;

      case PK.table_element_types.BOOL:
        return this.make_bool_editor;
        break;

      case PK.table_element_types.DATE:
        return this.make_date_editor;
        break;

      case PK.table_element_types.PHONE:
      case PK.table_element_types.MAIL:
        return undefined;
        break;

      case PK.table_element_types.DB_IDS:
        // TODO: Hack! Value can contain few ids!
        return this.make_number_editor;
        break;

      case PK.table_element_types.BINARY_DATA:
        return undefined;
        break;

      case PK.table_element_types.MONEY:
        return this.make_money_editor;
        break;

      default:
        return undefined;
    }
  };
};
