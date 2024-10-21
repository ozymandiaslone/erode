use std::env;
use std::sync::{Arc, Mutex};
use macroquad::prelude::*;
use mlua::prelude::*;
use mlua::{Lua, LuaOptions, StdLib, Result};
use std::fs;
use std::rc::Rc;
use std::cell::RefCell;

#[derive(Clone)]
struct Level {
  lua_script: String,
  children: Vec<Level>,
}

struct LevelTree {
  current: Level,
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
    Ok((LuaImage(this.0.clone())))
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
//  let level_tree_clone = Rc::clone(&level_tree);
  /*
  globals.set("choose_next_level", lua.create_function_mut(move |_, branch: usize| {
   let mut level_tree = match level_tree_clone.try_borrow_mut() {
        Ok(tree) => tree,
        Err(_) => return Err(LuaError::RuntimeError("ERROR: Could not borrow level tree mutably.".to_string())),
    };
   if let Some(_) = level_tree.traverse(branch) {
    Ok(())
   } else {
    Err(LuaError::RuntimeError("ERROR: Invalid branch traversal index".to_string()))
   }
  })?)?;
  let level_tree_clone = Rc::clone(&level_tree);
  */
  globals.set("add_level", lua.create_function_mut(move |_, path: String| {


    let mut level_path = match level_path.lock() {
      Ok(existing_path) => existing_path,
      Err(_) => return Err(LuaError::RuntimeError("ERROR: Could not mutably borrow level tree".to_string()))
    };
    *level_path = path;
    println!("INFO: level_path set to path");

   Ok(()) 
  })?)?;

  globals.set("new_image", lua.create_function(|_, (width, height): (u16, u16)| {
   Ok(LuaImage::new(width, height))
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

fn handle_tree(level_path: Arc<Mutex<String>>, level_tree: Arc<Mutex<LevelTree>>) {
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
}

#[macroquad::main("ERODE")]
async fn main() {


  // maybe in the future to manage levels,
  // I should create / kill a lua runtime
  // for each level, that way I think
  // I could potentially even maybe 
  // reuse the rust loop logic, where
  // each lua level has a sorta generic
  // update fn which does whatever it wants
  set_fullscreen(true);
  let mut startup_screen = Level {
    lua_script: "levels/startup-screen.lua".to_string(),
    children: vec![],
  };
  let lua = Lua::new();
  let level_tree = Arc::new(Mutex::new(LevelTree { current: startup_screen }));
  let level_path = Arc::new(Mutex::new(String::new()));
  send_fns_to_lua(&lua, level_path.clone(), level_tree.clone()).await.expect("Failed to send fns to lua!");
  let tree_cl = level_tree.clone();
  if let Ok(tree) = tree_cl.lock() {
    let lua_script = fs::read_to_string(&tree.current.lua_script).expect("ERROR: could not load lua script from file.");
    lua.load(&lua_script).exec().expect("failed to load lua script!!");
  } else {
    panic!("ERROR: Uh Oh - could not lock/load tree/script");
  }

  loop {
    if screen_width() < 1200. {
      set_fullscreen(true);
      next_frame().await
    } else {
      clear_background(BLUE);
      handle_tree(level_path.clone(), level_tree.clone());
      // Fetch the Lua `update` function and call it if it exists
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
