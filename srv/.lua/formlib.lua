local fm = require "fullmoon"

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

Form = {bound = false, valid = false}

function Form:new(o)
  o = o or {}
  self.__index = self
  setmetatable(o, self)
  -- initial values
  o.fields = o.fields or {}
  -- validator - add field name
  for _, field in ipairs(o.fields) do   
    field.errors = {}
    field.has_errors = false
    if field.validators then
      for _, validatorExpr in ipairs(field.validators) do        
        validatorExpr[1]=field.name        
      end
    end
  end
  return o
end

function Form:bind(params)
  for _, field in ipairs(self.fields) do
    local paramValue = params[field.name]
    if paramValue then
      field.value = paramValue
    end
  end
  self.bound = true
end


function Form:validate(params)
  if self.bound == false then
    return
  end
  self.valid = true
  for _, field in ipairs(self.fields) do
    -- run validators for each field
    if field.validators then
      for _, validatorExpr in ipairs(field.validators) do
        local validator = fm.makeValidator({validatorExpr})
        local valid, error = validator(params)
        fm.logInfo(string.format("valid=%s", valid))
        fm.logInfo(string.format("error=%s", error))
        if not valid then
          table.insert(field.errors, error)
          field.has_errors = true
          self.valid = false
        end
      end
    end
  end
end



function Form:__tostring()
    return dump(self)
end



