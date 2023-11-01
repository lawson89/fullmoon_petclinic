local fm = require "fullmoon"

local util = require "util"

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


function Dbconn:runSqlInFile(fname)
    fm.logInfo(string.format("Running sql in file: %s", fname))
    local sqlList = util.sqlFileToList(fname)
    for _, sql in ipairs(sqlList) do
        self:execute(sql)
    end
end
