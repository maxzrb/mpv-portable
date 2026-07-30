-- 在普通 mpv 与 LSFG Vulkan Layer 模式之间按当前进度重启播放

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local config_dir = mp.command_native({ 'expand-path', '~~/' })
local root_dir = utils.join_path(config_dir, '..')
local launcher_path = utils.join_path(root_dir, 'start-mpv-lsfg.ps1')
local lossless_dll = utils.join_path(root_dir, 'Lossless Scaling/Lossless.dll')
local layer_dll = utils.join_path(root_dir, 'lsfg-vk/lsfg-vk-layer.dll')
local request_root = utils.join_path(root_dir, 'lsfg-vk')
local telemetry_path = utils.join_path(root_dir, 'lsfg-vk/telemetry.json')

local active = os.getenv('LSFGVK_ENV') == '1'
    and os.getenv('DISABLE_LSFGVK') ~= '1'
local multiplier = tonumber(os.getenv('LSFGVK_MULTIPLIER')) or 2
local performance = os.getenv('LSFGVK_PERFORMANCE_MODE') == '1'
local overlay_visible = false
local telemetry = nil
local fps_overlay = mp.create_osd_overlay('ass-events')

local function update_user_data()
    local mode = 'off'
    if active then
        mode = string.format('%dx-%s', multiplier, performance and 'performance' or 'quality')
    end

    mp.set_property_native('user-data/lsfg/active', active)
    mp.set_property_native('user-data/lsfg/mode', mode)
    mp.set_property_native('user-data/lsfg/fps-overlay', overlay_visible)
    mp.set_property_native('user-data/lsfg/input-fps', 0)
    mp.set_property_native('user-data/lsfg/output-fps', 0)
end

local function file_exists(path)
    return utils.file_info(path) ~= nil
end

