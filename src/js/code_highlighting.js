PK.code_highlighting = new function()
{
  hljs.initHighlightingOnLoad()

  this.highlight = function(code_text)
  {
    var viewDiv = document.getElementById("highlight-view");

    viewDiv.innerHTML = '<pre><code class="lua">' + code_text + "</code></pre>"
    hljs.highlightBlock(viewDiv.firstChild.firstChild)

    var result = viewDiv.innerHTML
    viewDiv.innerHTML = ""

    return result
  }
};
