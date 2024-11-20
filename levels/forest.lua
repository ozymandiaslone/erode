local state = {
  setup = nil,
  cam_pos = {0, 0},
  enum = {
    leaving_forest = true,
    returning_forest = nil,
    forest_moving = nil,
    village_beginning = nil,
    village_end = nil,
  }
}

function update()
  if not state.setup then setup() end
  handle_inputs()
  update_entities()
  draw_entities()
end

function update_entities()
  if state.enum.leaving_forest then
    update_cart_frames()
    update_texture_positions()
    update_wizard_frames()
  elseif state.enum.returning_forest then
    
  elseif state.enum.village_beginning then

  elseif state.enum.village_end then
  end

end

function draw_entities() 
  if state.enum.leaving_forest then 
    draw_forest()
    draw_wizard()
  elseif state.enum.returning_forest then
  elseif state.enum.village_beginning then
  elseif state.enum.village_end then
  end
end

function setup() 
  state.assets = {
    leaving_village_sky = setup_bg_asset("assets/leaving-village-sky.png"),
    far_trees = setup_bg_asset("assets/demon_woods/layers/parallax-demon-woods-far-trees.png"),
    mid_trees = setup_bg_asset("assets/demon_woods/layers/parallax-demon-woods-mid-trees.png"),
    near_trees = setup_bg_asset("assets/demon_woods/layers/parallax-demon-woods-close-trees.png"),
    wizard_burst = setup_bg_asset("assets/wizard-sprite-burst.png"),
    cart = setup_bg_asset("assets/carriage.png"),
  }
  -- setup the cart's animations
  setup_cart_animations()
  setup_wizard_animations()

  state.setup = true 
end

function setup_bg_asset(path) 
  return { texture = load_texture(path), pos = {0, 0} }
end

-- TODO FIX THIS FN
function update_cart_frames()
  local time_now = os.clock()
  local direction = state.assets.cart.direction
  local animation = state.assets.cart.animations[direction]
  local frame = animation.frames[animation.current_frame]
  local dt = time_now - animation.last_time
  if dt > animation.interval and state.enum.forest_moving then
    animation.current_frame = (animation.current_frame % 3) + 1
    animation.last_time = time_now
  end
end

function update_wizard_frames()
  local time_now = os.clock()
  local direction = state.assets.wizard_burst.direction
  local animation = state.assets.wizard_burst.animations[direction]
  local frame = animation.frames[animation.current_frame]
  local dt = time_now - animation.last_time
  if dt > animation.interval then
    animation.current_frame = (animation.current_frame % 6) + 1
    animation.last_time = time_now
  end
end


function draw_cart()

  local direction = state.assets.cart.direction
  local animation = state.assets.cart.animations[direction]
  local frame = animation.frames[animation.current_frame]

  if not frame then
    print("ERROR: frame " .. tostring(level.player.animation.current_frame) .. " is nil")
    return
  end
  draw_texture_part(
    state.assets.cart.texture,
    frame.x,
    frame.y,
    frame.w,
    frame.h,
    state.assets.cart.x,
    state.assets.cart.y,
    0,
    state.assets.cart.scale  -- Scale
  )
end

function setup_wizard_animations()
  local x0 = 0 
  local frame_width = 40 
  local frame_height = 40 
  local frame_gap = 0  
  local y0 = 0 
  local directions = {"left"}

  state.assets.wizard_burst.animations = {}

  for dir, direction in ipairs(directions) do
    state.assets.wizard_burst.animations[direction] = {frames = {}, current_frame = 1, interval = 0.014, last_time = os.clock()}
    for frame = 1, 6 do
      state.assets.wizard_burst.animations[direction].frames[frame] = {
        x = x0 + (frame - 1) * (frame_width + frame_gap),
        y = y0 + (dir - 1) * (frame_height + frame_gap),
        w = frame_width,
        h = frame_height
      }
      print("ADDED WIZARD FRAME")
    end
  end
  state.assets.wizard_burst.direction = "left"
  state.assets.wizard_burst.scale = 5 
end

function draw_wizard()
  local direction = state.assets.wizard_burst.direction
  local animation = state.assets.wizard_burst.animations[direction]
  local frame = animation.frames[animation.current_frame]

  if not frame then
    print("ERROR: frame " .. tostring(level.player.animation.current_frame) .. " is nil")
    return
  end
  draw_texture_part(
    state.assets.wizard_burst.texture,
    frame.x,
    frame.y,
    frame.w,
    frame.h,
    0,
    0,
    0,
    state.assets.wizard_burst.scale  -- Scale
  )

end