local function append(list, value)
    list[#list + 1] = value
end

local function collect_playback_arguments(clear_all_filters)
    local args = {}
    local time_pos = mp.get_property_number('time-pos', 0)
    local paused = mp.get_property_bool('pause', false)
    local playlist = mp.get_property_native('playlist') or {}
    local playlist_pos = mp.get_property_number('playlist-pos', 0)

    append(args, string.format('--start=%.3f', math.max(time_pos, 0)))
    append(args, paused and '--pause=yes' or '--pause=no')
    if clear_all_filters then
        append(args, '--vf-clr')
        append(args, '--interpolation=no')
    end

    if #playlist > 0 then
        append(args, string.format('--playlist-start=%d', math.max(playlist_pos, 0)))
        for _, item in ipairs(playlist) do
            if item.filename and item.filename ~= '' then
                append(args, item.filename)
            end
        end
    else
        local path = mp.get_property('path')
        if path and path ~= '' then
            append(args, path)
        end
    end

    return args
end

local function launch(disable, requested_multiplier, requested_performance, clear_all_filters)
    if not file_exists(launcher_path) then
        mp.osd_message('LSFG 启动器不存在：' .. launcher_path, 5)
        msg.error('LSFG 启动器不存在：' .. launcher_path)
        return
    end

    if not disable and (not file_exists(lossless_dll) or not file_exists(layer_dll)) then
        mp.osd_message('LSFG 运行文件不完整，请先检查 Lossless Scaling 和 lsfg-vk 目录', 6)
        msg.error('LSFG 运行文件不完整')
        return
    end

    local media_args = collect_playback_arguments(clear_all_filters)
    if #media_args == 0 then
        mp.osd_message('当前没有可重新打开的媒体', 4)
        return
    end

    -- Optimus / 无 VRR 下 Present 速率≠源帧率，将 estimated-vf-fps 写入侧文件供启动脚本读取
    local video_fps = mp.get_property_number('estimated-vf-fps', 0)
    if video_fps and video_fps > 0 then
        local fps_path = utils.join_path(request_root, 'lsfg-source-fps')
        local f = io.open(fps_path, 'w')
        if f then f:write(tostring(video_fps)); f:close() end
    end

    local request_name = string.format('lsfg-request-%s-%d.json',
        tostring(mp.get_property_number('pid', 0)), os.time())
    local request_path = utils.join_path(request_root, request_name)
    local request_file, write_error = io.open(request_path, 'wb')
    if not request_file then
        mp.osd_message('无法写入 LSFG 续播参数：' .. tostring(write_error), 6)
        msg.error('无法写入 LSFG 续播参数：' .. tostring(write_error))
        return
    end
    request_file:write(utils.format_json(media_args))
    request_file:close()

    -- 切换到 LSFG 时先移除其他补帧；清空入口则移除完整滤镜链。
    if clear_all_filters then
        mp.commandv('vf', 'clr', '')
    else
        mp.commandv('vf', 'remove', '@quality-memc')
    end
    mp.set_property_bool('interpolation', false)
    mp.commandv('write-watch-later-config')

    local args = {
        'powershell.exe',
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', launcher_path,
    }

    if disable then
        append(args, '-Disable')
    else
        append(args, '-Multiplier')
        append(args, tostring(requested_multiplier))
        if requested_performance then
            append(args, '-Performance')
        end
    end

    append(args, '-MpvArgumentsFile')
    append(args, request_path)

    local ok, result = pcall(mp.command_native, {
        name = 'subprocess',
        playback_only = false,
        detach = true,
        args = args,
    })

    if not ok or (result and result.status and result.status ~= 0) then
        local detail = not ok and tostring(result)
            or tostring(result.error_string or result.status)
        mp.osd_message('启动新 mpv 失败：' .. detail, 6)
        msg.error('启动新 mpv 失败：' .. detail)
        return
    end

    if disable then
        mp.osd_message('正在关闭 LSFG 并从当前进度重启', 3)
    else
        local preset = requested_performance and '性能' or '质量'
        mp.osd_message(string.format('正在启用 LSFG %d× %s并从当前进度重启',
            requested_multiplier, preset), 3)
    end

    mp.add_timeout(0.35, function()
        mp.commandv('quit')
    end)
end

local function restart_lsfg(value, preset)
    local requested_multiplier = tonumber(value)
    if not requested_multiplier or requested_multiplier < 2 or requested_multiplier > 4 then
        mp.osd_message('LSFG 倍率必须为 2、3 或 4', 4)
        return
    end

    launch(false, requested_multiplier, preset == 'performance')
end

local function close_all_memc()
    if active then
        launch(true)
        return
    end

    mp.commandv('vf', 'remove', '@quality-memc')
    mp.set_property_bool('interpolation', false)
    mp.osd_message('补帧已关闭', 3)
end

local function clear_all_filters()
    if active then
        launch(true, nil, nil, true)
        return
    end

    mp.commandv('vf', 'clr', '')
    mp.set_property_bool('interpolation', false)
    mp.osd_message('全部视频滤镜已清空', 3)
end

local function telemetry_is_fresh()
    if not telemetry or type(telemetry.updated_ms) ~= 'number' then
        return false
    end
    return math.abs(os.time() * 1000 - telemetry.updated_ms) < 3000
end

local function update_fps_overlay()
    if not active or not overlay_visible then
        fps_overlay.data = ''
        fps_overlay:update()
        return
    end

    local width, height = mp.get_osd_size()
    if not width or not height or width <= 0 or height <= 0 then
        return
    end

    local font_size = math.max(22, math.floor(height * 0.026))
    local details
    if telemetry_is_fresh() then
        details = string.format(
            '原始 %.1f FPS\\N实时 %.1f FPS',
            telemetry.input_fps or 0, telemetry.output_fps or 0)
    else
        details = '等待帧率遥测…'
    end

    fps_overlay.res_x = width
    fps_overlay.res_y = height
    fps_overlay.z = 2000
    fps_overlay.data = string.format(
        '{\\an9\\pos(%d,24)\\fnSegoe UI\\fs%d\\bord2\\shad1'
        .. '\\1c&HFFFFFF&\\3c&H000000&}LSFG %d× · %s\\N%s',
        width - 24, font_size, multiplier,
        performance and '性能' or '质量', details)
    fps_overlay:update()
end

local function poll_telemetry()
    if not active then
        return
    end

    local file = io.open(telemetry_path, 'rb')
    if file then
        local content = file:read('*a')
        file:close()
        local parse_ok, parsed = pcall(utils.parse_json, content)
        if parse_ok and type(parsed) == 'table'
                and type(parsed.input_fps) == 'number'
                and type(parsed.output_fps) == 'number' then
            telemetry = parsed
            mp.set_property_native('user-data/lsfg/input-fps', parsed.input_fps)
            mp.set_property_native('user-data/lsfg/output-fps', parsed.output_fps)
        end
    end

    update_fps_overlay()
end

local function sync_fps_overlay(_, browser_open)
    overlay_visible = active and browser_open == true
    mp.set_property_native('user-data/lsfg/fps-overlay', overlay_visible)
    update_fps_overlay()
end

local function show_status()
    if active then
        local rates = telemetry_is_fresh()
            and string.format('\n原始帧率：%.1f FPS\n实时帧率：%.1f FPS',
                telemetry.input_fps or 0, telemetry.output_fps or 0)
            or '\n帧率：等待遥测'
        mp.osd_message(string.format(
            'LSFG 已启用\n倍率：%d×\n模式：%s\n后端：Vulkan Layer%s',
            multiplier, performance and '性能' or '质量', rates), 5)
    else
        mp.osd_message('LSFG 未启用\n可从“视频滤镜 → 补帧”选择测试模式', 5)
    end
end

update_user_data()

mp.register_script_message('lsfg-restart', restart_lsfg)
mp.register_script_message('lsfg-close-all', close_all_memc)
mp.register_script_message('lsfg-clear-all-filters', clear_all_filters)
mp.register_script_message('lsfg-show-status', show_status)

mp.add_periodic_timer(0.25, poll_telemetry)
mp.observe_property(
    'user-data/stats/toggled', 'bool', sync_fps_overlay)

mp.register_event('file-loaded', function()
    if active then
        update_fps_overlay()
    end
end)

mp.register_event('shutdown', function()
    fps_overlay:remove()
end)
