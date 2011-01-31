PK.code_highlighting = new function()
{
  if (!window.hljs)
  {
    this.highlight = function(code_text) { return '<pre>' + code_text + '</pre>' }
    return
  }

  hljs.initHighlightingOnLoad()

  this.highlight = function(code_text)
  {
    var viewDiv = document.getElementById("highlight-view");
    if(!viewDiv)
    {
      CRITICAL_ERROR("No 'highlight-view' div necessary for code highlighting!")
      return '<pre>' + code_text + '</pre>'
    }

    viewDiv.innerHTML = '<pre><code class="lua">' + code_text + "</code></pre>"
    hljs.highlightBlock(viewDiv.firstChild.firstChild)

    var result = viewDiv.innerHTML
    viewDiv.innerHTML = ""

    return result
  }
};
