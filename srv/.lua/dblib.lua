local fm = require "fullmoon"

Dbconn = {}

function Dbconn:new(o)
  fm.logInfo("creating new dbconn")
  o = o or {}
  self.__index = self
  fm.logInfo("setting metatable")
  setmetatable(o, self)
  -- initial values
  if not o.dbm then
    error("database connection must be provided")
  end
  self.dbm = o.dbm
  fm.logInfo("done")
  return o
end

function Dbconn:execute(sql, parms)
        fm.logInfo(string.format("Executing: %s", sql))
        local changes
        if parms then
          changes = self.dbm:execute(sql, tables.unpack(parms))
        else
          changes = self.dbm:execute(sql)
        end
        fm.logInfo(string.format("row(s) changed: %s", changes))    
        return changes
end

function Dbconn:query(sql, parms)
        fm.logInfo(string.format("Executing: %s", sql))
        local changes
        if parms then
          changes = self.dbm:fetchAll(sql, tables.unpack(parms))
        else
          changes = self.dbm:fetchAll(sql)
        end
        fm.logInfo(string.format("row(s) changed: %s", changes))    
        return changes
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
    local sqlListClean = {}
    for _, sql in ipairs(sqlList) do
        sql = trim(sql)
        if #sql > 1 then
            table.insert(sqlListClean, sql)
        end
    end
    return sqlListClean
end

function Dbconn:runSqlInFile(fname)
    local sqlList = sqlFileToList(fname)
    for _, sql in ipairs(sqlList) do
        fm.logInfo(string.format("Executing: %s", sql))
        local changes = self:execute(sql)
        fm.logInfo(string.format("row(s) changed: %s", changes))
    end
end
