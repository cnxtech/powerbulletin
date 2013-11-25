define = window?define or require(\amdefine) module
require, exports, module <- define

require! {
  Component: yacomponent
  #pagedown # XXX pull in converter + sanitizer if needed on server
}
{templates} = require \../build/component-jade
{storage, lazy-load-fancybox} = require \../client/client-helpers

const max-retry      = 3failures
const watch-interval = 2500ms # check dirty every...

module.exports =
  class Editor extends Component
    dirty:   false
    watcher: void
    retry:   0
    editor:  void

    template: templates.Editor

    init: ->
      # defaults
      @local \id,   '' unless @local \id
      @local \body, '' unless @local \body

    body:  ~> @editor.val!
    watch: ~> @watcher = set-interval @save, watch-interval
    save: (to-server=false) ~>
      v = @editor.val!
      if @dirty # save!
        if to-server or (parse-int(Math.random!*4) is 1) # 1-in-4 saves to server
          clear-interval @watcher; @watcher=void # stop watching
          data = {}
          @@$.ajax {
            type : \PUT
            data : {config:sig:v}
            url  : @local \url
          }
            ..done (r) ~> # saved, so reset--
              @dirty=false
              @retry=0
              @watch @save
            ..fail (r) ~> # failed, so try again until max-retries
              if ++@retry <= max-retry then @watch @save true # to server, again
        else # local storage
          storage.set \sig, v

    on-attach: ->
      ####  main  ;,.. ___  _
      # lazy-load-pagedown on client
      window.Markdown ||= {}
      <~ require <[pdEditor pdConverter pdSanitizer]>

      # init editor
      id      = @local \id
      html-id = if id then "\#wmd-input#id" else \#wmd-input
      @editor  = @@$ html-id

      c = new Markdown.Converter!
      e = new Markdown.Editor c, id
      e.run!
      #{{{ - delegates
      # escape to close
      @editor.on \keydown ~> if it.which is 27 then $.fancybox.close!; false
      @editor.on \keyup   ~> @dirty=true # yo, editor--save me soon
      #}}}
      @watch @save # initial watch--go
      set-timeout (~> @editor.focus!), 100ms # ... & focus!

    on-detach: ~> # XXX ensure detach is called
      # save & cleanup
      clear-interval @watcher
      @save true # to server
      @$.off!remove!

# vim: fdm=marker
