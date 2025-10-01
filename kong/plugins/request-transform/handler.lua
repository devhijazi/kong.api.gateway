-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--assert(ngx.get_phase() == "timer", "The world is coming to an end!")

---------------------------------------------------------------------------------------------
-- In the code below, just remove the opening brackets; `[[` to enable a specific handler
--
-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.
---------------------------------------------------------------------------------------------
local redis = require 'redis'

local plugin = {
  PRIORITY = 1000, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1", -- version in X.Y.Z format. Check hybrid-mode compatibility requirements.
}

local params = {
  host = '',
  port = 6379
}

local client = redis.connect(params)

function plugin:init_worker()
  kong.log.debug("saying hi from the 'init_worker' handler")
end --]]

function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end


function plugin:access(plugin_conf)
  local purePath = kong.request.get_path()
  local acessToken = kong.request.get_header('x-access-token')

  local path = {}
  for match in (purePath.."/"):gmatch("(.-)".."/") do
    table.insert(path, match)
  end

  local applicationName = string.format('%s-%s', path[3], path[2])
  kong.log.debug("applicationName")
  print(applicationName)

  -- ========================================
  local getPermission = getSecret(acessToken)

  if getPermission == nil then
    kong.response.set_status(401)
    kong.response.set_header('Content-Type', 'application/json')
    return kong.response.error(401, "Not Authorized")
  end

  local permissions = {}
  for permission in (getPermission.."|"):gmatch("(.-)".."|") do
    table.insert(permissions, permission)
  end

  -- ========================================

  local items = Set(permissions)

  if items[applicationName] == nil then
    kong.response.set_status(403)
    kong.response.set_header('Content-Type', 'application/json')
    return kong.response.error(403, "Access Forbidden")
  end

end

function getSecret(token)
  if token == nil then
    return nil
  end

  local value = client:get(token)
  return value
end

return plugin