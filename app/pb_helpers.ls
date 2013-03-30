
# XXX shared by pb_mutants & pb_entry

# double-buffered replace of view with target
@render-and = (fn, w, target, tmpl, params, cb) -->
  $t = w.$ target
  $b = w.$ '<div>'
  $b.hide!
  $t[fn] $b
  jade.render $b.0, tmpl, params
  #$t[fn] $b.html!
  #$b.remove!
  $b.show!add-class \fadein
  cb $b
@render-and-append  = @render-and \append
@render-and-prepend = @render-and \prepend

@is-editing-regexp = /\/?(edit|new)\/?([\d+]*)\/?$/

@is-editing = ->
  m = window.location.pathname.match @is-editing-regexp
  return if m then m[2] else false

@remove-editing-url = ->
  if window.location.href.match @is-editing-regexp
    History.push-state {no-surf:true} '' window.location.href.replace(@is-editing-regexp, '')

@scroll-to-edit = (cb) ->
  cb = -> noop=1 unless cb
  id = is-editing!
  if id then # scroll to id
    awesome-scroll-to "\#subpost_#{id}" 600ms cb
    true
  else
    scroll-to-top cb
    false

# handle in-line editing
@edit-post = (id, data) ->
  focus  = (e) -> set-timeout (-> e.find 'input[type="text"]' .focus!), 100
  render = (sel, locals) ~>
    e = $ sel
    @render-and-prepend window, sel, \post_edit, post:locals, ->
      focus e

  scroll-to-edit!
  if not id.length and data # render new
    data.action = '/resources/post'
    data.method = \post
    render '.forum', data
  else # fetch existing & render
    sel = "\#subpost_#{id}"
    e   = $ sel
    unless e.find('.container:first:visible').length # guard
      $.get "/resources/posts/#{id}" (p) ->
        render sel, p
        e .add-class \editing
    else
      focus e

@align-breadcrumb = ->
  b = $ '#breadcrumb'
  m = $ '.menu'
  b.css \left ((m.width! - b.width!)/2 + m.offset!left)

# vim:fdm=indent
