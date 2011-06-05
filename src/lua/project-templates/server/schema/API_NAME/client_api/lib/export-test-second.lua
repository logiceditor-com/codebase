-- TODO: Remove this file after api:export finished
--------------------------------------------------------------------------------

api:export "export-test-second" {
  exports = { "name3"; };
  handler = function()

    local name3 = function()
      fail()
      return name1()
    end

  end;
}
