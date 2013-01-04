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
Command.description = "(No description)"
Command.usage = ""
function Command:run()
end

function Command:register()
	if (self.registered) then
		return
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
		return
	end

	removeVal(commands, self)
	for i,v in ipairs(self.name) do
		commandRegisters[v] = nil
	end
	self.registered = false
	return self
end

function Command:printHelp()
end

------------------------------------------------------
-- Option type
------------------------------------------------------
local globalOptions = {}
local globalOptionRegisters = {}

local Option = {}
local OptionMT = {
	name = "options.Option",
	__index = Option,
}
options.Option = OptionMT

-- default field values of command.
Option.description = "(No description)"

function Option:trigger(val)
end

function Option:registerGlobal()
	if (self.registered) then
		return
	end

	table.insert(globalOptions, self)
	for i,v in ipairs(self.name) do
		globalOptionRegisters[v] = 
			(globalOptionRegisters[v] and error("Duplicated command name" .. v))
			or self
	end

	self.registered = true
	return self
end

function Option:unregisterGlobal()
	if (not self.registered) then
		return
	end

	removeVal(globalOptions, self)
	for i,v in ipairs(self.name) do
		globalOptionRegisters[v] = nil
	end
	self.registered = false
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
	return args:registerGlobal()
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
		c:match("%-(%w)")
		or c:match("%-%-(%w+)")
		or c
end

local function translateCmd(c)
	if (#c == 1) then
		return '-'..c
	end
	return c
end

function options.parseCommandLine(args)
	local cmdName = args[1]
	return cmdName and commandRegisters[untranslateCmd(cmdName)]
end

function options.parseConfigFile(args)
end

function options.printHelp()
	print("Available subcommands:")
	for i,v in ipairs(commands) do
		local out = {'   ', translateCmd(v.name[1])}
		if (#v.name > 1) then
			local c = ' ('
			for i = 2, #v.name do
				table.insert(out, c)
				c = ', '
				table.insert(out, translateCmd(v.name[i]))
			end
			table.insert(out, ')')
		end
		print(table.concat(out))
		print("\t"..v.description)
	end
end


return options
