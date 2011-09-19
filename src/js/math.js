PK.check_namespace('Math');

PK.Math.random_int = function(m, n)
{
  return Math.floor( Math.random() * (n - m + 1) ) + m;
}
