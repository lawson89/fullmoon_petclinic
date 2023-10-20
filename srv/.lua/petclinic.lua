-- framework setup
local fm = require "fullmoon"

-- set template folder and extensions
fm.setTemplate({ "/templates/", fmt = "fmt" })

-- set static assets
fm.setRoute("/*", "/assets/*")

-- set routes and handlers
fm.setRoute(fm.GET "/", fm.serveContent("index", { name = 'rick' }))

-- start the app
fm.run()