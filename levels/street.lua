-- TODO -- OVERVIEW -- 
-- fix movement (not crucial) [ ] 
-- add player animations [ ] 

---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global

local level = {
  scenes = {},
  setup = nil,
  player = {
    direction = "left",
    animations = {},
    x = 0,
    y = 0,
  }
  column = {},
}

function update()
  if not level.setup then setup() end
  handle_inputs()
  update_player_frames()
  draw()
end

function setup()
  -- TODO put some of this stuff in its own fn
  while not level.player.texture do
    if not level.player.texture then level.player.texture = load_texture("assets/idle.png") end
  end
  setup_player_animations()
  setup_scenes()
  level.setup = true
end
function setup_demon_woods()
-- assets/demon_woods/layers/parallax-demon-woods-bg.png
  level.scenes.demon_woods = {}
  local woods = level.scenes.demon_woods
  while not woods.parallax_background or not woods.far_trees do
    if not woods.parallax_background then woods.parallax_background = load_texture("assets/demon_woods/layers/parallax-demon-woods-bg.png") end
    if not woods.far_trees then woods.far_trees = load_texture("assets/demon_woods/layers/parallax-demon-woods-far-trees.png")end

  end
end
function setup_scenes()
  setup_street_scene()
  setup_demon_woods()
end
function setup_street_scene()
  level.scenes.street = {}
  local street = level.scenes.street
  while not street.sky or not street.city or not street.road do
    if not street.sky then street.sky = load_texture("assets/Sky_pale.png") end
    if not street.city then street.city = load_texture("assets/Back_pale.png") end
    if not street.road then street.road = load_texture("assets/road&lamps_pale.png") end
  end
end

function setup_player_animations()
  local x0 = 32
  local frame_width = 16
  local frame_height = 16
  local frame_gap = 64
  local y0 = 32
  local directions = {"right", "left", "up", "down"}
  level.player.animations = {}

  for dir, direction in ipairs(directions) do
    level.player.animations[direction] = {frames = {}, current_frame = 1, interval = 0.1, last_time = os.clock()}
    for frame = 1, 4 do
      level.player.animations[direction].frames[frame] = {
        x = x0 + (frame - 1) * (frame_width + frame_gap),
        y = y0 + (dir - 1) * (frame_height + frame_gap),
        w = frame_width,
        h = frame_height
      }
    end
  end
end


-- TODO FIX THIS FN
function update_player_frames()
  local time_now = os.clock()
  local direction = level.player.direction
  local animation = level.player.animations[direction]
  local frame = animation.frames[animation.current_frame]
  local dt = time_now - animation.last_time
  if dt > animation.interval then
    animation.current_frame = (animation.current_frame % 4) + 1
    animation.last_time = time_now
  end
end

function advance_frame()
  level.player.animation.current_frame = (level.player.animation.current_frame % 4) + 1
end

function draw_player()

  local direction = level.player.direction
  local animation = level.player.animations[direction]
  local frame = animation.frames[animation.current_frame]

  if not frame then
    print("ERROR: frame " .. tostring(level.player.animation.current_frame) .. " is nil")
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
    6.  -- Scale
  )
end

-- TODO FIX THIS - MOVEMENT SPEED IS BASED ON (not dt)
function handle_inputs()
  if is_key_down("W") then
    level.player.y = level.player.y - 6
    level.player.direction = "down"
  end
  if is_key_down("A") then
    level.player.x = level.player.x - 6
    level.player.direction = "left"
  end
  if is_key_down("S") then
    level.player.y = level.player.y + 6
    level.player.direction = "up"
  end
  if is_key_down("D") then
    level.player.x = level.player.x + 6
    level.player.direction = "right"
  end
end

function draw()
  local scene = level.scenes.street
  draw_texture(scene.sky, 0, 0)
  draw_texture(scene.city, 0, 0)
  draw_texture(scene.road, 0, 0)
  draw_tint(0.15)
  draw_player()
end

