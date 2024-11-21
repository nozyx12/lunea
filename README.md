# Lunea

Lunea is a lightweight and flexible task manager for Lua developers, designed to simplify project management and task execution. It includes built-in support for dependency management, LuaRocks integration, and script execution, making it a powerful yet minimalist tool.

## Features
- Task Management: Define and execute tasks easily with predefined or custom tasks.
- Dependency Management: Automatically check and install dependencies using LuaRocks. 
- Script Execution: Associate project-specific scripts with task execution. 
- Dynamic Arguments: Command-line arguments are automatically parsed and converted. 
- Color-Coded Logging: Clear and visually appealing logs. 
- Built-In Project Standards: Easily define project metadata and scripts.

## Installation

### ⚠️ Requirements
- Lua 5.1
- LuaRocks for dependency management.

### Install Lunea using installation packages
- Visit the GitHub Releases page.
- Download the appropriate installation package for your system.
- Follow the instructions provided to set it up.

## Usage
1. Create a Project File

Create a file named project.lunea to define your project and its tasks.
Example project.lunea:

```lua
project.name = "MyProject"
project.version = "1.0.0"
project.description = "A demo project for Lunea."
project.author = "Your Name"
project.license = "MIT"
project.dependencies = { "luasocket", "luafilesystem" }

project.scripts = {
   ["example"] = "example.lua"
}

project.tasks = {
   custom_task = function()
      print("This is a custom task defined in the project.")
   end
}
```

2. Run Tasks

Use the command line to execute tasks.
### Run a Built-In Task:
```bash
lunea version
```

### Run a Custom Task:
```bash
lunea custom_task
```

### Run a Script:
```bash
lunea run example
```

### Built-In Tasks
`install_dependencies`

Installs all project dependencies using LuaRocks.
```bash
lunea install_dependencies
```

`check_dependencies`

Verifies that all project dependencies are installed.

```bash
lunea check_dependencies
```

`run`

Executes a script defined in the `project.scripts` table.

```bash
lunea run <script_id>
```
- Replace <script_id> with the ID of the script defined in project.scripts.

`version`

Displays the current version of Lunea and Lua.

```bash
lunea version
```

`project_info`

Displays project metadata and configuration.

```bash
lunea project_info
```

`tasks`

Lists all available tasks (built-in and custom).

```
lunea tasks
```

## Project Structure

A typical Lunea project may include the following:

```bash
my_project/
├── project.lunea       # Project definition
├── example.lua     # An example project script (named example.lua)
└── test.lua     # An example project script (named test.lua)
```

## Advanced Features
### Command-Line Arguments

Arguments passed to tasks are automatically converted:

- `true` (string) → `true` (boolean)
- `true` (string) → `false` (boolean)
- Numeric strings (e.g., `123`) → Numbers (`123`)

#### Example:

```bash
lua lunea.lua run_script true 42 hell"
```
- The task will receive `true` (boolean), `42` (number), and `hello` (string) as arguments.

### Custom Task Definition

You can define custom tasks in `project.lunea`.
```lua
project.tasks.my_task = function(arg1, arg2)
    print("My task executed with arguments:", arg1, arg2)
end
```

## Notes

- **Dependencies**: Ensure LuaRocks is correctly installed for dependency management.
- **Error Handling**: Lunea displays clear error messages for missing dependencies, undefined tasks, or failed scripts.
- **Task Name Conflicts**: Custom task names in `project.lunea` cannot overwrite built-in tasks.

## Contributing

Contributions are welcome! Feel free to open an **issue** or submit a **pull request** to improve Lunea.

## License

Lunea is licensed under the NPL (v1) License. See the LICENSE file for details.

### Manage your Lua projects efficiently with **Lunea**! 🎉