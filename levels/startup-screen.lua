
---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global
---@diagnostic disable: undefined-field



local state = {
  setup = nil,
  square_image = nil,
  square_texture = nil,
  screen_width = 0,
  screen_height = 0,
  last_update = nil,
  column = 0,
  right = 0
}
local font = {
  A = {
    "01110",
    "10001",
    "10001",
    "11111",
    "10001",
    "10001",
    "10001",
  },

}

function update()
  if not state.setup then setup() end
  update_state()
  draw()
end

function update_state()
  -- draw this column either white or black
  for y = 0, state.screen_height - 1 do
    r,g,b,a = state.square_image:get_pixel(state.column, y)
    if r == 0 then
      state.square_image:set_pixel(state.column, y, 1, 1, 1, 1)
      state.square_image:set_pixel(state.column + 1, y, 1, 1, 1, 1)
    else
      state.square_image:set_pixel(state.column, y, 0, 0, 0, 1)
      state.square_image:set_pixel(state.column + 1, y, 0, 0, 0, 1)
    end
  end

  -- increment the column just once
  if state.column > state.screen_width - 3 then
    state.column = 0
    if state.right == 1 then
      state.right = 0
    else
      state.right = 1
    end
  else
    state.column = state.column + 2
  end

  -- handle mouse
  x, y = mouse_position()
  if x and y then
     if x > state.column then
      -- on right side of line 
      if state.right == 0 then
        draw_circle(x, y, 50, 0, 0, 0, 1, state.square_image)
      else
        draw_circle(x, y, 50, 1, 1, 1, 1, state.square_image)
      end
    else
      if state.right == 0 then
        draw_circle(x, y, 50, 1, 1, 1, 1, state.square_image)
      else
        draw_circle(x, y, 50, 0, 0, 0, 1, state.square_image)
      end
    end
  end

  draw_inverted_text(100, 100, "A", 5, state.square_image)

  -- update the texture 
  state.square_texture:update(state.square_image)
end

function setup()
  while state.screen_width < 1920 or state.screen_height < 1080  do
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

function draw_circle(x, y, radius, r, g, b, a, image)
  local height = screen_height()
  local width = screen_width()

  for w = math.max(0, x - radius), math.min(width - 1, x + radius) do
    for h = math.max(0, y - radius), math.min(height - 1, y + radius) do
      local dx = w - x
      local dy = h - y
      if dx * dx + dy * dy < radius^2 then
        image:set_pixel(w, h, r, g, b, a)
      end
    end
  end
end


function invert_pixel(x, y, image)
    local r, g, b, a = image:get_pixel(x, y)
    if r ==1 then
        image:set_pixel(x, y, 0, 0, 0, 1)
    elseif r == 0 then
        image:set_pixel(x, y, 1, 1, 1, 1)
    end
end

function draw_inverted_text(x, y, text, scale, image)
    for i = 1, #text do
        local char = text:sub(i, i)
        local glyph = font[char]
        if glyph then
            for gy = 1, #glyph do
                for gx = 1, #glyph[gy] do
                    if glyph[gy]:sub(gx, gx) == "1" then
                        for sx = 0, scale - 1 do
                            for sy = 0, scale - 1 do
                                local px = x + (i - 1) * 6 * scale + (gx - 1) * scale + sx
                                local py = y + (gy - 1) * scale + sy
                                invert_pixel(px, py, image)
                            end
                        end
                    end
                end
            end
        end
    end
end
function draw_inverse_circle(x, y, radius, image)
  local count = 0
  local height = screen_height()
  local width = screen_width()

  for w = math.max(0, x - radius), math.min(width - 1, x + radius) do
    for h = math.max(0, y - radius), math.min(height - 1, y + radius) do
      local dx = w - x
      local dy = h - y
      if dx * dx + dy * dy < radius^2 then
        r, g, b, a = image:get_pixel(w, h)
        if r == 1 then
          image:set_pixel(w, h, 0, 0, 0, 1)
        else
          image:set_pixel(w, h, 1, 1, 1, 1)
        end
      end
    end
  end
end
