//TODO 
// [ ] add rodio
// [ ] make the rest of the game

use std::env;
use std::sync::{Arc, Mutex};
use macroquad::prelude::*;
use macroquad::audio::{load_sound, play_sound, play_sound_once, PlaySoundParams, Sound};
use mlua::prelude::*;
use mlua::{Lua, LuaOptions, StdLib, Result};
use std::fs;
use std::rc::Rc;
use std::cell::RefCell;

#[derive(Clone, Debug, PartialEq)]
struct Level {
  lua_script: String,
  children: Vec<Level>,
}

struct LevelTree {
  current: Level,
  buffer: Level,
}

impl LevelTree {
  fn traverse(&mut self, idx: usize) -> Option<&Level> {
   if idx < self.current.children.len() {
    self.current = self.current.children[idx].clone();
    Some(&self.current)
   } else {
    // invalid branch
    None
   }
  }
  fn add_child(&mut self, child: Level) {
     self.current.children.push(child);
  }
}

struct LuaSound(Sound); 
impl LuaUserData for LuaSound {
  fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
     methods.add_method("play_once", |_, this, (): ()| {
       play_sound_once(&this.0);
       Ok(())
     });
  }
}

impl LuaSound {
  async fn new(path: String) -> Self {
    LuaSound(load_sound(&path).await.expect("ERROR: could not load sound"))
  }
}

#[derive(Clone)]
struct LuaLevel(Level);
impl LuaUserData for LuaLevel {
  fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {

  }
}
impl LuaLevel {
  fn new(lua_script: String) -> Self {
   LuaLevel(Level { lua_script, children: Vec::new() })
  }
}
struct LuaTexture2D(Texture2D);
impl LuaUserData for LuaTexture2D{
  fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
   methods.add_method("width", |_, this, ()| Ok(this.0.width()));
   methods.add_method("height", |_, this, ()| Ok(this.0.height()));
   methods.add_method_mut("update", |_, this, (image): (LuaAnyUserData)| {
    let image = image.borrow::<LuaImage>()?;
    this.0.update(&image.0);
    Ok(())
   });
  }
}

fn draw_tint(pct: f32) {
  draw_rectangle(0.0, 0.0, screen_width(), screen_height(), Color::new(0.0, 0.0, 0.0, pct));
}

struct LuaImage(Image);

impl LuaUserData for LuaImage {
  fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M ) {
   methods.add_method("width", |_, this, ()| Ok(this.0.height()));
   methods.add_method("height", |_, this, ()| Ok(this.0.height()));
   methods.add_method_mut("set_pixel", |_, this, (x, y, r, g, b, a): (u32, u32, f32, f32, f32, f32)| {
    this.0.set_pixel(x, y, Color::new(r, g, b, a));
    Ok(())
   });
   methods.add_method("get_pixel", |_, this, (x, y): (u32, u32) | {
    let pixel = this.0.get_pixel(x, y);
    Ok((pixel.r, pixel.g, pixel.b, pixel.a))
   });
   methods.add_method("to_texture", |_, this, ()| {
    let texture = Texture2D::from_image(&this.0);
    Ok(LuaTexture2D(texture))
   });
   methods.add_method_mut("invert_pixels", |_, this, ()| {
    invert_all_pixels(&mut this.0);
    Ok(())
   });
   methods.add_method("clone", |_, this, ()| {
    Ok(LuaImage(this.0.clone()))
   });
   methods.add_method_mut("draw_circle", |_, this, (x, y, radius, r, g, b, a): (u32, u32, u32, f32, f32, f32, f32)| {
      for w in std::cmp::min(0, x - radius)..std::cmp::min(this.0.width()  as u32, x+radius) {
     for h in std::cmp::min(0, y - radius)..std::cmp::min(this.0.height() as u32 , y+radius) {
        let dx: u32 = w - x;
        let dy: u32 = h - y;

        if dx*dx + dy*dy <= radius*radius {
         this.0.set_pixel(w, h, Color {r, g, b, a})  
        } 
     }
    }
      Ok(())
   });
  }
}

impl LuaImage {
  fn new(width: u16, height: u16) -> Self {
   LuaImage(Image::gen_image_color(width, height, Color::new(0.0, 0.0, 0.0, 0.0)))
  }
}

