local state = {
  setup = nil,
  cam_pos = {0, 0},
}

function update()
  if not state.setup then setup() end
  handle_inputs()
  update_texture_positions()
  draw_background()
end

function setup() 
  state.assets = {
    forest_bg = setup_bg_asset("assets/demon_woods/layers/parallax-demon-woods-bg.png"),
    far_trees = setup_bg_asset("assets/demon_woods/layers/parallax-demon-woods-far-trees.png"),
    mid_trees = setup_bg_asset("assets/demon_woods/layers/parallax-demon-woods-mid-trees.png"),
    near_trees = setup_bg_asset("assets/demon_woods/layers/parallax-demon-woods-close-trees.png"),
  }
  state.setup = true 
end

function setup_bg_asset(path) 
  return { texture = load_texture(path), pos = {0, 0} }
end

function draw_background() 
  -- first draw the background
  local bg_pos = state.assets.forest_bg.pos
  local bg_scl
  state.assets.forest_bg.pos, bg_scl  = draw_scaled(state.assets.forest_bg.texture, bg_pos)
  state.assets.forest_bg.scl = bg_scl
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
  -- finally the near trees
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
  if is_key_down("W") then

  end
  if is_key_down("A") then
    -- move left 
    state.cam_pos[1] = state.cam_pos[1] + 0.65

  end
  if is_key_down("S") then

  end
  if is_key_down("D") then
    -- move right
    state.cam_pos[1] = state.cam_pos[1] - 0.65 
  end
end


