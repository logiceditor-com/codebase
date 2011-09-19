PK.check_namespace('Time');

PK.Time.get_current_timestamp = function()
{
  return ((new Date)*1 - 1);
}
