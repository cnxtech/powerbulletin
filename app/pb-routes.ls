require! {
  express
  \body-parser
  \cookie-parser
  \cookie-session
  fs
  mutant
  async
  csurf
  cors
  \./auth
  \./auth-handlers
  mmw: \mutant/middleware
  pg:  \./postgres
  mw:  \./middleware
  jsu: \./js-urls

  mutants:   \../shared/pb-mutants
  handlers:  \./pb-handlers
  resources: \./pb-resources
}
global <<< require \./server-helpers

# middleware we will use only on personalized routes to save cpu cycles!
auth-mw =
  * cookie-parser!
  * cookie-session {secret:cvars.secret, proxy:true, cookie:{secure-proxy:true, secure:true, max-age:1000*60*60*24*365}}
  * auth.mw.initialize
  * auth.mw.session
personal-mw =
  * cors(origin: '*', credentials: true)
  * body-parser.urlencoded {+extended, +defer}
  ...auth-mw

exports.use = (app) ->
#{{{ API Resources
  # upload handlers (personal-mw interferes with formidable)
  app.post   \/resources/users/:id/avatar,               ...auth-mw, handlers.profile-avatar
  app.post   \/resources/sites/:id/header,               ...auth-mw, handlers.forum-header
  app.post   \/resources/forums/:id/background,          ...auth-mw, handlers.forum-background
  app.post   \/resources/sites/:id/logo,                 ...auth-mw, handlers.forum-logo
  app.post   \/resources/sites/:id/private-background,   ...auth-mw, handlers.private-background
  app.post   \/resources/sites/:id/offer-photo/:offerid, ...auth-mw, handlers.offer-photo
  app.post   \/resources/sites/:id/upload,               ...auth-mw, handlers.site-upload # FIXME use csurf!

  app.all      \/resources/*,                 ...personal-mw
  app.resource \resources/sites,              resources.sites
  app.resource \resources/posts,              resources.posts
  app.resource \resources/users,              resources.users
  app.resource \resources/aliases,            resources.aliases
  app.resource \resources/products,           resources.products
  app.resource \resources/conversations,      resources.conversations
  app.resource \resources/threads,            resources.threads
  app.resource \resources/domains,            resources.domains

  app.get  \/resources/posts/:id/sub-posts,   handlers.sub-posts
  app.post \/resources/posts/:id/impression,  handlers.add-impression
  app.post \/resources/posts/:id/censor,      handlers.censor
  app.post \/resources/posts/:id/uncensor,    handlers.uncensor
  app.post \/resources/posts/:id/sticky,      handlers.sticky
  app.post \/resources/posts/:id/locked,      handlers.locked
  app.put \/resources/users/:id/avatar,       handlers.profile-avatar-crop

  # TODO move csrf as site-wide middleware
  app.get    \/resources/sites/:id/csrf,   csurf!, handlers.get-csrf

  app.delete \/resources/sites/:id/header,               handlers.forum-header-delete
  app.delete \/resources/forums/:id/background,          handlers.forum-background-delete
  app.delete \/resources/sites/:id/logo,                 handlers.forum-logo-delete
  app.delete \/resources/sites/:id/private-background,   handlers.private-background-delete
  app.delete \/resources/sites/:id/offer-photo/:offerid, handlers.offer-photo-delete
  app.delete \/resources/sites/:id/upload,               handlers.site-delete

#}}}

#{{{ Common JS
  common-js = [v for k,v of jsu when k in [
    \jquery
    \jqueryComplexify
    \jqueryCookie
    \jqueryFancybox
    \jqueryHistory
    \jqueryMasonry
    \jqueryTransit
    \jqueryUi
    \jqueryWaypoints
    \raf
    \reactivejs
    \socketio
    \powerbulletin]]
##}}}

# inject testing code in dev only
  if process.env.NODE_ENV is \development
    entry = common-js.pop!
    common-js.push "#{cvars.cache5-url}/local/mocha.js"
    common-js.push "#{cvars.cache5-url}/local/chai.js"
    common-js.push entry

#{{{ Admin
  app.get \/admin/:action?,
    personal-mw.concat(
      , mw.require-admin
      , mw.add-js(common-js)
      , mmw.mutant-layout(\layout, mutants)
    ),
    handlers.admin
#}}}

# MISC AJAX
  app.post '/ajax/checkout/:productId', personal-mw, handlers.checkout

# auth
  auth-handlers.apply-to app, personal-mw

#{{{ Users
  app.get '/u/:name', (req, res, next) ->
    res.redirect "/user/#{req.params.name}/", 301

  app.get '/user/:name',
    personal-mw,
    mw.add-js(common-js),
    mmw.mutant-layout(\layout, mutants),
    mw.private-site,
    handlers.profile

  app.get '/user/:name/page/:page',
    personal-mw,
    mw.add-js(common-js),
    mmw.mutant-layout(\layout, mutants),
    mw.private-site,
    handlers.profile
#}}}

  app.get '/dynamic/css/:file' handlers.stylus # dynamic serving

  app.get '/favicon.ico', (req, res, next) ->
    # TODO - replace with real favicon
    next 404, \404

  app.get '/robots.txt', mw.multi-domain, (req, res, next) ->
    res.send if res.locals.private
      '''
      User-agent: *
      Disallow: /
      '''
    else
      '''
      User-agent: *
      Allow: /
      '''

  app.get '/_routes', (req, res, next) -> # print GET routes
    res.send ["#{r.path}\n" for r in app.routes[\get]]

# page handler tries to match paths before forum handler
  app.get '*',
    personal-mw,
    mw.add-js(common-js),
    mmw.mutant-layout(\layout, mutants),
    mw.private-site,
    handlers.page

  app.get '/',
    personal-mw,
    mw.geo,
    mw.add-js(common-js),
    mmw.mutant-layout(\layout, mutants),
    mw.private-site,
    handlers.homepage

  app.get \/search,
    personal-mw,
    mw.add-js(common-js),
    mmw.mutant-layout(\layout, mutants),
    mw.private-site,
    handlers.search

  app.get '/hello', handlers.hello

  # stream download to browser
  app.get '/download/:siteId/uploads/:file' personal-mw, (req, res, next) ->
    res.set-header \content-type \application/octet-stream
    return res.status 400 .send 'Bad file' if req.params.file.match /\.\./ # guard
    site = res.vars.site
    file = "./public/sites/#{site.id}/uploads/#{req.params.file}" # XXX don't trust client site-id
    err, stat <- fs.stat file
    if err then return res.status 400 .send 'Unable to stream file' # guard
    if stat.is-file! then fs.create-read-stream file .pipe res

  app.get '/:forum/most-active',
    personal-mw,
    mw.add-js(common-js),
    mmw.mutant-layout(\layout, mutants),
    mw.private-site,
    handlers.forum


# XXX: TODO, FURL needs to take into account these cases so i can get rid of dependent
# hacky regexps:
# * /new/new
# * /t/ is a forum?
# * need to know about distinct state 'edit post'
# * need to know about distinct state 'new post'
#
# if the above is satisfied, then i can stop capturing below ()
# and stop using captured params in the handler itself
# instead furl will provide all i need..
# these regexps at that point will only serve to differentiate
# between running the personalize mw or not

# personal-mw so we can edit posts
  app.all new RegExp('^(.+)/t/([^/]+/edit/[^/]+)$'),
    personal-mw ++ [
      mw.add-js(common-js),
    ],
    mmw.mutant-layout(\layout, mutants),
    mw.private-site,
    handlers.forum

# forum + post depersonalized
  app.all new RegExp('^(.+)/t/(.+)$'),
    personal-mw,
    mw.add-js(common-js),
    mmw.mutant-layout(\layout, mutants),
    mw.private-site,
    handlers.forum

# personal-mw so we can create new posts
  app.all new RegExp('^(.+)/new$'),
    personal-mw ++ [
      mw.add-js(common-js),
    ],
    mmw.mutant-layout(\layout, mutants),
    mw.private-site,
    handlers.forum

# bare forum (catch all / depersonalized)
  app.all new RegExp('^(.+)$'),
    personal-mw,
    mw.add-js(common-js),
    mmw.mutant-layout(\layout, mutants),
    mw.private-site,
    handlers.forum

# vim:fdm=marker
