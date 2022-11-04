# LogIO
LuaU Logging System

## Motivation
LuaU has no destinctive Log/Logging systems at the time of writing this, LogIO was programmed with the hope of covering this area with what LuaU 
currently supports at the moment

## Overview
To get started with this system, you need to initiate a Log Class through
```lua
  local LogClass = LogIO.new("YourSystemName")
```

This `LogClass` will define methods and properties which allow you to decorate the output of your LuaU program

## API
> setProperty

```lua
  local LogClass = LogIO.new("YourSystemName")
  
  LogClass:setProperty("removeFileEndings", false)
```

Though this can be set through the settings table passed into the `new` method, you can also write to the properties table using this function.
Properties define the attributes when compiling a given text ~ they influence the behaviour at which these texts are displayed.

 Property  | Property type | Property description |
| ------------- | ------------- | ------------- |
| expandTables | [Boolean](https://www.lua.org/pil/2.2.html) | Defines if tables are expanded in the Output  |
| exposeTableNames | [Boolean](https://www.lua.org/pil/2.2.html) | Exposes the tables memory address |
| useNewLines | [Boolean](https://www.lua.org/pil/2.2.html) | Create NewLines in the Table expansion, often makes things clearer |
| useTabs | [Boolean](https://www.lua.org/pil/2.2.html) | Value using Tabs over Spaces in Table expansion |
| removeFileEndings | [Boolean](https://www.lua.org/pil/2.2.html) | When calling either `error` or `critical` this setting will define if the filetype is visible |
| bytes | [Boolean](https://www.lua.org/pil/2.2.html) | Byes containing the ANSI prefix, space & tab |

---

> setLogLevel

```lua
  local LogClass = LogIO.new("YourSystemName")
  
  LogClass:setLogLevel(2)
  LogClass:debug("Message!") -- this will not appear in the output, fails to meet the criteria of LogLevel
```

Log Levels help to define a standard for displaying outputs ~ using LogLevel you can provide a definition for what method is allowed to log to the output

---

> getLogger

```lua
  local LogClass = LogIO.getLogger("InitiatedSystem")
  
  LogClass:setLogLevel(5)
```

Get Logger will return the initiated log object

---

> debug, log, warn, error, critical

```lua
  local LogClass = LogIO.new("YourSystemName")

  LogClass:debug("Message!")
  LogClass:log("My", "Message")
  LogClass:warn("My", newproxy())
  LogClass:error("Whoah!", { 1, 2, 3 })
  
  -- the below will never run since calling `error` will raise an exception in that specific thread
  
  LogClass:critical("Well, hopefully it should never get to this point..")
```

 Method  | ANSI Color | Level |
| ------------- | ------------- | ------------- |
| debug | Magenta | 1 |
| log | Blue | 2 |
| warn | Yellow | 3 |
| error | Red | 4 |
| critical | Red | 5 |