function setup_cart_animations()
  local x0 = 0 
  local frame_width = 30 
  local frame_height = 30 
  local frame_gap = 0  
  local y0 = 0 
  local directions = {"right"}

  state.assets.cart.animations = {}

  for dir, direction in ipairs(directions) do
    state.assets.cart.animations[direction] = {frames = {}, current_frame = 1, interval = 0.03, last_time = os.clock()}
    for frame = 1, 3 do
      state.assets.cart.animations[direction].frames[frame] = {
        x = x0 + (frame - 1) * (frame_width + frame_gap),
        y = y0 + (dir - 1) * (frame_height + frame_gap),
        w = frame_width,
        h = frame_height
      }
    end
  end

  state.assets.cart.direction = "right"
  state.assets.cart.scale = 10
  state.assets.cart.x = (screen_width() * 0.5) - (state.assets.cart.scale * state.assets.cart.texture:width()) * 0.4
  state.assets.cart.y = screen_height() - ((state.assets.cart.scale * state.assets.cart.texture:height()) + screen_height() * 0.18) 

end


function draw_forest() 
  -- first draw the background
  local bg_pos = state.assets.leaving_village_sky.pos
  local bg_scl
  state.assets.leaving_village_sky.pos, bg_scl  = draw_scaled(state.assets.leaving_village_sky.texture, bg_pos)
  state.assets.leaving_village_sky.scl = bg_scl

  -- next we draw the furthest layer of trees
  local far_trees_pos = state.assets.far_trees.pos
  local far_trees_scl
  state.assets.far_trees.pos, far_trees_scl = draw_scaled(state.assets.far_trees.texture, far_trees_pos)
  state.assets.far_trees.scl = far_trees_scl

  -- now the mid trees...
  local mid_trees_pos = state.assets.mid_trees.pos
  local mid_trees_scl
  state.assets.mid_trees.pos, mid_trees_scl = draw_scaled(state.assets.mid_trees.texture, mid_trees_pos)
  state.assets.mid_trees.scl = mid_trees_scl

  -- next, we draw the cart
  draw_cart()

  -- finally, draw the near trees
  local near_trees_pos = state.assets.near_trees.pos
  local near_trees_scl
  state.assets.near_trees.pos, near_trees_scl = draw_scaled(state.assets.near_trees.texture, near_trees_pos)
  state.assets.near_trees.scl = near_trees_scl
end

function draw_scaled(texture, position)
  local texture_w = texture:width()
  local texture_h = texture:height()
  local scl_x = screen_width() / texture_w
  local scl_y = screen_height() / texture_h
  local scl = math.max(scl_x, scl_y)
  local scaled_texture_w = texture_w * scl
  local wrap_threshold = -scaled_texture_w


  if position[1] * scl < wrap_threshold then
    position[1] = position[1] + scaled_texture_w / scl
    if position[1] * scl < wrap_threshold * 2 then
      position[1] = 0
    end
  end

  local y = position[2]
--  local texture_x = (x * scl)

  --if texture_x < wrap_threshold then
   -- texture_x = texture_x + scaled_texture_w
  --end

  -- wrap the texture coordinate based on its width
  draw_texture_part(texture, 0, 0, texture_w, texture_h, position[1] * scl, y, 0, scl)

  -- draw the texture to the right, if needed
  local texture_end_x = (position[1] * scl)+ (texture_w * scl)
  if texture_end_x < screen_width() then
    draw_texture_part(texture, 0, 0, texture_w, texture_h, texture_end_x, y, 0, scl)
  end

  return {position[1], position[2]}, scl
end

-- this code is bad
function update_texture_positions()
  local far_trees_pos = state.assets.far_trees.pos
  if not state.assets.far_trees.scl then
    state.assets.far_trees.scl = math.max(screen_width() / state.assets.far_trees.texture:width(), screen_height() / state.assets.far_trees.texture:height())
  end
  local mid_trees_pos = state.assets.mid_trees.pos
  if not state.assets.mid_trees.scl then
    state.assets.mid_trees.scl = math.max(screen_width() / state.assets.mid_trees.texture:width(), screen_height() / state.assets.mid_trees.texture:height())
  end
  local near_trees_pos = state.assets.near_trees.pos
  if not state.assets.near_trees.scl then
    state.assets.near_trees.scl = math.max(screen_width() / state.assets.near_trees.texture:width(), screen_height() / state.assets.near_trees.texture:height())
  end


  far_trees_pos[1] = (state.cam_pos[1]) % -state.assets.far_trees.texture:width()
  mid_trees_pos[1] = (2 * state.cam_pos[1]) % -state.assets.mid_trees.texture:width()
  near_trees_pos[1] = (3 * state.cam_pos[1]) % -state.assets.near_trees.texture:width()


end


-- TODO FIX THIS - MOVEMENT SPEED IS BASED ON frame rate (not dt)
function handle_inputs()
  state.enum.forest_moving = nil
  if is_key_down("W") then
  end
  if is_key_down("A") then
    -- move left 
    state.cam_pos[1] = state.cam_pos[1] + 0.2
    state.enum.forest_moving = true
  end
  if is_key_down("S") then

  end
  if is_key_down("D") then
    -- move right
    state.cam_pos[1] = state.cam_pos[1] - 0.2 
    state.enum.forest_moving = true
  end
end


