local fm = require "fullmoon"


Form = {
  bound = false,
  fieldDefs = nil,
  validator = nil,
  fields = nil,
  valid = false
}

function Form:new(o)
  o = o or {}
  self.__index = self
  setmetatable(o, self)
  if o.fieldDefs then
      o.fields = {}
      for _, fieldDef in ipairs(o.fieldDefs) do
        o.fields[fieldDef.name] = {value="nil", errors="nil"}
      end
  end
  o.bound = false
  o.valid = false
  return o
end

function Form:bind(params)
  for fieldName, fieldData in pairs(self.fields) do
    local paramValue = params[fieldName]
    if paramValue then
      fieldData.value = paramValue
    end
  end
  self.bound = true
end

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

function Form:validate(params)
  if self.bound == false then
    return
  end
  if self.validator then
    local valid, errors = self.validator(params)
    fm.logInfo(dump(errors))
    if valid then
      self.valid = true
    else 
      for fieldName, fieldData in pairs(self.fields) do
      fm.logInfo(fieldName)
          if errors[fieldName] then
              fieldData.errors = errors[fieldName]
          else
              fieldData.errors = {}
          end            
      end
      self.valid = false
    end
  end
end



function Form:__tostring()
    return dump(self)
end



