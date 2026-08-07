local Element = require('elements/Element')
local mp_utils = require('mp.utils')

local function load_media_format_info()
	local candidates = {
		mp.command_native({'expand-path', '~~/script-modules/media-format-info.lua'}),
	}
	local source = debug.getinfo(1, 'S').source:gsub('^@', '')
	local script_dir = select(1, mp_utils.split_path(source))
	local parent = ''
	for _ = 1, 4 do
		parent = parent .. '../'
		candidates[#candidates + 1] = mp_utils.join_path(
			script_dir, parent .. 'script-modules/media-format-info.lua'
		)
	end
	for _, path in ipairs(candidates) do
		local ok, result = pcall(dofile, path)
		if ok and type(result) == 'table' then return result end
	end
	error('无法加载 media-format-info.lua')
end

local MediaFormatInfo = load_media_format_info()

---@class MediaInfo : Element
local MediaInfo = class(Element)

-- 与参考版一致的胶囊几何参数（逻辑像素，随 uosc/DPI 缩放）
local MEDIA_INFO_FONT_SIZE = 16
local MEDIA_INFO_CAPSULE_HEIGHT = 27
local MEDIA_INFO_TIMELINE_OFFSET = 30
local MEDIA_INFO_PICTURE_INSET = 10
local MEDIA_INFO_LETTER_SPACING = 0.2

local function format_rate(bits_per_second)
	local value = tonumber(bits_per_second) or 0
	if value <= 0 then return '' end
	if value >= 100000000 then return string.format('%d Mbps', math.floor(value / 1000000 + 0.5)) end
	if value >= 1000000 then return string.format('%.1f Mbps', value / 1000000) end
	return string.format('%d Kbps', math.floor(value / 1000 + 0.5))
end

local function read_bitrate()
	local bitrate = mp.get_property_number('video-bitrate', 0)
	if bitrate > 0 then return format_rate(bitrate) end
	local track = mp.get_property_native('current-tracks/video', {})
	bitrate = type(track) == 'table' and tonumber(track['demux-bitrate']) or 0
	if bitrate and bitrate > 0 then return format_rate(bitrate) end
	local size = mp.get_property_number('file-size', 0)
	local duration = mp.get_property_number('duration', 0)
	if size > 0 and duration > 0 then return format_rate(size * 8 / duration) end
	return ''
end

local function read_network_speed()
	local path = mp.get_property('path', ''):lower()
	if not path:match('^%a[%w+.-]*://') then return '' end
	local bytes = mp.get_property_number('cache-speed', 0)
	if bytes <= 0 then return '' end
	if bytes >= 1024 * 1024 then return string.format('↓ %.1f MB/s', bytes / 1024 / 1024) end
	return string.format('↓ %d KB/s', math.floor(bytes / 1024 + 0.5))
end

-- 信箱黑边时返回视频画面的纵向范围（uosc 坐标），用于把胶囊夹在画面内
local function get_video_display_vertical_bounds()
	local dimensions = mp.get_property_native('osd-dimensions', {})
	local osd_height = type(dimensions) == 'table' and tonumber(dimensions.h) or nil
	local display_height = tonumber(display.height)
	if not osd_height or osd_height <= 0 or not display_height or display_height <= 0 then
		return nil, nil
	end
	local scale_y = display_height / osd_height
	local top = clamp(0, (tonumber(dimensions.mt) or 0) * scale_y, display_height)
	local bottom = clamp(0, (osd_height - (tonumber(dimensions.mb) or 0)) * scale_y, display_height)
	if bottom <= top then return nil, nil end
	return top, bottom
end

local function append(parts, text, tone, group, compact_before)
	if text and text ~= '' then
		parts[#parts + 1] = {
			text = tostring(text),
			tone = tone or 'base',
			group = group or 'base',
			compact_before = compact_before == true,
		}
	end
end

