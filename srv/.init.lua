if MDB then MDB.on() end -- only needed when debugging .init.lua code
print(package.path)
package.path=package.path..";/zip/.lua/?.lua"
print(package.path)
print(debug.getinfo(1,"S").source)

pc = require "petclinic"

pc:initDb()
pc.run(8000)

