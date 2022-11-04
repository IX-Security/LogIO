local MAX_LOG_STACK_SIZE = 100

type logObject = {
	debug: () -> nil,
	log: () -> nil,
	warn: () -> nil,
	error: () -> nil,
	critical: () -> nil,

	setLogLevel: () -> nil,
	setProperty: () -> nil
}

type logSettings = {
	format: string,
	errorFormat: string,
	level: number,

	properties: {
		expandTables: boolean,
		exposeTableNames: boolean,
		useNewLines: boolean,
		useTabs: boolean,
		removeFileEndings: boolean,

		bytes: {
			tab: string,
			space: string,

			prefix: string
		}
	}
}

local LogIO = { }

local loggersLookup = { }
local tableLookup = { }

LogIO.defaultPattern = "[%s][%s]%s: %s"
LogIO.defaultErrorPattern = "[%s:%d]"
LogIO.defaultLevel = 1

LogIO.ansiForegroundColors, LogIO.ansiAttributes, LogIO.ansiReset = {
	["black"] = 30,
	["red"] = 31,
	["green"] = 32,
	["yellow"] = 33,
	["blue"] = 34,
	["magenta"] = 35,
	["cyan"] = 36,
	["white"] = 37,
}, {
	["bright"] = 1,
	["dim"] = 2,
	["underline"] = 4,
	["blink"] = 5,
	["reverse"] = 7,
	["hidden"] = 8,
}, 0

LogIO.deafaultPrototypes = {
	["debug"] = {
		level = 1,
		foreground = LogIO.ansiForegroundColors.magenta
	},
	["log"] = {
		level = 2,
		foreground = LogIO.ansiForegroundColors.blue
	},
	["warn"] = {
		level = 3,
		foreground = LogIO.ansiForegroundColors.yellow
	},
	["error"] = {
		level = 4,
		closeThread = true,
		foreground = LogIO.ansiForegroundColors.red
	},
	["critical"] = {
		level = 5,
		closeThread = true,
		foreground = LogIO.ansiForegroundColors.red
	}
}

LogIO.defaultProperties = {
	expandTables = true,
	exposeTableNames = false,
	useNewLines = true,
	useTabs = false,

	removeFileEndings = true,

	bytes = {
		tab = "\9",
		space = "\32",

		prefix = "\27"
	}
}

function LogIO:_formatTable(tableObject, scope)
	local tableSource = (self.properties.exposeTableNames and tostring(tableObject) .. " {") or "{"
	local tableTrueIndex = 0

	if tableLookup[tableObject] then
		return (self.properties.exposeTableNames and tostring(tableObject)) or string.format("Ref< -%d > { ... }", scope - tableLookup[tableObject])
	else
		tableLookup[tableObject] = scope or 1
	end

	if not self.properties.expandTables then
		return tableSource .. " }"
	end

	for index, value in tableObject do
		local typeIndex, typeValue = type(index), type(value)

		index = (typeIndex == "table" and self:_formatTable(index, (scope and scope + 1) or 2)) or tostring(index)
		value = (typeValue == "table" and self:_formatTable(value, (scope and scope + 1) or 2)) or tostring(value)

		if tableTrueIndex == 0 and self.properties.useNewLines then
			tableSource ..= "\n"
		end

		tableTrueIndex += 1
		tableSource ..= string.format(
			"%s[%s] = %s,%s",

			string.rep((self.properties.useTabs and self.properties.bytes.tab) or self.properties.bytes.space, (scope and scope) or 1),
			(typeIndex == "string" and string.format("\"%s\"", index)) or index,
			(typeValue == "string" and string.format("\"%s\"", value)) or value,
			(self.properties.useNewLines and "\n") or " "
		)
	end

	return tableSource .. string.format("%s}", string.rep((self.properties.useTabs and self.properties.bytes.tab) or self.properties.bytes.space, ((scope and scope) or 1) - 1))
end

function LogIO:_toString(...)
	local source = ""

	for _, value in { ... } do
		local typeOfValue = type(value)

		if typeOfValue == "table" then
			source ..= self:_formatTable(value)
		else
			source ..= tostring(value)
		end
	end

	tableLookup = { }

	return source
end

function LogIO:_setAnsiColor(message, ansiColor)
	local terminalCommandColor = string.format("%s[%dm", self.properties.bytes.prefix, ansiColor)
	local terminalCommandReset = string.format("%s[%dm", self.properties.bytes.prefix, LogIO.ansiReset)

	return string.format("%s%s%s", terminalCommandColor, message, terminalCommandReset)
end

function LogIO:_addToStack(object)
	if #self.logStack + 1 > MAX_LOG_STACK_SIZE then
		table.remove(self.logStack, 1)
	end

	table.insert(self.logStack, object)
end

function LogIO:_loadPrototype(prototypeIndex, prototypeData)
	self[prototypeIndex] = function(_, ...)
		local message = self:_toString(...)

		self:_addToStack({
			message = message,
		})

		if prototypeData.level >= self.level then
			message = string.format(self.format, self.logName, prototypeIndex, "%s", message)
			message = self:_setAnsiColor(message, prototypeData.foreground)

			if prototypeData.closeThread then
				local source, line = debug.info(2, "sl")
				source = string.split(source, "/")
				source = source[#source]

				if self.properties.removeFileEndings then
					for _, fileEnding in {
						".luau",
						".lua"
					} do
						source = string.gsub(source, fileEnding, "")
					end
				end

				error(string.format(message, string.format(self.errorFormat, source, line)), math.huge)
			else
				print(string.format(message, ""))
			end
		end
	end
end

function LogIO:setLogLevel(targetLevel)
	self.level = targetLevel
end

function LogIO:setProperty(name, value)
	self.properties[name] = value
end

function LogIO.getLogger(logName)
	return loggersLookup[logName] :: logObject
end

function LogIO.new(logName: string, logSettings: logSettings)
	local self = setmetatable({ }, { __index = LogIO })

	self.logName = logName

	assert(self.logName ~= nil, "Expected LogName: string")
	assert(loggersLookup[logName] == nil, "Logging Object already exists")

	self.properties = (logSettings and logSettings.properties) or self.defaultProperties
	self.errorFormat = (logSettings and logSettings.errorFormat) or self.defaultErrorPattern
	self.format = (logSettings and logSettings.format) or self.defaultPattern
	self.level = (logSettings and logSettings.level) or self.defaultLevel

	self.logStack = { }

	for prototypeName, prototypeData in self.deafaultPrototypes do
		self:_loadPrototype(prototypeName, prototypeData)
	end

	loggersLookup[logName] = self

	return self :: logObject
end

return LogIO