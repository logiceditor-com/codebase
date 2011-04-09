local log, dbg, spam, log_error
      = import 'pk-core/log.lua' { 'make_loggers' } (
          "deploy-rocks-common", "DRC"
        )

--------------------------------------------------------------------------------

local pairs, pcall, assert, error, select, next, loadfile, loadstring
    = pairs, pcall, assert, error, select, next, loadfile, loadstring

local table_concat = table.concat
local io = io
local os = os

--------------------------------------------------------------------------------

local arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments'
      }

local is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_table'
      }

local assert_is_table
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table'
      }

local tset
      = import 'lua-nucleo/table-utils.lua'
      {
        'tset'
      }

local do_in_environment
      = import 'lua-nucleo/sandbox.lua'
      {
        'do_in_environment'
      }

local shell_exec
      = import 'lua-aplicado/shell.lua'
      {
        'shell_exec'
      }

--------------------------------------------------------------------------------
-- TODO: Move these somewhere to lua-aplicado?

local write_flush = function(...)
  io.stdout:write(...)
  io.stdout:flush()
  return io.stdout
end

local writeln_flush = function(...)
  io.stdout:write(...)
  io.stdout:write("\n")
  io.stdout:flush()
  return io.stdout
end

local ask_user = function(prompt, choices, default)
  arguments(
      "string", prompt,
      "table", choices
    )
  assert(#choices > 0)

  local choices_set = tset(choices)

  writeln_flush(
      prompt, " [", table_concat(choices, ","), "]",
      default and ("=" .. default) or ""
    )

  for line in io.lines() do
    if (default and line == "") then
      return default
    end

    if choices_set[line] then
      return line
    end

    writeln_flush(
        prompt, " [", table_concat(choices, ","), "]",
        default and ("=" .. default) or ""
      )
  end

  return default -- May be nil if no default and user pressed ^D
end

local copy_file_to_dir = function(filename, dir)
  assert(shell_exec(
      "cp", filename, dir .. "/"
    ) == 0)
end

local remove_file = function(filename)
  assert(shell_exec(
      "rm", filename
    ) == 0)
end

local create_symlink_from_to = function(from_filename, to_filename)
  assert(shell_exec(
      "ln", "-s", from_filename, to_filename
    ) == 0)
end

-- TODO: Move these somewhere to lua-nucleo?

local load_table_from_file = function(path)
  local chunk = assert(loadfile(path))
  local ok, table_from_file = assert(do_in_environment(chunk, { }))
  assert_is_table(table_from_file)
  return table_from_file
end


--------------------------------------------------------------------------------

return
{
  writeln_flush = writeln_flush;
  write_flush = write_flush;
  ask_user = ask_user;
  copy_file_to_dir = copy_file_to_dir;
  remove_file = remove_file;
  create_symlink_from_to = create_symlink_from_to;
  load_table_from_file = load_table_from_file;
}
