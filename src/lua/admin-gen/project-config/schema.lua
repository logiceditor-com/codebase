--------------------------------------------------------------------------------
-- project-config-schema.lua: project configuration file format
--------------------------------------------------------------------------------
-- To be processed with pk-engine/tools_cli_config.lua
--------------------------------------------------------------------------------

cfg:root
{

  cfg:existing_path "PROJECT_PATH";

-------------------------------------------------------------------------------

  cfg:node "common"
  {
    cfg:node "internal_config"
    {
      cfg:node "production"
      {
        cfg:host "host";
        cfg:port "port";
      };

      cfg:node "deploy"
      {
        cfg:host "host";
        cfg:port "port";
      };
    };

    cfg:node "db"
    {
      cfg:existing_path "schema_filename";
      cfg:existing_path "changes_dir";
      cfg:existing_path "tables_filename";
      cfg:existing_path "tables_test_data_filename";
    };

    cfg:node "resources"
    {
      cfg:existing_path "dir";
      cfg:path "path_prefix";
    };

    cfg:node "exports"
    {
      cfg:existing_path "exports_dir";
      cfg:existing_path "profiles_dir";

      cfg:non_empty_ilist "sources"
      {
        cfg:path "sources_dir";
        cfg:path "profile_filename";
        cfg:path "out_filename";
      };
    };

    cfg:node "www"
    {
      cfg:node "application"
      {
        cfg:url "url";
        cfg:path "session_checker_file_name";
        cfg:existing_path "api_schema_dir";
        cfg:boolean "have_unity_client";

        -- TODO: Refactor this section
        cfg:node "generated"
        {
          cfg:path   "file_root";
          cfg:path   "api_version_filename";
          cfg:path   "handlers_index_filename";
          cfg:path   "data_formats_filename";
          cfg:path   "handlers_dir_name";
          cfg:string "base_url_prefix";
          cfg:path   "unity_api_filename";
          cfg:path   "test_dir_name";
          cfg:existing_path "doc_latex_template_filename";
          cfg:path   "doc_md_filename";
          cfg:path   "doc_pdf_filename";
        };
      };
    };
  };

-------------------------------------------------------------------------------

  cfg:node "apigen"
  {
    cfg:boolean "keep_tmp" { default = false; };

    cfg:variant "action"
    {
      variants =
      {
        ["help"] =
        {
          -- No parameters
        };

        ["dump_nodes"] =
        {
          cfg:path "out_filename" { default = "-" }; -- default stdout
          cfg:boolean "with_indent" { default = true };
          cfg:boolean "with_names" { default = true };
        };

        ["check"] =
        {
          -- No parameters
        };

        ["dump_urls"] =
        {
          -- No parameters
        };

        ["dump_markdown_docs"] =
        {
          -- No parameters
        };

        ["generate_documents"] =
        {
          -- No parameters
        };

        ["update_handlers"] =
        {
          -- No parameters
        };

        ["update_all"] =
        {
          -- No parameters
        };
      };
    };
  };

-------------------------------------------------------------------------------

  cfg:node "admin_gen"
  {
    intedmediate =
    {
      cfg:path "api_schema_dir";
      cfg:path "js_dir";
    };

    cfg:variant "action"
    {
      variants =
      {
        ["help"] =
        {
          -- No parameters
        };

        ["generate_admin_api_schema"] =
        {
          -- No parameters
        };

        ["generate_js"] =
        {
          -- No parameters
        };
      };
    };
  };

-------------------------------------------------------------------------------

  cfg:node "mkdb"
  {
    cfg:variant "action"
    {
      variants =
      {
        ["help"] =
        {
          -- No parameters
        };

        ["mkdb"] =
        {
          -- No parameters
        };
      };
    };
  };

-------------------------------------------------------------------------------

  cfg:node "db_admin"
  {
    cfg:variant "action"
    {
      variants =
      {
        ["help"] =
        {
          -- No parameters
        };

        ["list"] =
        {
          cfg:non_empty_string "table_name";
        };

        ["insert"] =
        {
          cfg:non_empty_string "table_name";
          cfg:freeform_table "data";
        };

        ["update"] =
        {
          cfg:non_empty_string "table_name";
          cfg:freeform_table "data";
        };

        ["delete"] =
        {
          cfg:non_empty_string "table_name";
          -- TODO: Non-empty string? Primary key may be non-integer.
          cfg:positive_integer "id";
        };
      };
    };
  };

-------------------------------------------------------------------------------

  cfg:node "db_changes"
  {
    cfg:variant "action"
    {
      variants =
      {
        ["help"] =
        {
          -- No parameters
        };

        ["initialize_db"] =
        {
          cfg:non_empty_string "db_name";
          cfg:boolean "force" { default = false };
        };

        ["list_changes"] =
        {
          -- No parameters
        };

        ["upload_changes"] =
        {
          -- No parameters
        };

        ["revert_changes"] =
        {
          cfg:non_empty_string "stop_at_uuid";
        };
      };
    };
  };

-------------------------------------------------------------------------------

  cfg:node "dbgen"
  {
    cfg:variant "action"
    {
      variants =
      {
        ["help"] =
        {
          -- No parameters
        };

        ["check"] =
        {
          -- No parameters
        };

        ["dottify"] =
        {
          -- No parameters
        };

        ["update_changes"] =
        {
          cfg:boolean "force" { default = false };
        };

        ["update_tables"] =
        {
          cfg:boolean "force" { default = false };
        };

        ["update_tables_test_data"] =
        {
          cfg:boolean "force" { default = false };
        };

        ["update_db"] =
        {
          cfg:boolean "force" { default = false };
        };

        ["update_data_changeset"] =
        {
          cfg:boolean "force" { default = false };
          cfg:non_empty_string "table_name";
          cfg:boolean "ignore_in_tests" { default = true };
        };
      };
    };
  };

-------------------------------------------------------------------------------

  cfg:node "list_exports"
  {
    cfg:variant "action"
    {
      variants =
      {
        ["help"] =
        {
          -- No parameters
        };

        ["list_all"] =
        {
          -- No parameters
        };
      };
    };
  };

-------------------------------------------------------------------------------

  cfg:node "resources"
  {
    cfg:variant "action"
    {
      variants =
      {
        ["help"] =
        {
          -- No parameters
        };

        ["list"] =
        {
          -- No parameters
        };

        ["update"] =
        {
          -- No parameters
        };

        ["purge"] =
        {
          -- No parameters
        };
      };
    };
  };

-------------------------------------------------------------------------------

  cfg:node "check_config"
  {
    cfg:variant "action"
    {
      variants =
      {
        ["help"] =
        {
          -- No parameters
        };

        ["check"] =
        {
          -- No parameters
        };
      };
    };
  };

-------------------------------------------------------------------------------

}
