--[[
	Author // AsynchronousMatrix
	Project // Log-IO
]]--

local LogIO = require("Source/init")
local Logger = LogIO.new("TestSystem")

local object = {"Hello", "World", "!", { "Sub", "Table!", { "Sub", "Table", "Of", "A", "Sub", "Table!" }}}

object.ref = object
object[4][3].ref = object

Logger:debug(object)