async fn send_fns_to_lua(lua: &Lua, level_path: Arc<Mutex<String>>, level_tree: Arc<Mutex<LevelTree>>) -> LuaResult<()> {

  let globals = lua.globals();
  
  globals.set("add_level", lua.create_function_mut(move |_, path: String| {
    let mut level_path = match level_path.lock() {
      Ok(existing_path) => existing_path,
      Err(_) => return Err(LuaError::RuntimeError("ERROR: Could not lock level_path".to_string()))
    };
    *level_path = path;
    println!("INFO: level_path set to path");
   Ok(()) 
  })?)?;
  let tree_cl = level_tree.clone();

  // returns 0 upon success
  globals.set("change_level", lua.create_function_mut(move |_, script: String| {
    println!("INFO: Change level called (at least)");
    let mut tree = match tree_cl.lock() {
      Ok(existing_tree) => existing_tree,
      Err(_) => return Err(LuaError::RuntimeError("ERROR: Could not lock level tree".to_string())),
    };
    let mut found = 99999;
    for (i, _) in tree.current.children.iter().enumerate() {
      if tree.current.children[i].lua_script == script {
        found = i
      }
    }
    // if we have found 
    if found < 99999 {
      tree.current = tree.current.children[found].clone();
      println!("INFO: CHANGED LEVEL");
      return Ok(0)
    }
    Ok(1)
  })?)?;

  globals.set("new_image", lua.create_function(|_, (width, height): (u16, u16)| {
   Ok(LuaImage::new(width, height))
  })?)?;

  globals.set("new_sound", lua.create_async_function(|_, path: String | async move{
    Ok(LuaSound::new(path).await)
  })?)?;

  globals.set("draw_tint", lua.create_function(|_, pct: f32| {
   draw_tint(pct);
   Ok(()) 
  })?)?;

  globals.set("load_texture", lua.create_async_function(|_, path: String| async move {
   match macroquad::texture::load_texture(&path).await {
    Ok(texture) => Ok(LuaTexture2D(texture)),
    Err(err) => Err(LuaError::RuntimeError(err.to_string())),
   }
  })?)?;

  globals.set("draw_texture", lua.create_function(|_, (texture, x, y): (LuaAnyUserData, f32, f32)| {
   let texture = texture.borrow::<LuaTexture2D>()?;
   macroquad::texture::draw_texture(&texture.0, x, y, WHITE);
   Ok(())
  })?)?;

  globals.set("new_level", lua.create_function(|_, lua_script: String| {
   Ok(LuaLevel::new(lua_script))
  })?)?;

  globals.set("play_sound", lua.create_async_function(|_, wav_path: String| async move {
    let sound = load_sound(&wav_path).await.expect("ERROR: Failed to load sound");
    play_sound(&sound, PlaySoundParams {
      looped: false,
      volume: 1.0
    });
    Ok(())
  })?)?;
  
  // returns 1 if lmb has been pressed once
  globals.set("mouse_clicked", lua.create_function(|_, ():()| {
   let mut pressed: u8 = 0;
   if is_mouse_button_pressed(MouseButton::Left) {
    pressed = 1;
   }
   Ok(pressed)
  })?)?;

  globals.set("screen_height", lua.create_function(|_, ():()| {
   Ok(screen_height())
  })?)?;

  globals.set("screen_width", lua.create_function(|_, ():()| {
   Ok(screen_width())
  })?)?;
  globals.set("mouse_position", lua.create_function(|_, ():()|{
   let (x, y) = mouse_position();
   let (rx, ry) = (x as u32, y as u32);
   Ok((rx, ry))
  })?)?;

  globals.set("draw_texture_part", lua.create_function(
  |_, (
    texture,
    source_x,
    source_y,
    source_w,
    source_h,
    dest_x,
    dest_y,
    rotation,
    scale,
   ):
   (
    LuaAnyUserData,
    f32,
    f32,
    f32,
    f32,
    f32,
    f32,
    f32,
    f32
   )|{
    let texture = texture.borrow::<LuaTexture2D>()?;
    texture.0.set_filter(FilterMode::Nearest);
    let source = Rect::new(source_x, source_y, source_w, source_h);
    let dest = Vec2::new(dest_x, dest_y);
    macroquad::texture::draw_texture_ex(
     &texture.0,
     dest.x,
     dest.y,
     WHITE,
     DrawTextureParams {
      source: Some(source),
      dest_size: Some(Vec2::new(source_w * scale, source_h * scale)),
      rotation,
      flip_x: false,
      flip_y: false,
      pivot: None,
     }
    );
    Ok(())
   })?)?;
  
  globals.set("is_key_down", lua.create_function(|_, key_code: String| {
   let key = match key_code.as_str() {
    "W" => KeyCode::W,
    "A" => KeyCode::A,
    "S" => KeyCode::S,
    "D" => KeyCode::D,
    "Space" => KeyCode::Space,
    _ => return Err(LuaError::RuntimeError("Invalid key".to_string())),
   };
   Ok(is_key_down(key))
  })?)?;

  Ok(())
}

