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


-- register package path for fbmake modules
local scriptroot

do
	-- use path lib locally
	local path = dofile(arg[0]:match("(.+[\\/])%w+%.lua").."path.lua")

	scriptroot = path.dirname(path.normalize(arg[0]))
	
	--register package path
	package.path = package.path..path.join(scriptroot,"?.lua")..";"..path.join(scriptroot, "?.luac")..";"
end

require("fbmake_version")

local path = require("path")
local options = require("options")

-- register fbmake command options

options.registerCommand{
	name = {"help", "?", "h", }, 
	introduce = "Describe the usage of this program or its subcommands", 
	usage = "[SUBCOMMAND]",
	run = function()
		local subcmd =  options.getContents()[1]
		if (subcmd) then
			local cmd = options.getRegisteredCommand(subcmd)
			if (cmd) then
				return cmd:printHelp()
			else
				return print(string.format('"%s": unknown command.', subcmd))
			end
		else
			print("Type 'fbmake help <subcommand>' for help on a specific subcommand. ")
			print("Type 'fbmake version' to see the program version.")
			print()
			options.printHelp()
			print("FBMake is a tool for build.")
			print("For additional information, see http://github.com/tdzl2003/fbmake")
			print()
		end
	end,
	noConfigFile = true,
	hideInHelp = true,
}

options.registerCommand{
	name = {"version", "v", },
	introduce = "Print version of fbmake tool.",
	--usage = "",
	run = function()
		print(string.format("FBMake, version %s", _G.FBMAKE_VERSION))
		print("   Copyright (C) 2013, DengYun")
		print()
		print("FBMake is open source software, see http://github.com/tdzl2003/fbmake")
		print()
	end,
	noConfigFile = true,
	hideInHelp = true,
}

--TODO: load commands & extensions.
--TODO: localize
local configFiles = options.registerGlobalOption{
	name = {"config-file"},
	hasArg = true,
	multi = true,
	description = "read user configuation files from directory ARG",
}

-- parsing command line.
local command = options.parseCommandLine(arg)

if (command and not command.noConfigFile) then
	-- read config from config files
	configFiles:unregister()

	for i,v in ipairs(configFiles.values) do
		options.parseConfigFile(configFiles)
	end
end

if (not command) then
	print("Type 'fbmake help' for usage")
else
	return command:run()
end

