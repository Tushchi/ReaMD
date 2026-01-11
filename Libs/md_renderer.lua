-- md_renderer.lua
-- ReaImGui renderer for markdown AST
-- Renders parsed markdown AST to ReaImGui widgets

local Renderer = {}

-- Import parser for node types reference
local Parser = require("md_parser")
local NT = Parser.NodeTypes

-- Import config for theme-aware colors
local Config = require("config")

-- ===============================================================================
-- COLOR CONSTANTS
-- ===============================================================================

local COLORS = {
    heading = 0x3366CCFF,        -- Blue for headers
    link = 0x0066CCFF,           -- Link blue
    code_bg = 0x1A1A1AFF,        -- Dark background for code blocks
    code_text = 0xE0E0E0FF,      -- Light text in code
    blockquote_line = 0x666666FF, -- Gray line for blockquote
    highlight = 0x3366CC66,      -- Semi-transparent highlight (increased from 33 to 66)
}

--- Get neutral button colors based on current theme
-- @return number, number, number, number: button, hovered, active, text colors
local function get_neutral_button_colors()
    local theme = Config.get("theme")
    if theme == "dark" then
        -- Darker button with white text for dark theme
        return 0x606060FF, 0x707070FF, 0x505050FF, 0xFFFFFFFF
    else
        -- Lighter button with dark text for light theme
        return 0xA0A0A0FF, 0xB0B0B0FF, 0x909090FF, 0x000000FF
    end
end

-- ===============================================================================
-- LAYOUT CONSTANTS
-- ===============================================================================

local LAYOUT = {
    indent_width = 20,           -- Indent for lists/quotes
    blockquote_line_width = 3,   -- Width of blockquote indicator line
    blockquote_gap = 8,          -- Gap between line and content
    code_block_padding = 8,      -- Padding inside code blocks
    list_bullet_offset = 15,     -- Offset for bullet/number
    heading_spacing = 4,         -- Extra spacing after headings
    paragraph_spacing = 8,       -- Spacing between paragraphs
}

-- ===============================================================================
-- STATE TRACKING
-- ===============================================================================

-- Track line positions for scroll sync
local line_positions = {}  -- Maps line_start -> Y coordinate

-- Track if we're rendering inline (for SameLine handling)
local inline_context = {
    active = false,
    first_element = true,
}

-- ===============================================================================
-- HELPER FUNCTIONS
-- ===============================================================================

--- Reset inline context for a new block
local function reset_inline_context()
    inline_context.active = false
    inline_context.first_element = true
end

--- Start inline rendering mode
local function start_inline_context()
    inline_context.active = true
    inline_context.first_element = true
end

--- Handle SameLine for inline elements
-- @param ctx ReaImGui context
local function handle_inline_spacing(ctx)
    if inline_context.active then
        if inline_context.first_element then
            inline_context.first_element = false
        else
            reaper.ImGui_SameLine(ctx, 0, 0)
        end
    end
end

--- Record line position for scroll sync
-- @param ctx ReaImGui context
-- @param line_start number: Line number in source
local function record_line_position(ctx, line_start)
    if line_start and not line_positions[line_start] then
        local _, y = reaper.ImGui_GetCursorScreenPos(ctx)
        line_positions[line_start] = y
    end
end

--- Check if a line should be highlighted and get its color
-- @param state table: Render state with highlight_lines (map of line_start -> color)
-- @param line_start number: Node's starting line
-- @param line_end number: Node's ending line (unused, kept for API compatibility)
-- @return boolean: True if should highlight
-- @return number|nil: Highlight color (0xRRGGBBAA) or nil
local function should_highlight(state, line_start, line_end)
    if not state or not state.highlight_lines then
        return false, nil
    end

    -- highlight_lines is now a map: {[line_start] = color, ...}
    local color = state.highlight_lines[line_start]
    if color then
        return true, color
    end
    return false, nil
end

--- Draw highlight background behind content
-- @param ctx ReaImGui context
-- @param width number: Width of highlight area
-- @param height number: Height of highlight area
-- @param color number|nil: Highlight color (0xRRGGBBAA), defaults to COLORS.highlight
local function draw_highlight_background(ctx, width, height, color)
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
    local x, y = reaper.ImGui_GetCursorScreenPos(ctx)
    reaper.ImGui_DrawList_AddRectFilled(
        draw_list,
        x, y,
        x + width, y + height,
        color or COLORS.highlight
    )
