// TODO: Very non-optimal!
PK.remove_holes_in_array = function(arr)
{
  if (!arr || arr.length == 0)
    return

  //PKLILE.timing.start("remove_holes_in_array")
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
  //PKLILE.timing.stop("remove_holes_in_array")
}
