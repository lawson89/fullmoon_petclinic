
-- framework setup
local fm = require "fullmoon"

-- local setup
local formlib = require "formlib"
local dblib = require "dblib"

-- set template folder and extensions
fm.setTemplate({ "/templates/", fmt = "fmt" })

local pc = {}

-- utility functions
-- https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console
local function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end


-- set routes and handlers
local function welcome(r)
    return fm.serveContent("welcome", { name = 'rick' })
end

local function find_owners(r)
    if r.params.lastName then
        local result = assert(pc.dbm:fetchAll([[
            SELECT *
            FROM owners
            where last_name LIKE ? order by last_name]],r.params.lastName.."%"))

        fm.logInfo(string.format("Rows: %s", #result))

        -- the resulting rows are key-value pair with the column as the key
        return fm.serveContent("owners/ownersList", {owners = result})
     else
       return fm.serveContent("owners/findOwners", {})
     end
end


local function new_owner(r)
  local form = Form:new({
    fields = {
        {name="firstName", label="First Name", widget="text", validators = {{minlen=1, msg = "must not be empty"},{maxlen=64, msg="must be more than 64 characters"}}},
        {name="lastName", label="Last Name", widget="text", validators = {{minlen=1, msg = "must not be empty"},{maxlen=64, msg="must be more than 64 characters"}}},
        {name="address", label="Address", widget="text", validators = {{minlen=1, msg = "must not be empty"},{maxlen=256, msg="must be more than 256 characters"}}},
        {name="city", label="City", widget="text", validators = {{minlen=1, msg = "must not be empty"},{maxlen=64, msg="must be less than 64 characters"}}},
        {name="telephone", label="Telephone", widget="text", validators = {{minlen=1, msg = "must not be empty"},
            {pattern="%d%d%d%d%d%d%d%d%d%d", msg="must be 10 digits  with no spaces or punctuation"}}}}
  })
    
  if r.method == 'GET' then
    return fm.serveContent("owners/createOrUpdateOwnerForm", {form=form})
  else
    fm.logInfo(string.format("form = %s", form))
    form:bind(r.params)
    form:validate(r.params)
    fm.logInfo(string.format("form = %s", form))
    if form.valid then
      assert(pc.dbm:execute("insert into owners (first_name, last_name, address, city, telephone) values (?, ?, ?, ?, ?)",
         r.params.firstName, r.params.lastName, r.params.address, r.params.city, r.params.telephone))
      return fm.serveRedirect(303, "/owners/find")   
    end
    return fm.serveContent("owners/createOrUpdateOwnerForm", {form=form})
  end
end

fm.setRoute("/owners/new", new_owner)
fm.setRoute(fm.GET "/owners/find", find_owners)
fm.setRoute(fm.GET "/", welcome)

-- set static assets
fm.setRoute("/*", "/assets/*")

function pc.run(port)
    -- start the app
    fm.run({ port = port or 8000 })
end

local DBNAME = 'fullmoon_petclinic.db'
function pc:initDb()
    fm.logInfo("Initializing database")
    fm.logInfo("Loading schema sql")
    local dbm = fm.makeStorage(DBNAME)
    local dbconn = Dbconn:new({dbm = dbm})
    fm.logInfo("created dbconnection")
    dbconn:runSqlInFile("./db/schema.sql")
--    fm.logInfo("Loading data sql")
--    dbconn:runSqlInFile("./db/data.sql")
    self.dbm = dbm
end

return pc