end

-- ===============================================================================
-- INLINE ELEMENT RENDERERS
-- ===============================================================================

--- Render text node
-- @param ctx ReaImGui context
-- @param node table: Text node
-- @param fonts table: Font handles
-- @param state table: Render state
local function render_text(ctx, node, fonts, state)
    handle_inline_spacing(ctx)
    reaper.ImGui_Text(ctx, node.text or "")
end

--- Helper: Push font with size (ReaImGui v0.10+ API)
-- @param ctx ReaImGui context
-- @param font Font handle
-- @param fonts table: Fonts table that may contain sizes
-- @param size_key string: Key for size lookup (e.g., "bold", "code")
local function push_font(ctx, font, fonts, size_key)
    if font then
        local size = fonts.sizes and fonts.sizes[size_key] or 14  -- Default to 14 if no size
        reaper.ImGui_PushFont(ctx, font, size)
    end
end

--- Render bold node
-- @param ctx ReaImGui context
-- @param node table: Bold node
-- @param fonts table: Font handles
-- @param state table: Render state
local function render_bold(ctx, node, fonts, state)
    if fonts.bold then
        push_font(ctx, fonts.bold, fonts, "bold")
    end

    if node.children then
        for _, child in ipairs(node.children) do
            Renderer.render_node(ctx, child, fonts, state)
        end
    end

    if fonts.bold then
        reaper.ImGui_PopFont(ctx)
    end
end

--- Render italic node
-- @param ctx ReaImGui context
-- @param node table: Italic node
-- @param fonts table: Font handles
-- @param state table: Render state
local function render_italic(ctx, node, fonts, state)
    if fonts.italic then
        push_font(ctx, fonts.italic, fonts, "italic")
    end

    if node.children then
        for _, child in ipairs(node.children) do
            Renderer.render_node(ctx, child, fonts, state)
        end
    end

    if fonts.italic then
        reaper.ImGui_PopFont(ctx)
    end
end

--- Render inline code
-- @param ctx ReaImGui context
-- @param node table: Code inline node
-- @param fonts table: Font handles
-- @param state table: Render state
local function render_code_inline(ctx, node, fonts, state)
    handle_inline_spacing(ctx)

    if fonts.code then
        push_font(ctx, fonts.code, fonts, "code")
    end

    reaper.ImGui_TextColored(ctx, COLORS.code_text, node.text or "")

    if fonts.code then
        reaper.ImGui_PopFont(ctx)
    end
end

--- Render link node
-- @param ctx ReaImGui context
-- @param node table: Link node
-- @param fonts table: Font handles
-- @param state table: Render state
local function render_link(ctx, node, fonts, state)
    handle_inline_spacing(ctx)

    -- Render link text in link color
    reaper.ImGui_TextColored(ctx, COLORS.link, "")
    reaper.ImGui_SameLine(ctx, 0, 0)

    -- Build link text from children
    local link_text = ""
    if node.children then
        for _, child in ipairs(node.children) do
            if child.type == NT.TEXT then
                link_text = link_text .. (child.text or "")
            end
        end
    end

    reaper.ImGui_TextColored(ctx, COLORS.link, link_text)

    -- Check for click
    if reaper.ImGui_IsItemHovered(ctx) then
        if reaper.ImGui_IsMouseClicked(ctx, 0) then
            if state then
                state.clicked_link = node.url
            end
        end
    end
end

-- ===============================================================================
-- SCENARIO MODE HELPERS
-- ===============================================================================

--- Extract text from first cell of a row (for identification)
-- @param row table: Table row with cells
-- @return string: Text content of first cell
local function get_row_identifier(row)
    if not row or not row.cells or not row.cells[1] then
        return ""
    end

    local cell = row.cells[1]
    local text = ""
    if cell.children then
        for _, child in ipairs(cell.children) do
            if child.type == NT.TEXT then
                text = text .. (child.text or "")
            elseif child.children then
                for _, sub in ipairs(child.children) do
                    if sub.type == NT.TEXT then
                        text = text .. (sub.text or "")
                    end
                end
            end
        end
    end
    return text
end