local function build_segments()
	local info = MediaFormatInfo.collect()
	if not info.video_present then return {} end
	local parts = {}
	-- 硬解/软解放在最前，一眼确认当前解码状态
	if info.hwdec == 'HW' then
		append(parts, '硬解', 'muted', 'decode')
	else
		append(parts, '软解', 'muted', 'decode')
	end
	append(parts, info.resolution_long, 'primary', 'picture')
	if info.dynamic_range ~= '' then
		append(parts, info.dynamic_range, 'hero', 'picture')
	end
	append(parts, info.video_codec, 'primary', 'video')
	append(parts, info.fps_label, 'muted', 'video')
	if info.audio_codec ~= '' or info.audio_layout ~= '' then
		append(parts, info.audio_codec, 'primary', 'audio')
		append(parts, info.audio_layout, 'muted', 'audio')
	end
	local output_format = mp.get_property('audio-out-params/format', ''):lower()
	if output_format:find('spdif-', 1, true) == 1 then
		append(parts, '源码直通', 'hero', 'audio', true)
	end
	local bitrate = read_bitrate()
	if bitrate ~= '' then
		append(parts, '码率', 'muted', 'throughput')
		append(parts, bitrate, 'primary', 'throughput', true)
	end
	local network = read_network_speed()
	if network ~= '' then
		append(parts, '网络', 'muted', 'throughput')
		append(parts, network, 'primary', 'throughput', true)
	end
	return parts
end

