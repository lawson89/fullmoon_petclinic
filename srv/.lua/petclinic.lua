
-- framework setup
local fm = require "fullmoon"

-- set template folder and extensions
fm.setTemplate({ "/templates/", fmt = "fmt" })

-- set static assets
fm.setRoute("/*", "/assets/*")

-- set routes and handlers
fm.setRoute(fm.GET "/", fm.serveContent("welcome", { name = 'rick' }))

local function run(port)
    -- start the app
    fm.run({ port = port or 8000 })
end

local pc = {
    run = run
}

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
local function initDb()
    fm.logInfo("Initializing database")
    fm.logInfo("Loading schema sql")
    local dbm = fm.makeStorage(DBNAME)
    runSqlInFile("./db/schema.sql", dbm)
    fm.logInfo("Loading data sql")
    runSqlInFile("./db/data.sql", dbm)
    pc.dbm = dbm
end

pc.initDb = initDb
return pc