-- State for popup management
local popup_state = {
    open_for_line = nil,  -- Which line's popup is open
}

--- Render item linker for scenario mode (v3: multi-item support)
-- Shows [+] to add items, [N] badge for count, popup with [→] jump and [X] remove
-- @param ctx ReaImGui context
-- @param state table: Render state with scenario data
-- @param line_start number: Line start for this element
-- @param line_end number: Line end for this element
-- @param identifier string: Display text for this element
-- @param node_type string: Type of node ("heading" or "table_row")
-- @param row_index number: Optional row index
local function render_item_linker(ctx, state, line_start, line_end, identifier, node_type, row_index)
    if not state or not state.scenario_enabled then
        return
    end

    local scenario = state.scenario_engine
    if not scenario then
        return
    end

    -- Get all linked items for this line
    local item_guids = scenario.get_fragment_item_guids(line_start)
    local count = #item_guids

    -- Check for legacy region link
    local current_fragment = scenario.find_fragment_by_line(line_start)
    local current_region_id = current_fragment and current_fragment.region_id or nil

    -- Unique IDs
    local add_id = "+##" .. tostring(line_start)
    local badge_id = tostring(count) .. "##badge" .. tostring(line_start)
    local popup_id = "items_popup##" .. tostring(line_start)

    -- Handle legacy region link (show info + unlink)
    if current_region_id and count == 0 then
        local region_name = scenario.get_region_name(current_region_id)
        reaper.ImGui_TextDisabled(ctx, "(rgn)")
        if reaper.ImGui_IsItemHovered(ctx) then
            reaper.ImGui_SetTooltip(ctx, region_name)
        end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_SmallButton(ctx, "X##rgn" .. tostring(line_start)) then
            scenario.unlink_fragment_by_line(line_start)
            state.scenario_changed = true
        end
        return
    end

    -- Color indicator button - only show if items are linked
    if count > 0 then
        local cat_index = scenario.get_fragment_color_category(line_start)
        local cat_info = scenario.get_color_category_info(cat_index)

        -- Colored SmallButton with category letter (V/M/F/O)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), cat_info.button_color)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), cat_info.button_color)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), cat_info.button_color)

        local btn_label = (cat_info.label or "?") .. "##clr" .. tostring(line_start)
        if reaper.ImGui_SmallButton(ctx, btn_label) then
            scenario.cycle_fragment_color_category(line_start)
            state.scenario_changed = true
        end
        reaper.ImGui_PopStyleColor(ctx, 3)

        if reaper.ImGui_IsItemHovered(ctx) then
            reaper.ImGui_SetTooltip(ctx, cat_info.name .. " - click to change")
        end
        reaper.ImGui_SameLine(ctx)
    end

    -- [+] button - add item from selection (theme-aware neutral color)
    -- If item is in a group, adds all items from that group
    local btn_color, btn_hover, btn_active, btn_text = get_neutral_button_colors()
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), btn_color)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), btn_hover)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), btn_active)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), btn_text)
    if reaper.ImGui_SmallButton(ctx, add_id) then
        local item, guid, all_guids = scenario.get_selected_item()
        if item and all_guids and #all_guids > 0 then
            -- Add all items from group (or single item if not grouped)
            for _, grp_guid in ipairs(all_guids) do
                scenario.link_fragment_to_item(
                    grp_guid,
                    line_start,
                    line_end,
                    identifier,
                    node_type,
                    row_index
                )
            end
            state.scenario_changed = true
        end
    end
    local add_hovered = reaper.ImGui_IsItemHovered(ctx)
    reaper.ImGui_PopStyleColor(ctx, 4)
    if add_hovered then
        reaper.ImGui_SetTooltip(ctx, "Select item on timeline, click + to link")
    end

    -- [N] badge - show count, click to open popup (theme-aware neutral color)
    if count > 0 then
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), btn_color)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), btn_hover)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), btn_active)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), btn_text)
        if reaper.ImGui_SmallButton(ctx, badge_id) then
            -- Toggle popup
            if popup_state.open_for_line == line_start then
                popup_state.open_for_line = nil
            else
                popup_state.open_for_line = line_start
                reaper.ImGui_OpenPopup(ctx, popup_id)
            end
        end
        local badge_hovered = reaper.ImGui_IsItemHovered(ctx)
        reaper.ImGui_PopStyleColor(ctx, 4)
        if badge_hovered then
            reaper.ImGui_SetTooltip(ctx, count .. " item(s) linked - click to manage")
        end

        -- Popup with item list
        if reaper.ImGui_BeginPopup(ctx, popup_id) then
            for idx, guid in ipairs(item_guids) do
                local item_info = scenario.get_item_info(guid)
                local item_label

                if item_info then
                    local minutes = math.floor(item_info.pos / 60)
                    local seconds = math.floor(item_info.pos % 60)
                    item_label = string.format("%d:%02d %s", minutes, seconds, item_info.track_name or "")
                else
                    item_label = "(missing)"
                end

                -- Jump button [→]
                if reaper.ImGui_SmallButton(ctx, ">" .. "##jump" .. tostring(line_start) .. "_" .. tostring(idx)) then
                    scenario.jump_to_item(guid)
                end
                if reaper.ImGui_IsItemHovered(ctx) then
                    reaper.ImGui_SetTooltip(ctx, "Jump to item")
                end

                reaper.ImGui_SameLine(ctx)

                -- Item info
                reaper.ImGui_Text(ctx, item_label)

                reaper.ImGui_SameLine(ctx)

                -- Remove button [X]
                if reaper.ImGui_SmallButton(ctx, "X##del" .. tostring(line_start) .. "_" .. tostring(idx)) then
                    scenario.remove_item_from_fragment(line_start, guid)
                    state.scenario_changed = true
                    -- Close popup if no items left
                    if #scenario.get_fragment_item_guids(line_start) == 0 then
                        reaper.ImGui_CloseCurrentPopup(ctx)
                        popup_state.open_for_line = nil
                    end
                end
            end
            reaper.ImGui_EndPopup(ctx)
        else
            -- Popup closed
            if popup_state.open_for_line == line_start then
                popup_state.open_for_line = nil
            end
        end
    end
