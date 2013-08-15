require! {
  Component: yacomponent
  ch: \../app/client-helpers.ls
}

{templates} = require \../build/component-jade.js

module.exports =
  class AdminMenu extends Component
    const opts =
      handle: \div
      items:  \li
      max-levels: 2
      tolerance: \pointer
      tolerance-element: '> div'
      placeholder: \placeholder

    template: templates.AdminMenu
    current:  null # active "selected" menu item

    show:       ~> set-timeout (~> @$.find \.col2 .show 300ms), 300ms
    clone: (item) ~> # clone a templated defined as class="default"
      console.log \clone:, item
      e = @$.find \.default .clone!remove-class(\default).attr \id, item.id
      e.find \input # add metadata to input
        ..data \menu, item.data?menu
        ..val item.data?title
      e
    current-store: !~>
      unless e = @current then return # guard
      form = @$.find \form
      form.find 'input[name="menu"]' .remove! # prune old form data
      # store
      e.data \menu, form.serialize!
      e.data \title, @current.val!
      console.log \store-menu:, e.data \menu
      console.log \store-title:, e.data \title
    current-restore: !~>
      unless e = @current then return # guard
      form  = @$.find \form
      reset = -> form.get 0 .reset! # default
      {menu, title} = @current.data
      e.val title
      if menu # restore current's menu
        form.deserialize menu
        console.log \restored:, menu
      else
        reset!

    on-attach: !~>
      # pre-load nested sortable list + initial active
      # - safely assume 2 levels max for now)
      site = @state.site!
      if site.config.menu # init ui
        s = @$.find \.sortable
        try
          for item in JSON.parse site.config.menu # render parent menu
            console.log \parsed:, item
            s.append(@clone item) if item?id
            if item.data?menu # ... & siblings
              for sub-item in JSON.parse item?menu
                item.append(@clone sub-item) if sub-item?id
        s.nested-sortable opts
        set-timeout (-> s.find \input:first .focus!), 200ms
        @show!

      @$.on \click \.onclick-add (ev) ~>
        @show!

        const prefix = \list_
        # generate id & add new menu item!
        max = parse-int maximum(s.find \li |> map (-> it.id.replace prefix, ''))
        id  = unless max then 1 else max+1
        e   = @clone {id:"#prefix#id"}
        console.log \created:, e
        @$.find \.sortable
          ..append e
          ..nested-sortable opts
          ..find \input .focus!
        @current-restore
        false

      # save menu
      @$.on \click 'button[type="submit"]' (ev) ~>
        @current-store

        # get entire menu
        menu = @$.find \.sortable .data(\mjsNestedSortable).to-hierarchy! # extended to pull data attributes, too
        console.log \saving-nested-sortable:, menu
        form = @$.find \form
        form.append(@@$ \<input> # append new menu
          .attr \type, \hidden
          .attr \name, \menu
          .val JSON.stringify menu)
        submit-form ev, (data) ->
          f = $ this # form
          t = $(form.find \.tooltip)
          show-tooltip t, unless data.success then (data?errors?join \<br>) else \Saved!

      # save current form on active row/input
      @$.on \blur \.row   (ev) ~> @current-store
      @$.on \change \form (ev) ~> @current-store

      @$.on \click \.row (ev) ~>
        # load data for active row
        @current = $ ev.target
        @current-restore

      # init
      @$.find \.sortable .nested-sortable opts

    on-detach: -> @$.off!
