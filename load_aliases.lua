-- load_aliases.lua
local alias_file = os.getenv("LOCALAPPDATA") .. "\\clink\\aliases.cmd"
clink.print("Loading aliases from: " .. alias_file)
if alias_file then
    -- Run the cmd file so doskey macros are defined in this session
    os.execute('cmd /c "' .. alias_file .. '"')
end