fn invert_all_pixels(img: &mut Image) {
  for x in 0..img.width() as u32 {
   for y in 0..img.height() as u32 {
    let col = img.get_pixel(x, y);
    if col.r > 0.9 {
     img.set_pixel(x, y, BLACK);
    } else {
     img.set_pixel(x, y, WHITE);
    }
   }
  }
}

fn runtime_manager() {

}

async fn handle_tree(level_path: Arc<Mutex<String>>, level_tree: Arc<Mutex<LevelTree>>, lua: &mut Lua) {
  if let Ok(mut path) = level_path.lock() {
    if !path.is_empty() {
      if let Ok(mut tree) = level_tree.lock() {
        let new_lvl = Level {
          lua_script: path.clone(),
          children: Vec::new(),
        };
        tree.add_child(new_lvl);
        println!("INFO: Added child level");
        *path = String::new();
        println!("INFO: Cleared path");

      }
    }
  }

  let tree_cl = level_tree.clone();

  if let Ok(mut tree) = level_tree.lock() {
    if tree.current.lua_script != tree.buffer.lua_script{
      // we need to update the lua runtime to the new level...
      println!("INFO: Rinsing lua runtime");
      let mut new_lua = Lua::new();
      let lua_script = fs::read_to_string(&tree.current.lua_script).expect("ERROR: Could not load script from file.");
      new_lua.load(&lua_script).exec().expect("ERROR: failed to load lua script.");
      *lua = new_lua;
      tree.buffer = tree.current.clone();
      let path = Arc::new(Mutex::new(tree.current.lua_script.clone().to_string()));
      println!("INFO: Sending fns to the lua runtime. Wish us luck.");
      send_fns_to_lua(lua, path, tree_cl).await.expect("ERROR: Failed to send fns to lua.");
      println!("INFO: Sent fns to new lua runtime :) ");
    }
  }
}

#[macroquad::main("ERODE")]
async fn main() {
  set_fullscreen(true);
  // this is the initial level the 
  // player starts at
  // (the startup screen)
  let mut startup_screen = Level {
    lua_script: "levels/startup-screen.lua".to_string(),
    children: vec![],
  };
  let mut lua = Lua::new();
  let level_tree = Arc::new(Mutex::new(LevelTree { current: startup_screen.clone(), buffer: startup_screen.clone() }));
  let level_path = Arc::new(Mutex::new(String::new()));
  send_fns_to_lua(&lua, level_path.clone(), level_tree.clone()).await.expect("Failed to send fns to lua!");
  let tree_cl = level_tree.clone();
  if let Ok(tree) = tree_cl.lock() {
    let lua_script = fs::read_to_string(&tree.current.lua_script).expect("ERROR: could not load lua script from file.");
    lua.load(&lua_script).exec().expect("failed to load lua script!!");
  } else {
    panic!("ERROR: Uh Oh - could not lock and load tree/script");
  }

  loop {
    if screen_width() < 1200. {
      set_fullscreen(true);
      next_frame().await
    } else {
      clear_background(BLUE);
      handle_tree(level_path.clone(), level_tree.clone(), &mut lua).await;
      // look for the Lua `update` function and call it if it exists
      if let Ok(update_fn) = lua.globals().get::<_, mlua::Function>("update") {
        if let Err(e) = update_fn.call::<_, ()>(()) {
        eprintln!("ERROR: Lua update function failed: {}", e);
      }
      } else {
        eprintln!("ERROR: No 'update' function found in Lua");
      }
      // print fps info (for development purposes)
      let fps: i32 = get_fps();
      draw_text(&format!("FPS: {}", fps), 20.0, 20.0, 30.0, WHITE);

      next_frame().await
     }
  }
}
