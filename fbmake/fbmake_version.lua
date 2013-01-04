
_G.FBMAKE_VERSION_MAJOR = 0
_G.FBMAKE_VERSION_MINOR = 2
_G.FBMAKE_VERSION_PATCH = 0

_G.FBMAKE_VERSION = FBMAKE_VERSION_MAJOR .. '.' .. FBMAKE_VERSION_MINOR .. '.' .. FBMAKE_VERSION_PATCH 

function _G.require_fbmake_version(maj, min, patch)
	patch = patch or 0
	if type(maj) == 'string' then
		local v = maj:split('.', true)
		maj = tonumber(v[1])
		min = tonumber(v[2])
		if (#v >= 3) then
			patch = tonumber(v[3])
		end
	end
	if (maj > FBMAKE_VERSION_MAJOR or
			(maj == FBMAKE_VERSION_MAJOR and min > FBMAKE_VERSION_MINOR) or
			(maj == FBMAKE_VERSION_MAJOR and min == FBMAKE_VERSION_MINOR and patch > FBMAKE_VERSION_PATCH)) then
		error("FBMake version " .. FBMAKE_VERSION ..
			' is lower than required version ' .. maj ..'.' .. min .. '.' .. patch
		)
	end
end
