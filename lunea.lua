LUNEA_VERSION = "1.0.0"

local colors = {
    reset = "\27[0m",
    red = "\27[31m",
    yellow = "\27[33m",
    blue = "\27[34m",
    cyan = "\27[36m"
}

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

local function is_dependency_installed(dep)
    local null_device = package.config:sub(1, 1) == "\\" and "NUL" or "/dev/null"
    local cmd = "luarocks show --local " .. dep .. " > " .. null_device .. " 2>&1"

    local success = os.execute(cmd)
    return success == 0
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
            local success = os.execute("luarocks install --local " .. dep)
            if not success == 0 then
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
            error("Dependency missing: " .. dep .. ". Use the task 'install_dependencies' to install project dependencies or install it manually with LuaRocks.")
        else
            print("Dependency found: " .. dep)
        end
    end
end

tasks["run"] = function(scriptId)
    if not scriptId then
        error("No script ID provided to the task!")
    end

    print("- Executing pre-run checks...")
    runTask("check_dependencies")
    print("- Pre-run checks finished!")

    local scriptPath = project.scripts[scriptId]
    if scriptPath then
       print("- Running script '" .. scriptId .. "' (" .. scriptPath .. ") ...")

       local success, err = pcall(dofile, scriptPath)
       if not success then
          error("An error occurred while running script '" .. scriptId .. "' (" .. scriptPath .. "): " .. err)
       end
    else
       error("No script found with ID: " .. scriptId)
    end
end

tasks["version"] = function()
    print("Running Lunea v" .. LUNEA_VERSION .. " on " .. _VERSION)
end

tasks["project_info"] = function()
    print("Displaying project information: (NOTE: If any of theses values are 'nil', your project may not follow Lunea's project standards)")
    print("- Name: " .. project.name)
    print("- Version: " .. project.version)
    print("- Description: " .. project.description)
    print("- Author: " .. project.author)
    print("- License: " .. project.license)
    print("- Dependencies: " .. (#project.dependencies > 0 and table.concat(project.dependencies, ", ") or "none"))

    local scripts = {}
    for id, path in pairs(project.scripts) do
        table.insert(scripts, "\n  - " .. id .. ": " .. tostring(path))
    end

    print("- Scripts:" .. table.concat(scripts, ""))

    local tasks = {}
    for task, func in pairs(project.tasks) do
        table.insert(tasks, task)
    end

    print("- Tasks: " .. table.concat(tasks, ", "))
end

tasks["tasks"] = function()
    print("Tasks:")
    for name, func in pairs(tasks) do
        print("- " .. name)
    end
end

local success, err = pcall(require, "luarocks.loader")
if not success then
    print(colors.red .. "ERROR: LuaRocks Loader is not available. Please fix your LuaRocks installation or install LuaRocks if you don't have it yet!")
    os.exit(1)
end

print(colors.cyan .. "> Loading project..." .. colors.reset)

local success, err = pcall(dofile, "project.lunea")
if not success then
    print(colors.red .. "ERROR: An error occurred while loading the project: " .. err .. colors.reset)
    os.exit(1)
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