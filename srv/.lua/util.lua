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

return {
  dump = dump,
  split = split,
  fileToString = fileToString,
  trim = trim,
  sqlFileToList = sqlFileToList  
}