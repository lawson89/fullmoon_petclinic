local fm = require "fullmoon"


Form = {}

function Form:new(o)
  o = o or {}
  self.__index = self
  setmetatable(o, self)
  -- initial values
  o.bound = false
  o.valid = false
  if o.fieldDefs then
      o.fields = {}
      for _, fieldDef in ipairs(o.fieldDefs) do
        o.fields[fieldDef.name] = fieldDef
      end
  end
  return o
end

function Form:bind(params)
  for fieldName, field in pairs(self.fields) do
    local paramValue = params[fieldName]
    if paramValue then
      field.value = paramValue
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
    if valid then
      self.valid = true
    else 
      for fieldName, field in pairs(self.fields) do
      fm.logInfo(fieldName)
          if errors[fieldName] then
              field.errors = {errors[fieldName]}
              field.has_errors = true
          else
              field.errors = {}
              field.has_errors = false
          end            
      end
      self.valid = false
    end
  end
end



function Form:__tostring()
    return dump(self)
end



