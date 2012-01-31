//------------------------------------------------------------------------------
// Math functions
//------------------------------------------------------------------------------

PK.check_namespace('Math');

/**
 * Returns random int number from m to n.
 *
 * @param m
 * @param n
 */
PK.Math.random_int = function(m, n)
{
  return Math.floor(Math.random() * (n - m + 1)) + m;
}

/**
 * If number <= a returns a; If v >= b returns b; otherwise returns v.
 *
 * @param v
 * @param a
 * @param b
 */
PK.Math.clamp = function(v, a, b)
{
  if (a == b ) return a;

  if (b < a)
  {
    var tmp = a;
    a = b;
    b = tmp;
  }
  return Math.min(Math.max(v, a), b);
}
