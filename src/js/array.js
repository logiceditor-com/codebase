// TODO: Very non-optimal!
PK.remove_holes_in_array = function(arr)
{
  if (!arr || arr.length == 0)
    return

  var i = 0;
  while (i < arr.length)
  {
    if (arr[i] === undefined)
    {
      arr.splice(i, 1)
    }
    else
    {
      i++
    }
  }
}