end

-- Keep old name as alias for compatibility
local render_region_selector = render_item_linker

-- ===============================================================================
-- BLOCK ELEMENT RENDERERS
-- ===============================================================================

--- Extract plain text from heading node
-- @param node table: Heading node
-- @return string: Plain text content
local function extract_heading_text(node)
    if not node or not node.children then
        return ""
    end

    local parts = {}
    for _, child in ipairs(node.children) do
        if child.type == NT.TEXT then
            table.insert(parts, child.text or "")
        elseif child.children then
            table.insert(parts, extract_heading_text(child))
        end
    end

    return table.concat(parts, "")
end

--- Render heading node
-- @param ctx ReaImGui context
-- @param node table: Heading node
-- @param fonts table: Font handles
-- @param state table: Render state
local function render_heading(ctx, node, fonts, state)
    reset_inline_context()
    record_line_position(ctx, node.line_start)

    -- Check for highlight
    local w, _ = reaper.ImGui_GetContentRegionAvail(ctx)
    if should_highlight(state, node.line_start, node.line_end) then
        draw_highlight_background(ctx, w, 24)  -- Approximate heading height
    end

    -- Select font and size key based on heading level
    local heading_font = nil
    local size_key = nil
    if node.level == 1 and fonts.h1 then
        heading_font = fonts.h1
        size_key = "h1"
    elseif node.level == 2 and fonts.h2 then
        heading_font = fonts.h2
        size_key = "h2"
    elseif node.level == 3 and fonts.h3 then
        heading_font = fonts.h3
        size_key = "h3"
    elseif fonts.bold then
        -- Fallback to bold for h4-h6
        heading_font = fonts.bold
        size_key = "bold"
    end

    if heading_font then
        push_font(ctx, heading_font, fonts, size_key)
    end

    -- Render heading content
    start_inline_context()
    if node.children then
        for _, child in ipairs(node.children) do
            -- Render children with heading color
            if child.type == NT.TEXT then
                handle_inline_spacing(ctx)
                reaper.ImGui_TextColored(ctx, COLORS.heading, child.text or "")
            else
                Renderer.render_node(ctx, child, fonts, state)
            end
        end
    end
    reset_inline_context()

    if heading_font then
        reaper.ImGui_PopFont(ctx)
    end

    -- Add region selector for headings in scenario mode
    if state and state.scenario_enabled and state.scenario_engine then
        reaper.ImGui_SameLine(ctx)
        local heading_text = extract_heading_text(node)
        -- Calculate section end (until next heading or end of document)
        local section_end = node.section_end or node.line_end
        render_region_selector(ctx, state, node.line_start, section_end, heading_text, "heading", nil)
    end

    reaper.ImGui_Spacing(ctx)
