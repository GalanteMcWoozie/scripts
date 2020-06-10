script_name('MM Master')
script_author('me')

require "lib.moonloader"
local keys                = require "vkeys"
local imgui               = require "imgui"
local encoding            = require "encoding"
local fa                  = require "faIcons"
local inicfg              = require "inicfg"
local dlstatus            = require('moonloader').download_status
local notify              = import "lib_imgui_notf.lua"
local fa_glyph_ranges	    = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
encoding.default          = 'CP1251'
u8                        = encoding.UTF8

update_state = false

local update_url          = 'https://raw.githubusercontent.com/GalanteMcWoozie/scripts/master/update.ini'
local update_path         = getWorkingDirectory() .. "/update.ini"

-- local script_url          = 'https://raw.githubusercontent.com/GalanteMcWoozie/scripts/master/MM%20Master.lua'
local script_path         = thisScript().path
local script_vers         = 1.2

local MColor              = 0xFFFFFF
local main_window_state   = imgui.ImBool(false)
local second_window_state = imgui.ImBool(false)
local text_buffer         = imgui.ImBuffer(256)

local sw, sh = getScreenResolution()

function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig() -- to use 'imgui.ImFontConfig.new()' on error
        font_config.MergeMode = true
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fontawesome-webfont.ttf', 14.0, font_config, fa_glyph_ranges)
    end
end

function imgui.TextColoredRGB(text, render_text)
    local max_float = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end

            local length = imgui.CalcTextSize(w)
            if render_text == 2 then
                imgui.NewLine()
                imgui.SameLine(max_float / 2 - ( length.x / 2 ))
            elseif render_text == 3 then
                imgui.NewLine()
                imgui.SameLine(max_float - length.x - 5 )
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], text[i])
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(w) end


        end
    end

    render_text(text)
end


function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end

	_, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	nick  = sampGetPlayerNickname(id)

	sampRegisterChatCommand("update", cmd_update)

	notify.addNotify("{E57525}[MM Master] {FFFFFF}Скрипт запущен", "\nСкрипт успешно запущен­\nТекущая версия: {E57525}v." .. script_vers, 2, 2, 5)

print("Checking updates for script")
	downloadUrlToFile(update_url, update_path, function(id, status)
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			print("update.ini was loaded")
			updateIni = inicfg.load(nil, update_path)
			if tonumber(updateIni.info.vers) > script_vers then
				notify.addNotify("{E57525}[MM Master]{FFFFFF} Доступно обновление на: {E57525}v." .. tonumber(updateIni.info.vers) .. "\n(Текущая версия: {e57525}v." .. script_vers .. "{FFFFFF})", 2, 2, 6)
				print("Founded {e57525}new version")
				print("Old version: {E57525}" .. script_vers)
				print("New version: {E57525}" .. updateIni.info.vers)
			elseif tonumber(updateIni.info.vers) == script_vers then
				print("No updates matched")
			end
			print("Deleting update.ini")
			os.remove(update_path)
		end
	end)

	while true do
		wait(0)
		downloadUrlToFile(script_url, script_path, function(id, status)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage("{E57525}[MM Master]{FFFFFF} Скрипт успешно обновлен с {E57525}v." .. script_vers .. " {FFFFFF}на {E57525}v." .. updateIni.info.vers, -1)
				thisScript():reload()
			end
		end)
		break
	end
end
-- new string
