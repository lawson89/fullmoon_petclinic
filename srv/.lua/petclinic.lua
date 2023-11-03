
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
  return fm.serveContent("welcome")
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

        return fm.serveContent("owners/ownersList", {owners = owners})
     else
       return fm.serveContent("owners/findOwners", {})
     end
end

local function showOwner(r)
    if r.params.id then
        local dbconn = pc:dbconn()
        dbconn:query("select * from missing")
        local owner = assert(dbconn:queryOne("select * from owners where id=?", {r.params.id}))
        local pets = dbconn:query("select pets.id, pets.name, birth_date, types.name as type from pets, types where pets.type_id = types.id and pets.owner_id= ? order by      pets.name", {r.params.id})
        for _, pet in ipairs(pets) do
          local pet_id = pet.id
          local visits = assert(dbconn:query("select * from visits, pets where visits.pet_id=pets.id and pet_id = ? order by visit_date", {pet_id}))
          pet.visits = visits
        end

        if owner then
          return fm.serveContent("owners/ownerDetails", {owner = owner, pets = pets}) 
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
      local dbconn = pc:dbconn()
      local results = assert(dbconn:queryOne("insert into owners (first_name, last_name, address, city, telephone) values (?, ?, ?, ?, ?) returning id",
         {r.params.first_name, r.params.last_name, r.params.address, r.params.city, r.params.telephone}))
      local owner_id = results.id
      return fm.serveRedirect(303, "/owners/"..owner_id)   
    end
    return fm.serveContent("owners/createOrUpdateOwnerForm", {form=form})
  end
end


local function petForm()
    local form = Form:new({
    fields = {
        {name="name", label="Name", widget="text", validators = {{minlen=1, msg = "must not be empty"},{maxlen=64, msg="must be more than 64 characters"}}},
        {name="birth_date", label="Birth Date", widget="date", validators = {{minlen=1, msg = "please select a date"}}},
        {name="type_id", label="Type", widget="select", options={}, validators = {}}}
    })
    return form
end

local function editPet(r)
  local dbconn = pc:dbconn()
  local form = petForm()
  local typeOptions = assert(dbconn:query("select id as value, name as label from types order by name"))
  form:setFieldOptions('type_id', typeOptions)
  
  if r.method == 'GET' then
    local owner = assert(dbconn:queryOne("select * from owners where id=?", {r.params.id}))
    local pet = assert(dbconn:queryOne("select * from pets where id=?", {r.params.pet_id}))
    form:bind(pet)
  else
    form:bind(r.params)
    form:validate(r.params)
    if form.valid then
      -- todo this would be a lot cleaner with named sql placeholders
      -- then we could just pass the form and have it match up by name
      assert(dbconn:execute("update pets set name=?, birth_date=?, type_id=? where id=?",
        {r.params.name, r.params.birth_date, r.params.type_id, r.params.pet_id}))
      return fm.serveRedirect(303, "/owners/"..r.params.id)
    end
  end
  return fm.serveContent("pets/createOrUpdatePetForm", {form = form, owner=owner, action='edit'}) 
end

local function newPet(r)
  local dbconn = pc:dbconn()
  local form = petForm()
  local typeOptions = assert(dbconn:query("select id as value, name as label from types order by name"))
  form:setFieldOptions('type_id', typeOptions)
    
  if r.method == 'GET' then    
    local owner = assert(dbconn:queryOne("select * from owners where id=?", {r.params.id}))
  else
    form:bind(r.params)
    form:validate(r.params)
    fm.logInfo(util.dump(form))
    if form.valid then
      assert(pc:dbconn():execute("insert into pets (name, birth_date, type_id, owner_id) values (?, ?, ?, ?)",
         {r.params.name, r.params.birth_date, r.params.type_id, r.params.id}))
      return fm.serveRedirect(303, "/owners/"..r.params.id)   
    end
  end
  return fm.serveContent("pets/createOrUpdatePetForm", {form=form, owner=owner})
end

local function visitForm()
    local form = Form:new({
    fields = {
        {name="visit_date", label="Visit Date", widget="date", validators = {{minlen=1, msg = "please choose a visit date"}}},
        {name="description", label="Description", widget="text", validators = {{minlen=1, msg = "must not be empty"},{maxlen=64, msg="must be more than 256 characters"}}},
        }
    })
    return form
end

local function newVisit(r)
  local dbconn = pc:dbconn()
  local form = visitForm()
    
  local owner = assert(dbconn:queryOne("select * from owners where id=?", {r.params.id}))
  local pet = assert(dbconn:queryOne("select * from pets where id=?", {r.params.pet_id}))
  local visits = assert(dbconn:query("select * from visits, pets where visits.pet_id=pets.id and pet_id = ? order by visit_date", {r.params.pet_id}))
    
  if r.method == 'GET' then    
    return fm.serveContent("pets/createOrUpdateVisitForm", {form=form, owner=owner, pet=pet, visits=visits})
  else
    form:bind(r.params)
    form:validate(r.params)
    if form.valid then
      assert(pc:dbconn():execute("insert into visits (pet_id, visit_date, description) values (?, ?, ?)",
         {r.params.pet_id, r.params.visit_date, r.params.description}))
      return fm.serveRedirect(303, "/owners/"..r.params.id)   
    end
    return fm.serveContent("pets/createOrUpdateVisitForm", {form=form, owner=owner, pet=pet, visits=visits})
  end
end


local function vetList(r)
  local dbconn = pc:dbconn()
  local vets = assert(dbconn:query("select *, (select group_concat(name) from specialties, vet_specialties where vet_specialties.vet_id=vets.id and vet_specialties.specialty_id=specialties.id) as specialties from vets order by last_name"))
  return fm.serveContent("vets/vetList", {vets = vets}) 
end        


fm.setRoute("/owners/new", newOwner)
fm.setRoute(fm.GET "/owners/find", findOwners)
fm.setRoute(fm.GET "/owners/:id[%d]", showOwner)
fm.setRoute("/owners/:id[%d]/edit", editOwner)
fm.setRoute("/owners/:id[%d]/pets/new", newPet)
fm.setRoute("/owners/:id[%d]/pets/:pet_id[%d]/edit", editPet)
fm.setRoute("/owners/:id[%d]/pets/:pet_id[%d]/visits/new", newVisit)
fm.setRoute(fm.GET "/vets", vetList)
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
