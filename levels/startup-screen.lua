
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
  right = 0,
  progress = 0
}

-- TODO DEFINTELY move this into its own script
-- FONT RENDERING
local font = {
  [" "] = {
    "00000",
    "00000",
    "00000",
    "00000",
    "00000",
    "00000",
    "00000",
  },
  A = {
    "01110",
    "10001",
    "10001",
    "11111",
    "10001",
    "10001",
    "10001",
  },
  B = {
    "11110",
    "10001",
    "11110",
    "10001",
    "10001",
    "10001",
    "11110"
  },
  C = {
    "01111",
    "10000",
    "10000",
    "10000",
    "10000",
    "10000",
    "01111"
  },
  D = {
    "11110",
    "10001",
    "10001",
    "10001",
    "10001",
    "10001",
    "11110",
  },
  E = {
    "11111",
    "10000",
    "10000",
    "11111",
    "10000",
    "10000",
    "11111"
  },
  F = {
    "11111",
    "10000",
    "10000",
    "11111",
    "10000",
    "10000",
    "10000"
  },
  G = {
    "11111",
    "10000",
    "10000",
    "10011",
    "10001",
    "10001",
    "11111"
  },
  H = {
    "10001",
    "10001",
    "10001",
    "11111",
    "10001",
    "10001",
    "10001"
  },
  I = {
    "11111",
    "00100",
    "00100",
    "00100",
    "00100",
    "00100",
    "11111"
  },
  J = {
    "11111",
    "00001",
    "00001",
    "00001",
    "00001",
    "10011",
    "11110"
  },
  K = {
    "10001",
    "10010",
    "10100",
    "11000",
    "11000",
    "10110",
    "10001",
  },
  L = {
    "10000",
    "10000",
    "10000",
    "10000",
    "10000",
    "10000",
    "11111"
  },
  M = {
    "10001",
    "11011",
    "10100",
    "10001",
    "10001",
    "10001",
    "10001"
  },
  N = {
    "10001",
    "10001",
    "11001",
    "10101",
    "10011",
    "10001",
    "10001",
  },
  O = {
    "00100",
    "01010",
    "10001",
    "10001",
    "10001",
    "01010",
    "00100",
  },
  P = {
    "11110",
    "10001",
    "10001",
    "11110",
    "10000",
    "10000",
    "10000",
  },
  Q = {
    "00100",
    "01010",
    "10001",
    "10001",
    "10101",
    "01010",
    "00101",
  },
  R = {
    "11110",
    "10001",
    "10001",
    "11110",
    "10100",
    "10010",
    "10001",
  },
  S = {
    "01111",
    "10000",
    "10000",
    "01110",
    "00001",
    "00001",
    "11110",
  },
  T = {
    "11111",
    "00100",
    "00100",
    "00100",
    "00100",
    "00100",
    "00100"
  },
  U = {
    "10001",
    "10001",
    "10001",
    "10001",
    "10001",
    "10001",
    "11111",
  },
  V = {
    "10001",
    "10001",
    "10001",
    "10001",
    "11011",
    "11011",
    "11111",
  },
  W = {
    "10001",
    "10001",
    "10001",
    "10001",
    "10101",
    "11011",
    "10001"
  },
  X = {
    "10001",
    "01010",
    "00100",
    "00100",
    "01010",
    "10001",
    "10001",
  },
  Y = {
    "10001",
    "01010",
    "00100",
    "00100",
    "00100",
    "00100",
    "00100",
  },
  Z = {
    "11111",
    "00001",
    "00010",
    "00100",
    "01000",
    "10000",
    "11111",
  },
   ["?"] = {
    "01110",
    "10001",
    "00001",
    "00101",
    "00110",
    "00000",
    "00100",
  },
  ["."] = {
    "00000",
    "00000",
    "00000",
    "00000",
    "00000",
    "11000",
    "11000",
  }
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
     if x > state.column + 50 then
      -- on right side of line 
      if state.right == 0 then
        state.square_image:draw_circle(x, y, 50, 0, 0, 0, 1)
      else
        state.square_image:draw_circle(x, y, 50, 1, 1, 1, 1)
      end
    elseif x < state.column - 50 then
      if state.right == 0 then
        state.square_image:draw_circle(x, y, 50, 1, 1, 1, 1)
      else
        state.square_image:draw_circle(x, y, 50, 0, 0, 0, 1)
      end
    end
  end

  local clicked = mouse_clicked()
  if clicked == 1 then
    state.progress = state.progress + 1
    invert_img_pixels(state.square_image)
  end
  local temp_img = state.square_image:clone()
  draw_text()
  -- update the texture 
  state.square_texture:update(state.square_image)
  state.square_image = temp_img
end

function setup()
  add_level("levels/forest.lua")
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
function match_progress()
  if state.progress == 0 then
    return "BEGIN?"
  elseif state.progress == 1 then
    return "ARE YOU SURE?"
  elseif state.progress == 2 then
    return "DO NOT SAY YOU HAD NO WARNING."
  elseif state.progress == 3 then
    return"YOUR ACTIONS WILL HAVE CONSEQUENCES."
  else
    return ""
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

function invert_img_pixels(img)
  img:invert_pixels()
  if state.right == 1 then state.right = 0 else state.right = 1 end
end

function draw_text()
  local text = match_progress()
  local scale = 7
  local offset_x = #text * 5 * scale / 2
  local offset_y =  7 * scale / 2
  draw_inverted_text(state.screen_width / 2 - offset_x, state.screen_height / 2 + offset_y, text, scale, state.square_image)
end

function draw_inverted_text(x, y, text, scale, image)
  for i = 1, #text do
    local char = text:sub(i, i)
    local glyph = font[char]
    if glyph then
      for gy = 1, #glyph do
        for gx = 1, #glyph[gy] do
          if glyph[gy]:sub(gx, gx) == "1" then
            local base_x = x + (i - 1) * 6 * scale + (gx - 1) * scale
            local base_y = y + (gy - 1) * scale
            for sx = 0, scale - 1 do
              for sy = 0, scale - 1 do
                local px = base_x + sx
                local py = base_y + sy
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
