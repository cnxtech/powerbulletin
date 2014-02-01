define = window?define or require(\amdefine) module
require, exports, module <- define

require! {
  XBBCode: './xbbcode'
}

# regex to match urls
url-pattern = /(\w+:\/\/[\w\.\?\&=\%\/-]+[\w\?\&=\%\/-])/g

replace-urls = (s, fn) ->
  s.replace url-pattern, fn

# given a url, return its hostname
hostname = (url) ->
  url.match(/^https?:\/\/(.*?)\//)?1

# given a url, find a way to embed it in html
embedded = (url) ->
  h = hostname url
  #if url.match /\.(jpe?g|png|gif)$/i
  #  """<a href="#{url}" target="_blank"><img src="#{url}" /></a>"""
  if h is \www.youtube.com and url.match(/v=(\w+)/)
    [m,v] = url.match(/v=(\w+)/)
    """<iframe width="560" height="315" src="//www.youtube.com/embed/#v" frameborder="0" allowfullscreen></iframe>"""
  else
    """<a href="#{url}" target="_blank">#{url}</a>"""

@cv = (converter) ->
  xbb = new XBBCode()
  converter.hooks.chain \preConversion, (text) ->
    console.log ">", text
    r = xbb.process { text, +add-inline-breaks }
    console.log "<", r
    return r?html
  converter.hooks.set \plainLinkText, embedded
  converter

@

# Example:
#
# require! { \pagedown, \./shared/format }
# cv = format.cv pagedown.get-sanitizing-converter!
# cv.make-html "# http://foo.com/img.jpg\n\n* one\n* two\n* three", {}