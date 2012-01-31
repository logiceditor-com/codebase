PK.check_namespace('Math');

PK.Math.random_int = function(m, n)
{
  return Math.floor( Math.random() * (n - m + 1) ) + m;
}

PK.Math.clamp = function(v, a, b)
{
  if (a == b )
    return a

  if (b < a) { var tmp = a; a=b; b=tmp; }
  return Math.min( Math.max(v,a), b )
}
