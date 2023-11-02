
-- framework setup
local fm = require "fullmoon"

-- local setup
require "formlib"
require "dblib"
local util = require "util"

-- set template folder and extensions
fm.setTemplate({ "/templates/", fmt = "fmt" })

local pc = {}

-- set routes and handlers
local function welcome(r)
  return fm.serveContent("welcome", {})
end

local function showError(r)
  error("bogus!")  
end


local function findOwners(r)
    if r.params.lastName then
        local dbconn = pc:dbconn()
        local owners = assert(dbconn:query("select *, (select group_concat(name) from pets where pets.owner_id=owners.id) as pets from owners where last_name LIKE ? order by last_name",
            {r.params.lastName.."%"}))

        fm.logInfo(string.format("Rows: %s", #owners))

        -- the resulting rows are key-value pair with the column as the key
        return fm.serveContent("owners/ownersList", {owners = owners})
     else
       return fm.serveContent("owners/findOwners", {})
     end
end

local function showOwner(r)
    if r.params.id then
        local dbconn = pc:dbconn()
        local owner = assert(dbconn:queryOne("select * from owners where id=?", {r.params.id}))
        if owner then
          return fm.serveContent("owners/ownerDetails", {owner = owner}) 
        end
    end
    return fm.serveRedirect(303, "/oops")
end

local function ownerForm()
    local form = Form:new({
    fields = {
        {name="first_name", label="First Name", widget="text", validators = {{minlen=1, msg = "must not be empty"},{maxlen=64, msg="must be more than 64 characters"}}},
        {name="last_name", label="Last Name", widget="text", validators = {{minlen=1, msg = "must not be empty"},{maxlen=64, msg="must be more than 64 characters"}}},
        {name="address", label="Address", widget="text", validators = {{minlen=1, msg = "must not be empty"},{maxlen=256, msg="must be more than 256 characters"}}},
        {name="city", label="City", widget="text", validators = {{minlen=1, msg = "must not be empty"},{maxlen=64, msg="must be less than 64 characters"}}},
        {name="telephone", label="Telephone", widget="text", validators = {{minlen=1, msg = "must not be empty"},
            {pattern="%d%d%d%d%d%d%d%d%d%d", msg="must be 10 digits  with no spaces or punctuation"}}}}
    })
    return form
end

local function editOwner(r)
  local dbconn = pc:dbconn()
  local form = ownerForm()
  
  if r.method == 'GET' then
    local owner = assert(dbconn:queryOne("select * from owners where id=?", {r.params.id}))
    form:bind(owner)
    return fm.serveContent("owners/createOrUpdateOwnerForm", {form = form, action='edit'}) 
  else
    form:bind(r.params)
    form:validate(r.params)
    fm.logInfo(util.dump(form))
    if form.valid then
      -- todo this would be a lot cleaner with named sql placeholders
      -- then we could just pass the form and have it match up by name
      assert(dbconn:execute("update owners set first_name=?, last_name=?, address=?, city=?, telephone=? where id=?",
        {r.params.first_name, r.params.last_name, r.params.address, r.params.city, r.params.telephone, r.params.id}))
    end
    return fm.serveRedirect(303, "/owners/"..r.params.id)
  end
end


local function newOwner(r)
  local form = ownerForm()
    
  if r.method == 'GET' then
    return fm.serveContent("owners/createOrUpdateOwnerForm", {form=form})
  else
    form:bind(r.params)
    form:validate(r.params)
    if form.valid then
      assert(pc:dbconn():execute("insert into owners (first_name, last_name, address, city, telephone) values (?, ?, ?, ?, ?)",
         {r.params.firstName, r.params.lastName, r.params.address, r.params.city, r.params.telephone}))
      return fm.serveRedirect(303, "/owners/find")   
    end
    return fm.serveContent("owners/createOrUpdateOwnerForm", {form=form})
  end
end

fm.setRoute("/owners/new", newOwner)
fm.setRoute(fm.GET "/owners/find", findOwners)
fm.setRoute(fm.GET "/owners/:id[%d]", showOwner)
fm.setRoute("/owners/:id[%d]/edit", editOwner)
fm.setRoute(fm.GET "/", welcome)
fm.setRoute(fm.GET "/oops", showError)

-- set static assets
fm.setRoute("/*", "/assets/*")

function pc.run(port)
    -- start the app
    fm.run({ port = port or 8000 })
end

local DBNAME = 'fullmoon_petclinic.db'
function pc:initDb()
    fm.logInfo("Initializing database")
    local dbm = fm.makeStorage(DBNAME)
    self.dbm = dbm
    local dbconn = self:dbconn()
    dbconn:runSqlInFile("./db/schema.sql")
    dbconn:runSqlInFile("./db/data.sql")

end

function pc:dbconn()
  return Dbconn:new({dbm = self.dbm})
end

return pc
