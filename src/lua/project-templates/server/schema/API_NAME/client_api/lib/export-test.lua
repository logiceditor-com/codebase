-- TODO: Remove this file after api:export finished
--------------------------------------------------------------------------------

api:export "export-test" {
  exports = {"name1"; "name2";};
  handler = function()
    local name_local = function()
    end

    local name1 = function()
      log("Name1 function worked successfuly")
      return name_local()
    end

    local name2 = function()
      fail("NOT_IMPLEMENTED", "TODO: Implement")
      return name_local()
    end

  end;
}
