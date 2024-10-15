local state = {
  setup = nil,
  square_image = nil,
  square_texture = nil,
  screen_width = 0,
  screen_height = 0,
}

function update()
  if not state.setup then setup() end
  draw()
end


function setup()
  while state.screen_width < 1200 or state.screen_height < 800  do
    state.screen_width = screen_width() 
    state.screen_height = screen_height()
  end
  while not state.square_image do 
      state.square_image = new_image(state.screen_width, state.screen_height)
  end

  local width = state.screen_width
  local height = state.screen_height
  

  for y = 0, height - 1 do
      for x = 0, width - 1 do
          state.square_image:set_pixel(x, y, 1.0, 1.0, 1.0, 1.0)
      end
  end

  if not state.square_texture then 
      state.square_texture = state.square_image:to_texture()
  end
  state.setup = true
end

function draw()
  draw_texture(state.square_texture, 0, 0)
end