-- 参考版胶囊渲染：按视觉分组（硬解+画面归 picture），hero/primary/muted 三档配色
local function render_segments(ass, x, y, segments, visibility, max_width)
	local scale = state.scale
	local size = round(MEDIA_INFO_FONT_SIZE * scale)
	local item_gap = round(12 * scale)
	local compact_gap = round(5 * scale)
	local capsule_gap = round(7 * scale)
	local capsule_padding = round(9 * scale)
	local capsule_height = round(MEDIA_INFO_CAPSULE_HEIGHT * scale)
	local capsule_radius = round(5 * scale)
	local cursor_x = x
	local max_x = max_width and (x + max_width) or display.width
	local base_opts = {
		size = size,
		color = config.color.menu_text or config.color.time_current or bgt,
		opacity = visibility * 0.98,
		border = math.max(1, options.text_border * scale),
		border_color = bg,
		shadow = 0,
		bold = false,
	}
	local hero_accent = config.color.menu_active or config.color.match
		or config.color.menu_foreground or fg
	local function visual_group(segment)
		local group = segment.group or segment.tone or 'base'
		if group == 'decode' or group == 'picture' then return 'picture' end
		return group
	end

	local groups = {}
	for _, segment in ipairs(segments) do
		local text = segment.text or ''
		if text ~= '' then
			local key = visual_group(segment)
			local group = groups[#groups]
			if not group or group.key ~= key then
				group = {key = key, segments = {}}
				groups[#groups + 1] = group
			end
			group.segments[#group.segments + 1] = segment
		end
	end

	for _, group in ipairs(groups) do
		local content_width = 0
		local prepared = {}
		local hero_group = false
		for index, segment in ipairs(group.segments) do
			local text_opts = table_assign({}, base_opts)
			if segment.tone == 'hero' then
				hero_group = true
				text_opts.color = config.color.match or hero_accent
				text_opts.opacity = visibility * 0.92
				text_opts.bold = true
			elseif segment.tone == 'primary' then
				text_opts.opacity = visibility
				text_opts.bold = true
			elseif segment.tone == 'muted' then
				text_opts.color = config.color.time_current or bgt
				text_opts.opacity = visibility * 0.90
			end
			if segment.text:match('^[%w%s%./%-]+$') then
				text_opts.spacing = MEDIA_INFO_LETTER_SPACING * scale
			end
			local width = text_width(segment.text, text_opts)
			if text_opts.spacing then width = width + math.max(0, #segment.text - 1) * text_opts.spacing end
			local gap_before = segment.compact_before and compact_gap or item_gap
			prepared[#prepared + 1] = {
				segment = segment,
				opts = text_opts,
				width = width,
				gap_before = gap_before,
			}
			if index > 1 then content_width = content_width + gap_before end
			content_width = content_width + width
		end

		local capsule_width = content_width + capsule_padding * 2
		local leading_gap = cursor_x > x and capsule_gap or 0
		if cursor_x + leading_gap + capsule_width > max_x then break end
		cursor_x = cursor_x + leading_gap

		ass:rect(cursor_x, y - capsule_height / 2, cursor_x + capsule_width, y + capsule_height / 2, {
			color = config.color.menu_background or bg,
			border = math.max(0.75, 0.85 * scale),
			border_color = hero_group and hero_accent
				or config.color.menu_foreground or config.color.timeline_track or fg,
			opacity = {
				main = visibility * 0.38,
				border = visibility * (hero_group and 0.54 or 0.44),
			},
			radius = capsule_radius,
		})

		local text_x = cursor_x + capsule_padding
		for index, item in ipairs(prepared) do
			if index > 1 then text_x = text_x + item.gap_before end
			ass:txt(text_x, y, 4, item.segment.text, item.opts)
			text_x = text_x + item.width
		end

		cursor_x = cursor_x + capsule_width
	end
end

function MediaInfo:new() return Class.new(self) --[[@as MediaInfo]] end

function MediaInfo:init()
	Element.init(self, 'media_info', {render_order = 5.5, anchor_id = 'controls'})
	local function refresh() request_render() end
	for _, property in ipairs({
		'hwdec-current', 'video-params', 'estimated-vf-fps', 'container-fps',
		'video-bitrate', 'audio-codec', 'audio-params', 'audio-out-params/format',
		'current-tracks/video', 'current-tracks/audio', 'cache-speed',
	}) do
		self:observe_mp_property(property, 'native', refresh)
	end
	self:register_mp_event('file-loaded', refresh)
	self:register_mp_event('video-reconfig', refresh)
end

function MediaInfo:on_display() request_render() end
function MediaInfo:on_options() request_render() end

-- 供速度滑块等元素对齐胶囊高度
function MediaInfo:get_height()
	return round(MEDIA_INFO_CAPSULE_HEIGHT * state.scale)
end

-- 供速度滑块等元素对齐胶囊字号
function MediaInfo:get_font_size()
	return round(MEDIA_INFO_FONT_SIZE * state.scale)
end

-- 供速度滑块等元素对齐胶囊中心（与 render 中 mi_y 同一计算）
function MediaInfo:get_center_y()
	local timeline = Elements.timeline
	if not (timeline and timeline.enabled and timeline.size > 0) then return nil end
	local scale = state.scale
	local bar_height = math.max(3, round(4 * scale))
	local hit_bay = timeline.by - timeline.size - timeline.top_border
	local bay = hit_bay + (timeline.size - bar_height) / 2
	local mi_y = bay - round(MEDIA_INFO_TIMELINE_OFFSET * scale)
	-- 与 render 相同的信箱黑边夹持，保证胶囊和滑块在任何画幅下都对齐
	local picture_top, picture_bottom = get_video_display_vertical_bounds()
	if picture_top and picture_bottom then
		local half_height = round(MEDIA_INFO_CAPSULE_HEIGHT * scale) / 2
		local picture_inset = round(MEDIA_INFO_PICTURE_INSET * scale)
		local min_y = picture_top + picture_inset + half_height
		local max_y = picture_bottom - picture_inset - half_height
		if min_y <= max_y then mi_y = clamp(min_y, mi_y, max_y) end
	end
	return mi_y
end

function MediaInfo:render()
	if not state.is_video or state.is_idle then return end
	local visibility = self:get_visibility()
	if visibility <= 0 then return end
	local segments = build_segments()
	if #segments == 0 then return end

	local scale = state.scale
	local ass = assdraw.ass_new()

	-- 与参考版一致：胶囊悬在时间轴上方约 45px，而不是贴进底部面板
	local timeline = Elements.timeline
	if not (timeline and timeline.enabled and timeline.size > 0) then return ass end
	local bar_height = math.max(3, round(4 * scale))
	local hit_bay = timeline.by - timeline.size - timeline.top_border
	local bay = hit_bay + (timeline.size - bar_height) / 2
	local mi_x = timeline.ax
	local mi_y = bay - round(MEDIA_INFO_TIMELINE_OFFSET * scale)

	-- 信箱黑边时把整行文字夹在视频画面内，避免胶囊落在黑边上
	local picture_top, picture_bottom = get_video_display_vertical_bounds()
	if picture_top and picture_bottom then
		local half_height = round(MEDIA_INFO_CAPSULE_HEIGHT * scale) / 2
		local picture_inset = round(MEDIA_INFO_PICTURE_INSET * scale)
		local min_y = picture_top + picture_inset + half_height
		local max_y = picture_bottom - picture_inset - half_height
		if min_y <= max_y then mi_y = clamp(min_y, mi_y, max_y) end
	end

	render_segments(ass, mi_x, mi_y, segments, visibility, timeline.bx - mi_x)
	return ass
end

return MediaInfo