end

--- Render paragraph node
-- @param ctx ReaImGui context
-- @param node table: Paragraph node
-- @param fonts table: Font handles
-- @param state table: Render state
local function render_paragraph(ctx, node, fonts, state)
    reset_inline_context()
    record_line_position(ctx, node.line_start)

    -- Check for highlight
    local w, _ = reaper.ImGui_GetContentRegionAvail(ctx)
    if should_highlight(state, node.line_start, node.line_end) then
        draw_highlight_background(ctx, w, 20)  -- Approximate paragraph height
    end

    -- Render children inline
    start_inline_context()
    if node.children then
        for _, child in ipairs(node.children) do
            Renderer.render_node(ctx, child, fonts, state)
        end
    end
    reset_inline_context()

    reaper.ImGui_Spacing(ctx)
end

--- Render code block
-- @param ctx ReaImGui context
-- @param node table: Code block node
-- @param fonts table: Font handles
-- @param state table: Render state
local function render_code_block(ctx, node, fonts, state)
    reset_inline_context()
    record_line_position(ctx, node.line_start)

    local code_text = node.text or ""
    local w, _ = reaper.ImGui_GetContentRegionAvail(ctx)

    -- Calculate approximate height based on line count
    local line_count = 1
    for _ in code_text:gmatch("\n") do
        line_count = line_count + 1
    end
    local line_height = 16  -- Approximate line height for code
    local block_height = (line_count * line_height) + (LAYOUT.code_block_padding * 2)

    -- Generate unique ID for this code block
    local child_id = "code_block_" .. tostring(node.line_start)

    -- Begin child window with colored background
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), COLORS.code_bg)

    -- v0.10 API: BeginChild(ctx, id, w, h, child_flags, window_flags)
    local child_flags = reaper.ImGui_ChildFlags_None and reaper.ImGui_ChildFlags_None() or 0
    local window_flags = reaper.ImGui_WindowFlags_None()
    if reaper.ImGui_BeginChild(ctx, child_id, w, block_height, child_flags, window_flags) then
        -- Add padding
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + LAYOUT.code_block_padding)
        reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) + LAYOUT.code_block_padding)

        if fonts.code then
            push_font(ctx, fonts.code, fonts, "code")
        end

        -- Render code text
        reaper.ImGui_TextColored(ctx, COLORS.code_text, code_text)

        if fonts.code then
            reaper.ImGui_PopFont(ctx)
        end

        reaper.ImGui_EndChild(ctx)
    end

    reaper.ImGui_PopStyleColor(ctx)
    reaper.ImGui_Spacing(ctx)
end

--- Render unordered list
-- @param ctx ReaImGui context
-- @param node table: List UL node
-- @param fonts table: Font handles
-- @param state table: Render state
local function render_list_ul(ctx, node, fonts, state)
    reset_inline_context()
    record_line_position(ctx, node.line_start)

    if node.children then
        for _, item in ipairs(node.children) do
            -- Record item position
            record_line_position(ctx, item.line_start)

            -- Check for highlight
            local w, _ = reaper.ImGui_GetContentRegionAvail(ctx)
            if should_highlight(state, item.line_start, item.line_end) then
                draw_highlight_background(ctx, w, 18)
            end

            -- Bullet point
            reaper.ImGui_Bullet(ctx)
            reaper.ImGui_SameLine(ctx)

            -- Render item content inline
            start_inline_context()
            if item.children then
                for _, child in ipairs(item.children) do
                    Renderer.render_node(ctx, child, fonts, state)
                end
            end
            reset_inline_context()
        end
    end

    reaper.ImGui_Spacing(ctx)
end

