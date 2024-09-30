-- TODO -- OVERVIEW -- 
-- fix movement (not crucial) [ ] 
-- add player animations [ ] 
--

---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global
local level = {
  sky = nil,
  city = nil,
  road = nil,
  setup = nil,
  player = {
    x = 0,
    y = 0,
    texture = nil,
    animation = {
      frames = {},
      current_frame = 1,
      interval = 0.19,
      last_time = 0
    }
  }
}

function setup()
  -- TODO put some of this stuff in its own fn
  while not level.sky or not level.city or not level.road or not level.player.texture do
    if not level.sky then level.sky = load_texture("assets/Sky_pale.png") end
    if not level.city then level.city = load_texture("assets/Back_pale.png") end
    if not level.road then level.road = load_texture("assets/road&lamps_pale.png") end
    if not level.player.texture then level.player.texture = load_texture("assets/idle.png") end
  end
  setup_player_animations()
  level.setup = true
end

function setup_player_animations()
  local x0 = 32
  local frame_width = 16
  local frame_height = 16
  local frame_gap = 64
  local y0 = 32

  -- idle right anim (4 frames)
  for i = 1, 4 do
    level.player.animation.frames[i] = {
      x = x0 + (i - 1) * (frame_width + frame_gap),
      y = y0,
      w = frame_width,
      h = frame_height
    }
    print("Frame " .. i .. " initialized: ", level.player.animation.frames[i].x)
  end
end

function update_player_frames()
  local time_now = os.clock()
  local dt = time_now - level.player.animation.last_time
  if dt > level.player.animation.interval then
    advance_frame()
    level.player.animation.last_time = time_now
  end
end

function advance_frame()
  level.player.animation.current_frame = (level.player.animation.current_frame % 4) + 1
end

function draw_player()
  local frame = level.player.animation.frames[level.player.animation.current_frame]
  if not frame then
    print("Error: frame " .. tostring(level.player.animation.current_frame) .. " is nil")
    return
  end
  draw_texture_part(
    level.player.texture,
    frame.x,
    frame.y,
    frame.w,
    frame.h,
    level.player.x,
    level.player.y,
    0,
    4.4  -- Scale
  )
end

-- TODO FIX THIS - MOVEMENT SPEED IS BASED ON FRAME RATE (not dt)
function handle_inputs()
  if is_key_down("W") then
    level.player.y = level.player.y - 6
  end
  if is_key_down("A") then
    level.player.x = level.player.x - 6
  end
  if is_key_down("S") then
    level.player.y = level.player.y + 6
  end
  if is_key_down("D") then
    level.player.x = level.player.x + 6
  end
end

function update()
  if not level.setup then setup() end
  handle_inputs()
  update_player_frames()
  draw()
end

function draw()
  draw_texture(level.sky, 0, 0)
  draw_texture(level.city, 0, 0)
  draw_texture(level.road, 0, 0)
  draw_tint(0.35)
  draw_player()
end
