local fm = require "fullmoon"
local util = require "util"

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
        if not valid then
          table.insert(field.errors, error)
          field.has_errors = true
          self.valid = false
        end
      end
    end
  end
end

function Form:setFieldOptions(name, options)
  for _, field in ipairs(self.fields) do
    if field.name == name then
      field.options = options
    end
  end
end



function Form:__tostring()
    return util.dump(self)
end



