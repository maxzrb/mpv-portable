# AGENTS.md - MPV Configuration Repository

## Repository Overview

**MPV media player configuration repository** for Windows. Contains Lua scripts, configuration files, OSC themes, and GLSL shaders.

**Structure:**
```
mpv/
├── portable_config/       # Main configuration directory
│   ├── scripts/           # Lua scripts (.lua)
│   ├── script-opts/       # Script configuration files (.conf)
│   ├── script-modules/    # Shared script modules
│   ├── osc-style/         # On-screen controller themes
│   ├── shaders/           # GLSL video shaders (34 categories)
│   ├── profiles.conf      # Configuration profiles
│   ├── mpv.conf           # Main MPV configuration
│   ├── input.conf         # Key bindings
│   └── manager.json       # Script manager sources
├── lua/                   # Lua runtime libraries
└── doc/                   # Documentation
```

## Build / Test / Validation

**No traditional build system** - this is a configuration repository.

### Validation Commands:
```bash
# Test MPV starts without errors (isolated script test)
mpv.exe --no-config --script=portable_config/scripts/your-script.lua

# Check Lua syntax (requires Lua)
luac -p portable_config/scripts/your-script.lua

# Test with a video file
mpv.exe --no-config --script=portable_config/scripts/your-script.lua video.mkv
```

### Testing Workflow:
1. Edit script in `portable_config/scripts/`
2. Update config in `portable_config/script-opts/` if needed
3. Test: `mpv.exe --no-config video-file.mkv`
4. Check console for script errors

### Debugging:
```bash
mpv.exe --log-file=output.txt video.mkv
```

## Code Style Guidelines

### File Organization
- **Scripts**: `portable_config/scripts/*.lua`
- **Configs**: `portable_config/script-opts/*.conf` (must match script name)
- **Modules**: `portable_config/script-modules/`
- **OSC themes**: `portable_config/osc-style/*.lua`
- **Profiles**: `portable_config/profiles.conf`
- **Shaders**: `portable_config/shaders/<category>/*.glsl`

### Lua Conventions
- **Imports**: Use single quotes (`require 'mp.msg'`)
- **Variables**: `local` for ALL variables (never global unless module export)
- **Options table**: Named `o` when using `mp.options`
- **Naming**: Variables=snake_case, Functions=PascalCase/snake_case, Constants=UPPER_CASE
- **Comments**: `-- Single line` or `--[[ Multi-line ]]`
- **Error handling**: Use pcall for optional modules, `msg.error` (NEVER print)
- **Graceful degradation**: Provide fallbacks when optional features unavailable

```lua
-- Options pattern (standard)
local o = { option1 = 'default', option2 = true }
options.read_options(o)

-- pcall for optional modules
local input_loaded, input = pcall(require, "mp.input")
if input_loaded then
    -- use module
else
    -- fallback
end

-- Set helper
function Set(t)
    local set = {}
    for _, v in pairs(t) do set[v] = true end
    return set
end
```

### MPV API
```lua
mp.register_script_message('message-name', handler)
mp.add_key_binding('KEY', 'binding-name', callback)
mp.observe_property('property', 'type', callback)
mp.commandv('command', 'arg1', 'arg2')
```

### Configuration Files (.conf)
Format: `key=value` pairs, one per line
```conf
# Comments start with #
option_name=value
```

### File Encoding
- **UTF-8** required, **Unix line endings** (LF)

## Shader Organization

Shaders are organized into 34 categories under `portable_config/shaders/`:

| Category | Purpose |
|----------|---------|
| AA | Anti-aliasing algorithms |
| ACNet | 2D animation super-resolution |
| Adaptive_sharpen | Adaptive sharpening |
| AiUpscale | AI-based upscaling |
| AMD | AMD CAS/FSR algorithms |
| Ani | ArtCNN-based 2D animation upscaling |
| Anime4K | 2D animation upscaling |
| ArtCNN | 2D animation super-resolution |
| Canvas | Canvas/effects tools |
| CfL | Chroma from Luma restoration |
| CuNNy | 2D anime super-resolution |
| Deband | Debanding algorithms |
| EDI | Edge-directed interpolation |
| ESRGAN | ESRGAN super-resolution |
| ETC | Miscellaneous effects |
| FSRCNNX | FSRCNNX super-resolution |
| SSim | SSim scale optimization |
| USM | Unsharp mask sharpening |
| color | Color adjustment tools |

**Shader path format**: `~~/shaders/<category>/<shader_name>.glsl`

## Script Template
```lua
--[[
  * scriptname.lua v.1.0.0
  * AUTHORS: author-name
  * License: MIT
]]

local msg = require 'mp.msg'
local options = require 'mp.options'

local o = { option1 = 'default' }
options.read_options(o)

mp.add_key_binding('KEY', 'action-name', callback)
```

### Module Structure (script-modules/)
```lua
local M = {}
function M.public_function() end
return M
```

## Important Conventions

1. **Script-Config Matching**: `scriptname.lua` → `scriptname.conf`
2. **Path Expansion**: Use `~~/` for mpv config directory
3. **Script Messages**: lowercase with hyphens (`message-name`)
4. **Key Bindings**: descriptive names (`browse-files`)
5. **External Scripts**: `manager.json` defines git sources
6. **Shader paths in input.conf**: Use `~~/shaders/<category>/<name>.glsl`

## Common Pitfalls

- ❌ Global variables (causes conflicts between scripts)
- ❌ Silent errors (always use `msg.error`)
- ❌ `print()` (use `msg.info/warn/error`)
- ❌ Hardcoded paths (use `~~/` or `mp.command_native({"expand-path", ...})`)
- ❌ Old shader paths like `shaders/igv/*`, `shaders/nnedi3/*`, `shaders/ravu/*`
- ✅ DO read options from `script-opts/` directory
- ✅ DO use `local` everywhere
- ✅ DO handle optional dependencies gracefully
- ✅ DO test with `--no-config` to isolate issues
- ✅ DO use new shader paths: `shaders/FSRCNNX/*`, `shaders/EDI/*`, `shaders/RAISR/*`

## Resources

- [MPV Manual](https://mpv.io/manual/master/)
- [MPV Lua Scripting](https://mpv.io/manual/master/#lua-scripting)
- [MPV API Reference](https://mpv.io/manual/master/#list-of-input-properties)
- [Shader Wiki](https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL)