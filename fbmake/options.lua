-- NOTICE:
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
-- POSSIBILITY OF SUCH DAMAGE.
-- 
-- read LICENSE.md for more informations.

local options = {}
_G.options = options


local function find(t, val)
	for i,v in ipairs(t) do
		if (v == val) then
			return i
		end
	end
end

local function removeVal(t, val)
	local pos = find(t, val)
	return pos and table.remove(t, pos)
end

------------------------------------------------------
-- Command type
------------------------------------------------------
local commands = {}
local commandRegisters = {}

local Command = {}
local CommandMT = {
	name = "options.Command",
	__index = Command,
}
options.Command = CommandMT

-- default field values of command.
Command.introduce = ""
Command.usage = ""
function Command:run()
end

function Command:register()
	if (self.registered) then
		return self
	end

	table.insert(commands, self)
	for i,v in ipairs(self.name) do
		commandRegisters[v] = 
			(commandRegisters[v] and error("Duplicated command name" .. v))
			or self
	end

	self.registered = true
	return self
end

function Command:unregister()
	if (not self.registered) then
		return self
	end

	removeVal(commands, self)
	for i,v in ipairs(self.name) do
		commandRegisters[v] = nil
	end
	self.registered = nil
	return self
end

function Command:registerOption(opt)
	if (not find(self.options, opt)) then
		table.insert(self.options, opt)
	end
end

function Command:unregisterOption(opt)
	removeVal(self.options, opt)
end

------------------------------------------------------
-- Option type
------------------------------------------------------
local globalOptions = {}
local optionRegisters = {}

local Option = {}
local OptionMT = {
	name = "options.Option",
	__index = Option,
}
options.Option = OptionMT

-- default field values of command.
Option.description = "(No description)"

function Option:trigger(val)
	if (self.multi) then
		self.values = self.values or {}
		self.value = self.value or val
		table.insert(self.values, val)
	elseif (self.hasArg) then
		self.value = val or self.value
	end
end

function Option:register()
	if (self.registered) then
		return
	end
	for i,v in ipairs(self.name) do
		optionRegisters[v] = 
			(optionRegisters[v] and error("Duplicated option name" .. v))
			or self
	end

	self.registered = true
	return self
end

function Option:unregister()
	if (not self.registered) then
		return
	end

	for i,v in ipairs(self.name) do
		optionRegisters[v] = nil
	end
	self.registered = nil
	return self
end

function Option:registerGlobal()
	if (not self.globalRegistered) then
		table.insert(globalOptions, self)
		self.globalRegistered = true
	end
	return self
end

function Option:unregisterGlobal()
	if (self.globalRegistered) then
		removeVal(globalOptions, self)
		self.globalRegistered = nil
	end
	return self
end

------------------------------------------------------
-- options package functions
------------------------------------------------------
local function _initNameArgs(args)
	assert(args.name, "Command must have at least one name!")
	if (type(args.name) == 'table') then
		assert(#args.name > 0, "Command must have at least one name!")
	else
		args.name = {tostring(args.name)}
	end
end

function options.registerCommand(args)
	_initNameArgs(args)
	args.options = args.options or {}
	setmetatable(args, CommandMT)
	return args:register()
end

function options.registerGlobalOption(args)
	_initNameArgs(args)
	setmetatable(args, OptionMT)
	return args:registerGlobal():register()
end

function options.getRegisteredCommand(cmd)
	return commandRegisters[cmd]
end

local contents = {}

function options.getContents()
	return contents
end

local function untranslateCmd(c)
	return 
		c:match("%-%-([%w%.%-%_]+)")
		or c:match("%-(%w)")
		or c
end

local function translateCmd(c)
	return c
end

local function untranslateOption(c)
	return 
		c:match("%-%-([%w%.%-%_]+)") or 
		c:match("%-(%w)")
end

local function translateOption(c)
	if (#c == 1) then
		return '-'..c
	end
	return '--'..c
end

function options.parseCommandLine(args)
	local cmdName = args[1]
	local ret = cmdName and commandRegisters[untranslateCmd(cmdName)]

	if (ret) then
		for k,v in ipairs(ret.options) do
			v:register()
		end

		local i = 2

		while (i<=#args) do
			local arg = args[i]
			local optname = untranslateOption(arg)

			if (optname) then
				local opt = optionRegisters[optname]
				if (opt) then
					if (opt.hasArg or opt.multi) then
						i = i+1
						opt:trigger(args[i])
					else
						opt:trigger()
					end
				else
					print(string.format("Warning: ignored unknown option '%s'", arg))
				end
			else
				table.insert(contents, arg)
			end

			i = i+1
		end
	end


	return ret
end

function options.parseConfigFile(fn)
	local fd = io.open(fn)
	local lineno = 0
	local namespace = ""

	for s in fd:lines() do
		lineno = lineno + 1
		local ns = s:match("%[([^%]]+)%]")
		if (ns) then
			namespace = ns
		else
			local k,v = s:match("([%w%.%-%_]+)%s%=(.*)")
			if k then
				local optname = namespace..'.'..k
				local opt = optionRegisters[optname]
				if (opt) then
					if (opt.hasArg or opt.multi) then
						opt:trigger(v)
					else
						opt:trigger()
					end
				else
					print(string.format(
						"%s(%d): Warning: ignored unknown option '%s'", 
						fn,
						lineno,
						optname))
				end
			elseif (s~= "") then
				table.insert(contents, v)
			end
		end
	end
	fd:close()
end

------------------------------------------------------
-- help functions
------------------------------------------------------

local function constructDesc(desc, prefix)
	prefix = prefix or ''
	if (type(desc) == 'table') then
		return prefix..table.concat(desc, '\n'..prefix)
	elseif (desc) then
		return prefix..desc
	else
		return ""
	end
end

local function constructName(name)
	local out = {translateCmd(name[1])}
	if (#name > 1) then
		local c = ' ('
		for i = 2, #name do
			table.insert(out, c)
			c = ', '
			table.insert(out, translateCmd(name[i]))
		end
		table.insert(out, ')')
	end
	return table.concat(out)
end

function Command:printHelp()
	print(constructName(self.name)..": "..constructDesc(self.introduce))
	print("usage: fbmake "..self.name[1].." " .. self.usage)
	print()
	if (self.description) then
		print(constructDesc(self.description))
	end

	if (#self.options >= 1) then
		print("Valid options:")

		for i,v in ipairs(self.options) do
			v:printDesciption()
		end
		print()
	end

	if (#globalOptions >= 1) then
		print("Global options:")
		for i,v in ipairs(globalOptions) do
			v:printDesciption()
		end
		print()
	end

end

function Option:printDesciption()
	for i,v in ipairs(self.name) do
		local out = {}
		table.insert(out, '  ')
		table.insert(out, translateOption(v))
		if (self.hasArg) then
			table.insert(out, ' ARG')
		end
		table.insert(out, " :")
		print(table.concat(out))
	end

	print(constructDesc(self.description, '\t'))
end

function options.printHelp()
	print("Available subcommands:")
	for i,v in ipairs(commands) do
		if (not v.hideInHelp) then
			print('   ' .. constructName(v.name))
			print(constructDesc(v.introduce, '\t'))
		end
	end
	print()
end


return options
