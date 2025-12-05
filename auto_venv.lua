-- auto_venv.lua
-- Auto-activate/deactivate Python .venv when changing directories in cmd via Clink.

-- Remember last directory and current venv.
local last_dir    = os.getcwd()
local active_venv = nil

-- Capture the "base" PATH once, before we start mutating it.
local base_path   = os.getenv("PATH") or ""

-- --- Helpers ---------------------------------------------------------------

local function file_exists(path)
    local f = io.open(path, "r")
    if f ~= nil then
        f:close()
        return true
    end
    return false
end

local function parent_dir(path)
    -- Strip trailing backslashes.
    path = path:gsub("[\\]+$", "")
    -- Match "C:\foo\bar" -> "C:\foo"
    local parent = path:match("^(.*)\\[^\\]+$")
    if parent == nil or parent == path or parent == "" then
        return nil
    end
    return parent
end

-- Walk up from cwd looking for a ".venv" folder with Scripts\activate.bat.
local function find_venv_root(start_dir)
    local dir = start_dir
    while dir do
        local venv_dir    = dir .. "\\.venv"
        local activatebat = venv_dir .. "\\Scripts\\activate.bat"
        if file_exists(activatebat) then
            return venv_dir
        end
        dir = parent_dir(dir)
    end
    return nil
end

local function activate_venv(venv_dir)
    if active_venv == venv_dir then
        return
    end

    -- Switch from one venv to another: reset first.
    if active_venv ~= nil then
        -- restore base PATH, clear VIRTUAL_ENV
        os.setenv("PATH", base_path)
        os.setenv("VIRTUAL_ENV", nil)
        active_venv = nil
    end

    local scripts = venv_dir .. "\\Scripts"
    -- Prepend Scripts to PATH, set VIRTUAL_ENV.
    os.setenv("VIRTUAL_ENV", venv_dir)
    os.setenv("PATH", scripts .. ";" .. base_path)
    active_venv = venv_dir
    clink.print("Activating virtual environment in : " .. active_venv)
end

local function deactivate_venv()
    if active_venv == nil then
        return
    end
    os.setenv("PATH", base_path)
    os.setenv("VIRTUAL_ENV", nil)
    clink.print("Deactivating virtual environment in : " .. active_venv)
    active_venv = nil
end

-- --- Prompt filter hook ----------------------------------------------------
-- This is called every time cmd asks Clink to build a prompt. :contentReference[oaicite:2]{index=2}

local function auto_venv_prompt_filter(prompt)
    local cwd = os.getcwd()
    if cwd ~= last_dir then
        last_dir = cwd

        local venv_dir = find_venv_root(cwd)
        if venv_dir then
            activate_venv(venv_dir)
        else
            deactivate_venv()
        end
    end

    -- Don’t change the actual prompt text; just return it.
    return prompt
end

-- Register the filter with some middle-ish priority (5 is arbitrary).
clink.prompt.register_filter(auto_venv_prompt_filter, 5)
