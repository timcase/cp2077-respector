local mod = {
	baseDir = string.gsub(({...})[2], '/+mod/mod%.lua$', ''):gsub('\\', '/') .. '/',
	config = {},
	loaded = {},
	deferred = {},
	dev = false,
	debug = false,
}

function mod.init(devMode, debugMode)
	mod.loadConfig()

	mod.dev = devMode
	mod.debug = debugMode

	if mod.dev or mod.debug then
		mod.dbg = mod.require('mod/utils/debug')
	end
end

function mod.dir(path)
	local result = path

	if not result:find('[\\/]$') then
		result = result .. '/'
	end

	if not result:find('^[./]') and not result:find('^%a:') then
		result = mod.baseDir .. result
	end

	--if mod.debug then
	--	print(('[DEBUG] Respector: Resolved dir %q to %q.'):format(path, result))
	--end

	return result
end

function mod.path(path)
	local result = path

	if not result:find('%.(%w+)$') then
		result = result .. '.lua'
	end

	if not result:find('^[./]') and not result:find('^%a:') then
		result = mod.baseDir .. result
	end

	--if mod.debug then
	--	print(('[DEBUG] Respector: Resolved path %q to %q.'):format(path, result))
	--end
	
	return result
end

function mod.load(path)
	--return dofile(mod.path(path))
	return (loadfile(mod.path(path)))(mod)
end

function mod.load(path)
	return (loadfile(mod.path(path)))(mod)
end

function mod.require(path)
	--return require(mod.baseDir ..path)

	if not mod.loaded[path] then
		mod.loaded[path] = (loadfile(mod.path(path)))(mod)
	end

	return mod.loaded[path]
end

function mod.defer(delay, callback)
	if callback then
		table.insert(mod.deferred, {
			delay = delay,
			callback = callback
		})

	elseif #mod.deferred > 0 and delay then
		for i, deferred in ipairs(mod.deferred) do
			deferred.delay = deferred.delay - delay

			if deferred.delay <= 0 then
				table.remove(mod.deferred, i)
				deferred.callback()
			end
		end
	end
end

function mod.loadConfig()
	mod.config = mod.load('config') or {}
end

function mod.onUpdate(delta)
	if #mod.deferred > 0 then
		mod.defer(delta)
	end
end

return mod