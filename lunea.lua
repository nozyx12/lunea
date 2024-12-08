LUNEA_VERSION = "1.0.1"

local colors = {
    reset = "\27[0m",
    red = "\27[31m",
    yellow = "\27[33m",
    blue = "\27[34m",
    cyan = "\27[36m"
}

local is_windows = package.config:sub(1, 1) == "\\"

if _VERSION ~= "Lua 5.1" then
    print(colors.red .. "ERROR: Incompatible Lua version detected!\n- Required Lua version: Lua 5.1\n- Current Lua version: " .. _VERSION)
    os.exit(1)
end

package.path = "packages/share/lua/5.1/?.lua;packages/share/lua/5.1/?/init.lua;" .. package.path
package.cpath = is_windows and "packages/lib/lua/5.1/?.dll;" or "packages/lib/lua/5.1/?.so;" .. package.cpath

local function command_exists(cmd)
    if is_windows then
        local result = os.execute("where " .. cmd .. " >NUL 2>&1")
        return result == true or result == 0
    else
        local handle = io.popen("command -v " .. cmd .. " >/dev/null 2>&1 && echo OK || echo FAIL")
        local result = handle:read("*a")
        handle:close()
        return result:match("OK") ~= nil
    end
end

if not command_exists("luarocks") then
    print(colors.red .. "ERROR: LuaRocks cannot be found on your PATH! Please fix your LuaRocks installation or install it if you don't have it yet!" .. colors.reset)
    os.exit(1)
end

project = {}
local tasks = {}

function runTask(task_name, ...)
    if tasks[task_name] then
        print(colors.cyan .. "> Executing task: " .. task_name .. colors.reset)

        local success, err = pcall(tasks[task_name], ...)
        if not success then
            print(colors.red .. "> Task '" .. task_name .. "' failed: " .. err .. colors.reset)
            os.exit(1)
        end

        print(colors.cyan .. "> Task ended: " .. task_name .. colors.reset)
    else
        print(colors.red .. "ERROR: Task not found: '" .. task_name .. "'" .. colors.reset)
    end
end

local function is_dependency_installed(dep)
    local exit_code = os.execute("luarocks show " .. dep .. " --tree=packages >" .. (is_windows and "NUL" or "/dev/null") .. " 2>&1")
    return exit_code == 0
end

local function convert_arg(value)
    if value == "true" then
        return true
    elseif value == "false" then
        return false
    elseif tonumber(value) then
        return tonumber(value)
    else
        return value
    end
end

tasks["install_dependencies"] = function()
    local deps = project.dependencies or {}
    if #deps == 0 then
        print("No dependencies to install.")
        return
    end

    for _, dep in ipairs(deps) do
        local is_installed = is_dependency_installed(dep)
        if not is_installed then
            print("- Installing dependency: " .. dep)
            local exit_code = os.execute("luarocks install " .. dep .. " --tree=packages")
            if exit_code ~= 0 then
                error("Failed to install dependency: " .. dep)
            else
                print("Dependency installed: " .. dep)
            end
        else
            print("- Already installed: " .. dep .. " (Skipping)")
        end
    end
end

tasks["check_dependencies"] = function()
    local deps = project.dependencies or {}
    if #deps == 0 then
        print("No dependencies to check.")
        return
    end

    for _, dep in ipairs(deps) do
        print("- Checking dependency: " .. dep)

        local is_installed = is_dependency_installed(dep)
        if not is_installed then
            error("Dependency missing: " .. dep .. ". Use the task 'install_dependencies' to install project dependencies.")
        else
            print("Dependency found: " .. dep)
        end
    end
end

tasks["run"] = function(file)
    if not file then
        error("No file to be run provided to the task!")
    end

    print("- Checking dependencies...")
    runTask("check_dependencies")

    print("- Running script: " .. file)

    local success, err = pcall(dofile, file)
    if not success then
        error("An error occurred while running script '" .. file .. "' : " .. err)
    end
end

tasks["version"] = function()
    print("Running Lunea v" .. LUNEA_VERSION)
end

tasks["project_info"] = function()
    print("Displaying project information:")
    print("- Name: " .. project.name)
    print("- Version: " .. project.version)
    print("- Description: " .. project.description)
    print("- Author: " .. project.author)
    print("- License: " .. project.license)
    print("- Dependencies: " .. (#project.dependencies > 0 and table.concat(project.dependencies, ", ") or "none"))

    local tasks = {}
    for task, func in pairs(project.tasks) do
        table.insert(tasks, task)
    end

    print("- Tasks: " .. (#project.tasks > 0 and table.concat(tasks, "") or "none"))
end

tasks["tasks"] = function()
    print("Tasks:")
    for name, func in pairs(tasks) do
        print("- " .. name)
    end
end

print(colors.cyan .. "> Loading project..." .. colors.reset)

local success, err = pcall(dofile, "project.lunea")
if not success then
    print(colors.red .. "ERROR: An error occurred while loading the project: " .. err .. colors.reset)
    os.exit(1)
end

if not project.name then
    print(colors.red .. "ERROR: Undefined project field: name" .. colors.reset)
elseif not project.version then
    print(colors.red .. "ERROR: Undefined project field: version" .. colors.reset)
elseif not project.description then
    print(colors.red .. "ERROR: Undefined project field: description" .. colors.reset)    
elseif not project.author then
    print(colors.red .. "ERROR: Undefined project field: author" .. colors.reset)
elseif not project.license then
    print(colors.red .. "ERROR: Undefined project field: license" .. colors.reset)
elseif not project.dependencies then
    print(colors.red .. "ERROR: Undefined project field: dependencies" .. colors.reset)
elseif not project.tasks then
    print(colors.red .. "ERROR: Undefined project field: tasks" .. colors.reset)
end

if project.tasks then
    for name, func in pairs(project.tasks) do
        if tasks[name] then
            print(colors.yellow .. "WARNING: The project is attempting to define a task with the name '" .. name .. "', which is already used by another task. The new task will be ignored.")
        else
            tasks[name] = func
        end
    end
end

if #arg > 0 then
    local task_name = arg[1]
    local task_args = {}

    for i = 2, #arg do
        table.insert(task_args, convert_arg(arg[i]))
    end

    runTask(task_name, unpack(task_args))
else
    print(colors.yellow .. "No task specified. Use `lunea <task> [task arguments]` to run a task." .. colors.reset)
end
