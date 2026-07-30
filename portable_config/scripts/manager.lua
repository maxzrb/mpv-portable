local msg = require 'mp.msg'

local running = false

local function expand_path(path)
    return mp.command_native({'expand-path', path})
end

local function show_result(success, result)
    running = false

    local stdout = result and result.stdout or ''
    local stderr = result and result.stderr or ''
    local status = result and result.status or -1

    if stdout ~= '' then
        msg.info(stdout)
    end
    if stderr ~= '' then
        msg.warn(stderr)
    end

    if success and status == 0 then
        mp.osd_message('安全更新完成，请查看控制台或更新报告', 5)
    else
        mp.osd_message('安全更新未完成，请查看控制台错误', 6)
        msg.error('manager update failed, exit status:', status)
    end
end

local function update_all()
    if running then
        mp.osd_message('更新任务正在运行', 3)
        return
    end

    local config_dir = expand_path('~~/')
    local helper = expand_path('~~/script-modules/manager-update.ps1')
    local args = {
        'powershell.exe',
        '-NoLogo',
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        helper,
        '-ConfigDir',
        config_dir,
    }

    running = true
    mp.osd_message('正在安全检查更新，不会直接覆盖个性化修改…', 4)
    msg.info('starting safe component update')

    local command = {
        name = 'subprocess',
        args = args,
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
    }

    if mp.command_native_async then
        mp.command_native_async(command, show_result)
    else
        local result = mp.command_native(command)
        show_result(result and result.status == 0, result)
    end
end

mp.register_script_message('manager-update-all', update_all)
mp.add_key_binding(nil, 'manager-update-all', update_all)