--- Render ordered list
-- @param ctx ReaImGui context
-- @param node table: List OL node
-- @param fonts table: Font handles
-- @param state table: Render state
local function render_list_ol(ctx, node, fonts, state)
    reset_inline_context()
    record_line_position(ctx, node.line_start)

    if node.children then
        for idx, item in ipairs(node.children) do
            -- Record item position
            record_line_position(ctx, item.line_start)

            -- Check for highlight
            local w, _ = reaper.ImGui_GetContentRegionAvail(ctx)
            if should_highlight(state, item.line_start, item.line_end) then
                draw_highlight_background(ctx, w, 18)
            end

            -- Use item's number if available, otherwise use index
            local num = item.number or idx
            reaper.ImGui_Text(ctx, tostring(num) .. ".")
            reaper.ImGui_SameLine(ctx)

            -- Render item content inline
            start_inline_context()
            if item.children then
                for _, child in ipairs(item.children) do
                    Renderer.render_node(ctx, child, fonts, state)
                end
            end
            reset_inline_context()
        end
    end

    reaper.ImGui_Spacing(ctx)
end

--- Render blockquote
-- @param ctx ReaImGui context
-- @param node table: Blockquote node
-- @param fonts table: Font handles
-- @param state table: Render state
local function render_blockquote(ctx, node, fonts, state)
    reset_inline_context()
    record_line_position(ctx, node.line_start)

    -- Get current position for drawing the line
    local start_x, start_y = reaper.ImGui_GetCursorScreenPos(ctx)

    -- Indent content
    reaper.ImGui_Indent(ctx, LAYOUT.indent_width)

    -- Render children
    if node.children then
        for _, child in ipairs(node.children) do
            Renderer.render_node(ctx, child, fonts, state)
        end
    end

    -- Get end position
    local _, end_y = reaper.ImGui_GetCursorScreenPos(ctx)

    -- Draw vertical line on the left
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
    local line_x = start_x + 2
    reaper.ImGui_DrawList_AddLine(
        draw_list,
        line_x, start_y,
        line_x, end_y,
        COLORS.blockquote_line,
        LAYOUT.blockquote_line_width
    )

    reaper.ImGui_Unindent(ctx, LAYOUT.indent_width)
    reaper.ImGui_Spacing(ctx)
end

--- Render horizontal rule
-- @param ctx ReaImGui context
-- @param node table: HR node
-- @param fonts table: Font handles
-- @param state table: Render state
local function render_hr(ctx, node, fonts, state)
    reset_inline_context()
    record_line_position(ctx, node.line_start)

    reaper.ImGui_Spacing(ctx)
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Spacing(ctx)
end

--- Render table cell content inline
-- @param ctx ReaImGui context
-- @param cell table: Cell node with children
-- @param fonts table: Font handles
-- @param state table: Render state
local function render_table_cell_content(ctx, cell, fonts, state)
    if cell.children then
        local first = true
        for _, child in ipairs(cell.children) do
            if child.type == NT.TEXT then
                if not first then
                    reaper.ImGui_SameLine(ctx, 0, 0)
                end
                reaper.ImGui_Text(ctx, child.text or "")
                first = false
            elseif child.type == NT.BOLD then
                if not first then
                    reaper.ImGui_SameLine(ctx, 0, 0)
                end
                if fonts.bold then
                    push_font(ctx, fonts.bold, fonts, "bold")
                end
                for _, sub in ipairs(child.children or {}) do
                    if sub.type == NT.TEXT then
                        reaper.ImGui_Text(ctx, sub.text or "")
                    end
                end
                if fonts.bold then
                    reaper.ImGui_PopFont(ctx)
                end
                first = false
            elseif child.type == NT.LINK then
                if not first then
                    reaper.ImGui_SameLine(ctx, 0, 0)
                end
                local link_text = ""
                for _, sub in ipairs(child.children or {}) do
                    if sub.type == NT.TEXT then
                        link_text = link_text .. (sub.text or "")
                    end
                end
                reaper.ImGui_TextColored(ctx, COLORS.link, link_text)
                if reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseClicked(ctx, 0) then
                    if state then state.clicked_link = child.url end
                end
                first = false
            end
        end
    end
end

