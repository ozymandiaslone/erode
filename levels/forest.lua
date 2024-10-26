local state = {
  setup = nil,
  assets = {},
}

function update()
  if not state.setup then setup() end
  draw_background()
end

function setup() 
  -- load our textures
  state.assets.forest_bg = load_texture("assets/demon_woods/layers/parallax-demon-woods-bg.png") 
  state.assets.far_trees = load_texture("assets/demon_woods/layers/parallax-demon-woods-far-trees.png")

  state.setup = true 
end

function draw_background() 
  -- draw the backmost layer of the background first
  local forest_bg_w = state.assets.forest_bg:width()
  local forest_bg_h = state.assets.forest_bg:height()
  local forest_bg_scl= screen_width() / forest_bg_w 
  draw_texture_part(state.assets.forest_bg, 0, 0, forest_bg_w, forest_bg_h, 0, 0, 0, forest_bg_scl)
  -- next we draw the furthest layer of trees
  local far_trees_w = state.assets.far_trees:width()
  local far_trees_h = state.assets.far_trees:height()
  local far_trees_scl = screen_height() / far_trees_h
  draw_texture_part(state.assets.far_trees, 0, 0, far_trees_w, far_trees_h, 0, 0, 0, far_trees_scl)
  
end
