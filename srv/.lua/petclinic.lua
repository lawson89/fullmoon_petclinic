
-- framework setup
local fm = require "fullmoon"

-- set template folder and extensions
fm.setTemplate({ "/templates/", fmt = "fmt" })

local pc = {}

-- utility functions
function dump(o)
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

local new_owner_validator = fm.makeValidator({
        {"firstName", minlen=5, maxlen=64, msg = "Invalid %s format"},
        all = true,
        key = true
    })

local function new_owner(r)
    fm.logInfo(r.method)
    if r.method == 'GET' then
        return fm.serveContent("owners/createOrUpdateOwnerForm", {})
    else
        fm.logInfo(string.format("%s", dump(r.params)))
        local valid, error = new_owner_validator(r.params)
        fm.logInfo(string.format("%s", valid))
        fm.logInfo(string.format("%s", dump(error)))
        if valid then
            assert(pc.dbm:execute("insert into owners (first_name, last_name, address, city, telephone) values (?, ?, ?, ?, ?)",
                r.params.firstName, r.params.lastName, r.params.address, r.params.city, r.params.telephone))
            return fm.serveRedirect("owners/find")   
        end
        return fm.serveContent("owners/createOrUpdateOwnerForm", {})
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


-- split("a,b,c", ",") => {"a", "b", "c"}
local function split(s, sep)
    local fields = {}

    local sep = sep or " "
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)

    return fields
end


local function fileToString(fname)
    local file = io.open( fname, "r" )
    local contents = file:read( "a" )
    file:close()
    return contents
end

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function sqlFileToList(fname)
    local allSql = fileToString(fname)
    local sqlList = split(allSql, ";")
    sqlListClean = {}
    for _, sql in ipairs(sqlList) do
        sql = trim(sql)
        if #sql > 1 then
            table.insert(sqlListClean, sql)
        end
    end
    return sqlListClean
end

local function runSqlInFile(fname, dbm)
    local sqlList = sqlFileToList(fname)
    for _, sql in ipairs(sqlList) do
        fm.logInfo(string.format("Executing: %s", sql))
        local changes = dbm:execute(sql)
        fm.logInfo(string.format("row(s) changed: %s", changes))
    end
end

local DBNAME = 'fullmoon_petclinic.db'
function pc:initDb()
    fm.logInfo("Initializing database")
    fm.logInfo("Loading schema sql")
    local dbm = fm.makeStorage(DBNAME)
    runSqlInFile("./db/schema.sql", dbm)
    fm.logInfo("Loading data sql")
    runSqlInFile("./db/data.sql", dbm)
    self.dbm = dbm
end

return pc
