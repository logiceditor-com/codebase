--------------------------------------------------------------------------------
-- #{PROJECT_LIBDIR}.lua: apigen configuration
#{FILE_HEADER}
--------------------------------------------------------------------------------
-- Note that PROJECT_PATH is defined in the environment
--------------------------------------------------------------------------------

local file = function(name) return { filename = name } end

local NAME = "#{PROJECT_LIBDIR}"

local EXPORTS_LIST_NAME = PROJECT_PATH
    .. "tmp/" .. NAME .. "/code/exports/client_api.lua"

common.PROJECT_PATH = PROJECT_PATH
common.www.application.file_header = [[
#{FILE_HEADER}
]]
common.www.application.url = "http://." -- no url used
common.www.application.api_schema_dir = PROJECT_PATH .. "#{PROJECT_LIBDIR}/schema/client_api/"
common.www.application.have_unity_client = false

common.www.application.db_tables_filename = "#{PROJECT_LIBDIR}/verbatim/db/tables.lua"
common.www.application.webservice_request_filename = "#{PROJECT_LIBDIR}/verbatim/webservice/request.lua"

common.www.application.code.exports =
{
  file (PROJECT_PATH .. "lib/lua-nucleo/lua-nucleo/code/exports.lua");
  file (PROJECT_PATH .. "lib/lua-aplicado/lua-aplicado/code/exports.lua");
  file (PROJECT_PATH .. "lib/pk-core/pk-core/code/exports.lua");
  file (PROJECT_PATH .. "lib/pk-engine/pk-engine/code/exports.lua");
--[[BLOCK_START:PK_ADMIN]]
  file (PROJECT_PATH .. "lib/pk-admin/pk-admin/code/exports.lua");
--[[BLOCK_END:PK_ADMIN]]
--[[BLOCK_START:PK_WEBSERVICE]]
  file (PROJECT_PATH .. "lib/pk-webservice/generated/pk-webservice/code/exports.lua");
--[[BLOCK_END:PK_WEBSERVICE]]
  --
  file (EXPORTS_LIST_NAME);
}

common.www.application.code.requires =
{
  file (PROJECT_PATH .. "lib/pk-engine/pk-engine/code/requires.lua");
}

common.www.application.code.globals =
{
  file (PROJECT_PATH .. "lib/lua-nucleo/lua-nucleo/code/foreign-globals/luajit2.lua");
  file (PROJECT_PATH .. "lib/lua-nucleo/lua-nucleo/code/foreign-globals/lua5_1.lua");
  file (PROJECT_PATH .. "lib/lua-nucleo/lua-nucleo/code/globals.lua");
}

common.www.application.generated =
{
  file_root = PROJECT_PATH .. NAME .. "/generated/";

  api_version_filename = "client_api_version.lua";
  handlers_index_filename = "handlers.lua";
  data_formats_filename = "formats.lua";
  handlers_dir_name = "handlers";

  exports_dir_name = "#{PROJECT_LIBDIR}/lib";
  exports_list_name = EXPORTS_LIST_NAME;

  context_extensions_dir_name = "#{PROJECT_LIBDIR}/ext";
  context_extensions_list_name = "#{PROJECT_LIBDIR}/extensions/extensions.lua";

  doc_md_filename = PROJECT_PATH .. "doc/#{PROJECT_LIBDIR}.md";
  doc_pdf_filename = PROJECT_PATH .. "doc/#{PROJECT_LIBDIR}.pdf";
  doc_latex_template_filename = common.www.application.api_schema_dir
    .. "/doc/latex.template";

  base_url_prefix = "/";

  --

  unity_api_filename = "/dev/null";
  test_dir_name = "/dev/null";
}

apigen =
{
  action =
  {
    name = "help";
    param =
    {
      -- No parameters
    };
  };
}