--- Render table
-- @param ctx ReaImGui context
-- @param node table: Table node
-- @param fonts table: Font handles
-- @param state table: Render state
local function render_table(ctx, node, fonts, state)
    reset_inline_context()
    record_line_position(ctx, node.line_start)

    if not node.rows or #node.rows == 0 then
        return
    end

    -- Calculate column count from first row
    local col_count = 0
    if node.rows[1] and node.rows[1].cells then
        col_count = #node.rows[1].cells
    end

    if col_count == 0 then return end

    -- Add extra column for region selector in scenario mode
    local scenario_enabled = state and state.scenario_enabled
    local total_cols = scenario_enabled and (col_count + 1) or col_count

    -- Begin table with borders
    local table_flags = reaper.ImGui_TableFlags_Borders()
                     + reaper.ImGui_TableFlags_RowBg()
                     + reaper.ImGui_TableFlags_SizingStretchProp()

    if reaper.ImGui_BeginTable(ctx, "md_table_" .. node.line_start, total_cols, table_flags) then
        -- Setup columns - stretch for content, fixed width for Link column
        for i = 1, col_count do
            reaper.ImGui_TableSetupColumn(ctx, "col" .. i)
        end
        if scenario_enabled then
            -- Link column: fixed width (80px for [color] [+] and [N] buttons)
            local col_flags = reaper.ImGui_TableColumnFlags_WidthFixed()
            reaper.ImGui_TableSetupColumn(ctx, "Link", col_flags, 80)
        end

        -- Render rows
        local data_row_index = 0  -- Track non-header rows for duplicate names

        for row_idx, row in ipairs(node.rows) do
            reaper.ImGui_TableNextRow(ctx)

            -- Check if this row should be highlighted (scenario mode)
            local row_line_start = row.line_start or (node.line_start + row_idx)
            local row_line_end = row.line_end or row_line_start
            local row_highlighted, row_highlight_color = should_highlight(state, row_line_start, row_line_end)

            -- Apply highlight background color to row (use category color)
            if row_highlighted then
                reaper.ImGui_TableSetBgColor(ctx, reaper.ImGui_TableBgTarget_RowBg0(), row_highlight_color or 0x3366CC66)
            end

            -- If this is the header row, make it bold
            local is_header = row.is_header

            -- Render original cells
            for col_idx, cell in ipairs(row.cells or {}) do
                if col_idx <= col_count then
                    reaper.ImGui_TableSetColumnIndex(ctx, col_idx - 1)

                    if is_header and fonts.bold then
                        push_font(ctx, fonts.bold, fonts, "bold")
                    end

                    render_table_cell_content(ctx, cell, fonts, state)

                    if is_header and fonts.bold then
                        reaper.ImGui_PopFont(ctx)
                    end
                end
            end

            -- Render region selector column
            if scenario_enabled then
                reaper.ImGui_TableSetColumnIndex(ctx, col_count)

                if is_header then
                    -- Header for link column
                    if fonts.bold then
                        push_font(ctx, fonts.bold, fonts, "bold")
                    end
                    reaper.ImGui_Text(ctx, "Link")
                    if fonts.bold then
                        reaper.ImGui_PopFont(ctx)
                    end
                else
                    -- Data row - show region dropdown
                    data_row_index = data_row_index + 1
                    local identifier = get_row_identifier(row)
                    local row_line_start = row.line_start or (node.line_start + row_idx)
                    local row_line_end = row.line_end or row_line_start

                    render_region_selector(
                        ctx, state,
                        row_line_start, row_line_end,
                        identifier, "table_row", data_row_index
                    )
                end
            end
        end

        reaper.ImGui_EndTable(ctx)
    end

    reaper.ImGui_Spacing(ctx)
end

-- ===============================================================================
-- NODE DISPATCHER
-- ===============================================================================

