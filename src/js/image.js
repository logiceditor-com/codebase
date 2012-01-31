//-----------------------------------------------------------------------------
// image.js: A set of utilities working with DOM images
//-----------------------------------------------------------------------------

// TODO: Rename
function onImageLoadingError(evt)
{
  console.log(this, evt)
  var src = (this && this.src) ? this.src : "(invalid image)"
  PKHB.ERROR(I18N('Failed to load: ${1}', src))
  this.loading_failure = true
}


// TODO: Rename
function hbe_checkIsImageLoaded(img)
{
  // During the onload event, IE correctly identifies any images that
  // weren’t downloaded as not complete. Others should too. Gecko-based
  // browsers act like NS4 in that they report this incorrectly.
  if(!img || !img.complete){
    return false;
  }

  // However, they do have two very useful properties: naturalWidth and
  // naturalHeight. These give the true size of the image. If it failed
  // to load, either of these should be zero.
  if(typeof img.naturalWidth != "undefined" && img.naturalWidth == 0){
    return false;
  }

  // No other way of checking: assume it’s ok.
  return true;
}


// TODO: Rename
function hbe_checkIsImageLoadedOrFailed(img)
{
  if(hbe_checkIsImageLoaded(img))
    return true;

  return img && img.loading_failure;
}
