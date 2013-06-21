require! \./Component.ls

{templates} = require \../build/component-jade.js

module.exports =
  class Auth extends Component
    # attributes
    component-name: \Auth
    template: templates.Auth

    # static methods

    # helper to construct an Auth component and show it
    @show-login-dialog = (cb=(->)) ->
      lazy-load (-> window.$.fn.complexify), "#{window.cache-url}/local/jquery.complexify.min.js", [], ~>
        if not window._auth
          window._auth             = new Auth locals: {site-name: window.site-name}, $('#auth')
          window._auth.after-login = Auth.after-login if Auth.after-login
          window._auth.attach!

        $.fancybox.open \#auth, window.fancybox-params
        set-timeout (-> $ '#auth input[name=username]' .focus! ), 100ms
        # password complexity ui
        window.COMPLEXIFY_BANLIST = [\god \money \password]
        $ '#auth [name="password"]' .complexify({}, (pass, percent) ->
          e = $ this .parent!
          e.find \.strength-meter .toggle-class \strong, pass
          e.find \.strength .css(height:parse-int(percent)+\%))
        cb window._auth.$

    @show-info-dialog = (msg, cb=(->)) ->
      <- Auth.show-login-dialog
      fb = $ \.fancybox-wrap:first
      fb.find \#msg .html msg
      set-timeout (-> switch-and-focus '', \on-dialog, ''), 500ms
      cb window._auth.$

    @show-reset-password-dialog = ->
      $auth <- Auth.show-login-dialog
      $form = $auth .find('.reset form')
      set-timeout (-> switch-and-focus '', \on-reset, '#auth .reset input:first'), 500ms
      hash = location.hash.split('=')[1]
      $form.find('input[type=hidden]').val(hash)
      console.log hash, $form, $auth
      $.post '/auth/forgot-user', { forgot: hash }, (r) ->
        if r.success
          $form .find 'h2:first' .html 'Choose a New Password'
          $form .find('input').prop('disabled', false)
        else
          $form .find 'h2:first' .html "Couldn't find you. :("

    # helper for wrapping event handlers in a function that requires authentication first
    @require-login = (fn) ->
      ->
        if window.user
          fn.apply window, arguments
        else
          Auth.show-login-dialog!
          false

    # constructor
    ->
      super ...

    on-attach: !~>
      @$.find '.social a' .click @open-oauth-window
      @$.on \submit '.login form' @login
      @$.on \submit '.register form' @register
      @$.on \submit '.forgot form' @forgot-password
      @$.on \submit '.reset form' @reset-password
      @$.on \click '.toggle-password' @toggle-password
      @$.on \submit '.choose form' @choose

    on-detach: !~>

    # open window for 3rd party authentication
    open-oauth-window: (ev) ->
      url = $(this).attr \href
      window.open url, \popup, "width=980,height=650,scrollbars=no,toolbar=no,location=no,directories=no,status=no,menubar=no"
      false

    # handler for login form
    login: (ev) ~>
      $form = $ ev.target
      u = $form.find('input[name=username]')
      p = $form.find('input[name=password]')
      params =
        username: u.val!
        password: p.val!
      $.post $form.attr(\action), params, (r) ~>
        if r.success
          $.fancybox.close!
          @after-login! if @after-login
        else
          $fancybox = $form.parents \.fancybox-wrap:first
          $fancybox.add-class \on-error
          $fancybox.remove-class \shake
          show-tooltip $form.find(\.tooltip), 'Try again!' # display error
          set-timeout (-> $fancybox.add-class(\shake); u.focus!), 100ms
      false

    # After a login, different webapps may want to do differnt things.
    after-login: ~>
      # This may be overridden after construction.

    # TODO - what am I going to do about
    # - switch-and-focus
    # - show-tooltip
    # - shake-dialog
    register: (ev) ~>
      $form = $ ev.target
      $form.find(\input).remove-class \validation-error
      $.post $form.attr(\action), $form.serialize!, (r) ~>
        if r.success
          $form.find("input:text,input:password").remove-class(\validation-error).val ''
          switch-and-focus \on-register \on-dialog ''
        else
          msgs = []
          r.errors?for-each (e) ->
            $e = $form.find("input[name=#{e.param}]")
            $e.add-class \validation-error .focus! # focus control
            msgs.push e.msg
          show-tooltip $form.find(\.tooltip), msgs.join \<br> # display errors
          shake-dialog $form, 100ms
      false

    # handler for form that asking for a password reset email
    forgot-password: (ev) ~>
      $form = $ ev.target
      $.post $form.attr(\action), $form.serialize!, (r) ~>
        if r.success
          show-info-dialog 'Check your inbox for reset link!'
        else
          $form.find \input:first .focus!
          msg = r.errors?0?name or r.errors?0?msg or 'Unable to find you'
          show-tooltip $form.find(\.tooltip), msg # display error
          shake-dialog $form, 100ms
      false

    # handler for form for resetting a forgotten password
    reset-password: (ev) ~>
      $form = $ ev.target
      password = $form.find('input[name=password]').val!
      if password.match /^\s*$/
        show-tooltip $form.find(\.tooltip), "Password may not be blank"
        return false
      $.post $form.attr(\action), $form.serialize!, (r) ~>
        if r.success
          $form.find('input').prop(\disabled, true)
          show-tooltip $form.find(\.tooltip), "Password changed!"
          location.hash = ''
          $form.find('input[name=password]').val('')
          set-timeout ( ->
            switch-and-focus \on-reset, \on-login, '#auth .login input:first'
            show-tooltip $('#auth .login form .tooltip'), "Now log in!"
          ), 1500ms
        else
          show-tooltip $form.find(\.tooltip), "Choose a better password"
      false

    # this toggles the visibility of the password field in case people want to see
    # their password as they type it
    toggle-password: (ev) ~>
      e = $ ev.target
      p = e.prev '[name=password]'
      if p.attr(\type) is \password
        e.html \Hide
        p.attr \type \text
      else
        e.html \Show
        p.attr \type \password
      false

    # choose a username
    choose: (ev) ~>
      $form = $ ev.target
      $.post $form.attr(\action), $form.serialize!, (r) ~>
        if r.success
          $.fancybox.close!
          @after-login!
          window.location.hash = ''
        else
          $form.find \input:first .focus!
          show-tooltip $form.find(\.tooltip), r.msg # display error
          shake-dialog $form, 100ms
      false