--- Render a single AST node recursively
-- @param ctx ReaImGui context
-- @param node table: AST node to render
-- @param fonts table: Font handles
-- @param state table: Render state
function Renderer.render_node(ctx, node, fonts, state)
    if not node or not node.type then
        return
    end

    local node_type = node.type

    if node_type == NT.DOCUMENT then
        -- Document is just a container
        if node.children then
            for _, child in ipairs(node.children) do
                Renderer.render_node(ctx, child, fonts, state)
            end
        end

    elseif node_type == NT.HEADING then
        render_heading(ctx, node, fonts, state)

    elseif node_type == NT.PARAGRAPH then
        render_paragraph(ctx, node, fonts, state)

    elseif node_type == NT.TEXT then
        render_text(ctx, node, fonts, state)

    elseif node_type == NT.BOLD then
        render_bold(ctx, node, fonts, state)

    elseif node_type == NT.ITALIC then
        render_italic(ctx, node, fonts, state)

    elseif node_type == NT.CODE_INLINE then
        render_code_inline(ctx, node, fonts, state)

    elseif node_type == NT.CODE_BLOCK then
        render_code_block(ctx, node, fonts, state)

    elseif node_type == NT.LIST_UL then
        render_list_ul(ctx, node, fonts, state)

    elseif node_type == NT.LIST_OL then
        render_list_ol(ctx, node, fonts, state)

    elseif node_type == NT.LIST_ITEM then
        -- List items are typically rendered by their parent list
        -- But handle standalone case
        start_inline_context()
        if node.children then
            for _, child in ipairs(node.children) do
                Renderer.render_node(ctx, child, fonts, state)
            end
        end
        reset_inline_context()

    elseif node_type == NT.BLOCKQUOTE then
        render_blockquote(ctx, node, fonts, state)

    elseif node_type == NT.LINK then
        render_link(ctx, node, fonts, state)

    elseif node_type == NT.HR then
        render_hr(ctx, node, fonts, state)

    elseif node_type == NT.TABLE then
        render_table(ctx, node, fonts, state)

    else
        -- Unknown node type - render as text if possible
        if node.text then
            handle_inline_spacing(ctx)
            reaper.ImGui_Text(ctx, node.text)
        end
    end
end

-- ===============================================================================
-- MAIN RENDER FUNCTION
-- ===============================================================================

--- Render parsed markdown AST to ReaImGui
-- @param ctx ReaImGui context
-- @param ast table: Document node from Parser.parse()
-- @param fonts table: Font table with normal, bold, italic, etc.
-- @param state table: State for scroll sync and interaction
--   state.scroll_y = current scroll position (read)
--   state.scroll_to_line = line to scroll to (write, then nil)
--   state.highlight_lines = {start=N, stop=M} or nil
--   state.clicked_link = url if link was clicked (write)
function Renderer.render(ctx, ast, fonts, state)
    -- Initialize state if needed
    state = state or {}

    -- Clear line positions for this render pass
    line_positions = {}

    -- Reset inline context
    reset_inline_context()

    -- Handle scroll-to-line request
    if state.scroll_to_line then
        -- We need to find the Y position for this line
        -- This might need a two-pass approach: first render to collect positions,
        -- then scroll. For now, we'll try to use cached positions.
        local target_y = line_positions[state.scroll_to_line]
        if target_y then
            -- Get window position to convert screen to scroll coordinates
            local _, window_y = reaper.ImGui_GetCursorScreenPos(ctx)
            local scroll_target = target_y - window_y
            reaper.ImGui_SetScrollY(ctx, scroll_target)
            state.scroll_to_line = nil  -- Clear the request
        end
        -- If position not found yet, it will be found on next frame
    end

    -- Read current scroll position
    if state then
        state.scroll_y = reaper.ImGui_GetScrollY(ctx)
    end

    -- Render the AST
    if ast then
        Renderer.render_node(ctx, ast, fonts, state)
    end

    -- After rendering, handle scroll-to-line if position is now available
    if state.scroll_to_line then
        local target_y = line_positions[state.scroll_to_line]
        if target_y then
            local _, window_y = reaper.ImGui_GetWindowPos(ctx)
            local scroll_target = target_y - window_y
            reaper.ImGui_SetScrollY(ctx, scroll_target)
            state.scroll_to_line = nil
        end
    end
end

--- Get recorded line positions (for external scroll sync)
-- @return table: Map of line_start -> Y coordinate
function Renderer.get_line_positions()
    return line_positions
end

-- ===============================================================================
-- CHECKPOINT: md_renderer.lua COMPLETE
-- Exported:
--   Renderer.render(ctx, ast, fonts, state) - Main render function
--   Renderer.render_node(ctx, node, fonts, state) - Render single node
--   Renderer.get_line_positions() - Get line->Y coordinate map
-- Required fonts: normal, bold, italic, bold_italic, h1, h2, h3, code
-- State: {scroll_y, scroll_to_line, highlight_lines, clicked_link}
-- ===============================================================================

return Renderer
