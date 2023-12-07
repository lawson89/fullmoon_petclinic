--
-- lightweight cross platform reloader for [Redbean web server](https://redbean.dev/)
-- Richard Lawson
--

-- ./redbean.com -i  -F reload.lua


DIRECTORY_TO_WATCH = './srv'
REDBEAN_TEMPLATE = 'redbean.template'
REDBEAN = 'redbean.com'
PIDFILE = 'redbean.pid'
LOGFILE = 'redbean.log'
ZIP = 'zip.com'
CHECK_INTERVAL = 1

mtime_table = {}

local function fileExists(fname)
  if unix.stat(fname) then
    return true
  else
    return false
  end
end


local function isRunning(pid)
  if unix.kill(pid, 0) then
    return true
  end
  return false    
end

local function getPid()
  return tonumber(Slurp(PIDFILE))
end

local function isRedbeanRunning()
  print("-- checking if redbean is running")
  if not fileExists(PIDFILE) then
    print(PIDFILE.." not not exist")
    return false
  end
  local pid = getPid()
  print(string.format("-- checking pid %s", pid))
  local running = isRunning(pid)
  print(string.format("-- %s running=%s", pid, running))
  return running
end

local function startRedbean()
  print("-- starting redbean")
  os.execute(string.format("./%s -vv -d -L %s -P %s", REDBEAN, LOGFILE, PIDFILE))
  if not isRedbeanRunning() then
    print(string.format("redbean is not running, please check %s, fix any issues and then redbean will restart", LOGFILE))
  end
end

local function stopRedbean()
  print('-- stopping redbean')
  if isRedbeanRunning() then    
    local pid = getPid()
    print(string.format("-- killing pid %s", pid))
    unix.kill(pid, unix.SIGTERM)
  end
  unix.unlink(PIDFILE)
end

local function nanoToMsElapsed(start_t)
  local _, end_t = unix.clock_gettime()
  return ((end_t - start_t) / 1000000)
end

local function buildRedbean()
  print("-- building app")
  local _, start_t = unix.clock_gettime()
  unix.unlink(REDBEAN)
  -- todo will need to detect if windows and modify commands
  local template = Slurp(REDBEAN_TEMPLATE)
  Barf(REDBEAN, template, 0700)
  -- os.execute(string.format("cp -f %s %s", REDBEAN_TEMPLATE, REDBEAN) )
  os.execute(string.format("cd srv/ && ../%s -r ../%s .", ZIP, REDBEAN))
  print(string.format("Build took %.2f ms", nanoToMsElapsed(start_t)))
end

local function onChange()
  stopRedbean()
  buildRedbean()
  startRedbean()
end

local function snapshot_dir(dir)
  local change_detected = false
  for name, kind, ino, off in assert(unix.opendir(dir)) do
      if name ~= '.' and name ~= '..' then
          local path = dir..'/'..name
          if kind == unix.DT_DIR then
            change_detected = change_detected or snapshot_dir(path)
          elseif kind == unix.DT_REG then
            local mtime = unix.stat(path):mtim()
            local old_mtime = mtime_table[path]
            if old_mtime == nil then
              -- first time we have seen file
            elseif mtime > old_mtime then
              change_detected = true            
            end
            mtime_table[path] = mtime
          else
            -- not a file or directory so skip
          end
      end
  end
  return change_detected
end


print(string.format('Watching for changes every %s seconds', CHECK_INTERVAL))
if isRedbeanRunning() then
  print("Redbean is running")
else
  print("Redbean is not running, attempting to launch")
  startRedbean()  
end
while(true)
do
  local _, start_t = unix.clock_gettime()
  local dir_changed = snapshot_dir(DIRECTORY_TO_WATCH)
  -- print(string.format("Directory scan took %.2f ms", nanoToMsElapsed(start_t)))
  if dir_changed then
    local status, retval = pcall(onChange)
    if not status then
      print("Error checking for changes, I'll keep checking though! " .. retval)
    end
  end
  unix.nanosleep(CHECK_INTERVAL)
end
