-- config.lua
-- Configuration management module for ReaMD
-- Handles user preferences with persistence via Reaper ExtState

local Config = {}

-- ExtState section name for all ReaMD settings
local SECTION = "ReaMD_Config"

-- ═══════════════════════════════════════════════════════════════════════════
-- DEFAULT VALUES
-- ═══════════════════════════════════════════════════════════════════════════

Config.defaults = {
    font_size = 14,                  -- Base font size
    font_family = "sans-serif",      -- Normal text font
    code_font = "monospace",         -- Code block font
    theme = "light",                 -- light/dark/auto
    scroll_speed = 1.0,              -- Scroll multiplier
    highlight_color = 0x3366CC33,    -- Fragment highlight (RGBA)
    auto_scroll = true,              -- Follow playback
    scroll_offset = 0.3,             -- Viewport offset (0.3 = 30% from top)
    last_directory = "",             -- Last opened folder
    recent_files = "",               -- Recent files (pipe-separated paths)
    ai_api_key = "",                 -- Anthropic API key for AI parsing
    live_preview = true,             -- Show live preview while editing
}

-- Type definitions for proper conversion from ExtState strings
local setting_types = {
    font_size = "number",
    font_family = "string",
    code_font = "string",
    theme = "string",
    scroll_speed = "number",
    highlight_color = "number",
    auto_scroll = "boolean",
    scroll_offset = "number",
    last_directory = "string",
    recent_files = "string",
    ai_api_key = "string",
    live_preview = "boolean",
}

-- Current settings (initialized as copy of defaults)
Config.settings = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- INTERNAL HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

--- Deep copy defaults to settings
local function copy_defaults()
    Config.settings = {}
    for key, value in pairs(Config.defaults) do
        Config.settings[key] = value
    end
end

--- Convert string from ExtState to proper type
-- @param key string: Setting key (used to determine type)
-- @param str_value string: String value from ExtState
-- @return any: Converted value, or nil if conversion fails
local function string_to_value(key, str_value)
    if not str_value or str_value == "" then
        return nil
    end

    local value_type = setting_types[key]

    if value_type == "number" then
        local num = tonumber(str_value)
        return num
    elseif value_type == "boolean" then
        if str_value == "true" or str_value == "1" then
            return true
        elseif str_value == "false" or str_value == "0" then
            return false
        end
        return nil
    elseif value_type == "string" then
        return str_value
    end

    return nil
end

--- Convert value to string for ExtState storage
-- @param value any: Value to convert
-- @return string: String representation
local function value_to_string(value)
    if value == nil then
        return ""
    end

    local val_type = type(value)

    if val_type == "boolean" then
        return value and "true" or "false"
    elseif val_type == "number" then
        -- Use %g for compact representation, but ensure precision for floats
        if value == math.floor(value) then
            return tostring(math.floor(value))
        else
            return string.format("%.6g", value)
        end
    else
        return tostring(value)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════════════════

--- Get a setting value
-- @param key string: Setting key
-- @return any: Current value, or default if key is invalid
function Config.get(key)
    if not key then
        return nil
    end

    -- Return current setting if it exists
    if Config.settings[key] ~= nil then
        return Config.settings[key]
    end

    -- Fall back to default
    return Config.defaults[key]
end

--- Set a setting value
-- @param key string: Setting key
-- @param value any: New value
-- @return boolean: True if setting was updated
function Config.set(key, value)
    -- Only allow known settings
    if not Config.defaults[key] then
        return false
    end

    -- Type validation
    local expected_type = setting_types[key]
    local actual_type = type(value)

    -- Allow nil to reset to default
    if value == nil then
        Config.settings[key] = Config.defaults[key]
        return true
    end

    -- Validate type matches
    if expected_type == "number" and actual_type ~= "number" then
        return false
    elseif expected_type == "boolean" and actual_type ~= "boolean" then
        return false
    elseif expected_type == "string" and actual_type ~= "string" then
        return false
    end

    Config.settings[key] = value
    return true
end

--- Load all settings from Reaper ExtState
-- Should be called at startup
function Config.load()
    -- Start with defaults
    copy_defaults()

    -- Load each setting from ExtState
    for key, _ in pairs(Config.defaults) do
        local str_value = reaper.GetExtState(SECTION, key)

        if str_value and str_value ~= "" then
            local converted = string_to_value(key, str_value)
            if converted ~= nil then
                Config.settings[key] = converted
            end
            -- If conversion fails, keep the default (already set)
        end
    end
end

--- Save all settings to Reaper ExtState
-- Should be called when settings change
function Config.save()
    for key, value in pairs(Config.settings) do
        local str_value = value_to_string(value)
        -- Third parameter 'true' persists across sessions
        reaper.SetExtState(SECTION, key, str_value, true)
    end
end

--- Reset all settings to defaults
-- Also clears ExtState
function Config.reset()
    -- Clear ExtState for all known keys
    for key, _ in pairs(Config.defaults) do
        reaper.DeleteExtState(SECTION, key, true)
    end

    -- Reset to defaults
    copy_defaults()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- RECENT FILES HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local MAX_RECENT_FILES = 10

--- Get list of recent files
-- @return table: Array of file paths
function Config.get_recent_files()
    local str = Config.get("recent_files") or ""
    if str == "" then return {} end

    local files = {}
    for path in str:gmatch("[^|]+") do
        if path ~= "" then
            table.insert(files, path)
        end
    end
    return files
end

--- Add file to recent files list
-- @param path string: File path to add
function Config.add_recent_file(path)
    if not path or path == "" then return end

    local files = Config.get_recent_files()

    -- Remove if already exists (to move to top)
    for i = #files, 1, -1 do
        if files[i] == path then
            table.remove(files, i)
        end
    end

    -- Add to beginning
    table.insert(files, 1, path)

    -- Limit to max
    while #files > MAX_RECENT_FILES do
        table.remove(files)
    end

    -- Save as pipe-separated string
    Config.set("recent_files", table.concat(files, "|"))
end

--- Remove file from recent files list
-- @param path string: File path to remove
function Config.remove_recent_file(path)
    if not path or path == "" then return end

    local files = Config.get_recent_files()
    local changed = false

    for i = #files, 1, -1 do
        if files[i] == path then
            table.remove(files, i)
            changed = true
        end
    end

    if changed then
        Config.set("recent_files", table.concat(files, "|"))
        Config.save()
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

-- Initialize settings with defaults on module load
copy_defaults()

-- ═══════════════════════════════════════════════════════════════════════════
-- CHECKPOINT: config.lua COMPLETE
-- Exported: Config.get, Config.set, Config.load, Config.save, Config.reset
--           Config.defaults, Config.settings
-- Settings: font_size, font_family, code_font, theme, scroll_speed,
--           highlight_color, auto_scroll, scroll_offset, last_directory
-- ═══════════════════════════════════════════════════════════════════════════

return Config
