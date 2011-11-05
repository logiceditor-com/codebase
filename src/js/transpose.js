/*
 *  Prototype and jQuery plugin to transpose Array.
 *
 * @author Shamasis Bhattacharya
 * @link http://www.shamasis.net/
 * @email mail@shamasis.net
 *
 * @version 1.0.0.0
 * @publish 24-Feb-2010 00:00 +0530 IST
 *
 */

/**
 * Transposes a given array.
 * @id Array.prototype.transpose
 * @author Shamasis Bhattacharya

 * @type Array
 * @return The Transposed Array
 * @compat=ALL
 */
Array.prototype.transpose = function() {

  // Calculate the width and height of the Array
  var a = this,
      w = a.length ? a.length : 0,
    h = a[0] instanceof Array ? a[0].length : 0;

  // In case it is a zero matrix, no transpose routine is needed.
  if(h === 0 || w === 0) { return []; }

  /**
   * @var {Number} i Counter
   * @var {Number} j Counter
   * @var {Array} t Is the array where transposed data is stored.
   */
  var i, j, t = [];

  // Loop through every item in the outer array (height)
  for(i=0; i<h; i++) {

    // Insert a new row (array)
    t[i] = [];

    // Loop through every item per item in outer array (width)
    for(j=0; j<w; j++) {

      // Save transposed data.
      t[i][j] = a[j][i];
    }
  }

  return t;
};

// If jQuery exists then write a function to extend jQuery with a transpose function.
if(typeof jQuery !== 'undefined') {
  jQuery.transpose = function(o) {
    if(o instanceof Array) {
      return o.transpose();
    }
  };
}
