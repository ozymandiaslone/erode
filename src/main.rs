use macroquad::prelude::*;
use mlua::prelude::*;
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
        methods.add_method("to_texture", |_, this, ()| {
            let texture = Texture2D::from_image(&this.0);
            Ok(LuaTexture2D(texture))
        });
    }
}

impl LuaImage {
    fn new(width: u16, height: u16) -> Self {
        LuaImage(Image::gen_image_color(width, height, Color::new(0.0, 0.0, 0.0, 0.0)))
    }
}

async fn send_fns_to_lua(lua: &Lua, level_tree: Rc<RefCell<LevelTree>>) -> LuaResult<()> {

    let globals = lua.globals();
    let level_tree_clone = Rc::clone(&level_tree);
    globals.set("choose_next_level", lua.create_function_mut(move |_, branch: usize| {
        let mut level_tree = level_tree_clone.borrow_mut();
        if let Some(_) = level_tree.traverse(branch) {
            Ok(())
        } else {
            Err(LuaError::RuntimeError("ERROR: Invalid branch traversal index".to_string()))
        }
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

    globals.set("new_level", lua.create_function(|_, (lua_script): (String)| {
        Ok(LuaLevel::new(lua_script))
    })?)?;

    globals.set("screen_height", lua.create_function(|_, ():()| {
        Ok(screen_height())
    })?)?;

    globals.set("screen_width", lua.create_function(|_, ():()| {
        Ok(screen_width())
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

fn runtime_manager() {

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
    let level_tree = Rc::new(RefCell::new(LevelTree { current: startup_screen }));
    send_fns_to_lua(&lua, level_tree.clone()).await.expect("Failed to send fns to lua!");

    let tree = level_tree.borrow();
    let lua_script = fs::read_to_string(&tree.current.lua_script).expect("ERROR: could not load lua script from file.");
    lua.load(&lua_script).exec().expect("failed to load lua script!!");

    loop {
        if screen_width() < 1200. {
            set_fullscreen(true);
            next_frame().await
        } else {

            clear_background(BLUE);
            // Fetch the Lua `update` function and call it if it exists
            if let Ok(update_fn) = lua.globals().get::<_, mlua::Function>("update") {
                if let Err(e) = update_fn.call::<_, ()>(()) {
                    eprintln!("ERROR: Lua update function failed: {}", e);
                }
            } else {
                eprintln!("ERROR: No 'update' function found in Lua");
            }

            // print fps info (for development purposes)
            let fps = get_fps();
            draw_text(&format!("FPS: {}", fps), 20.0, 20.0, 30.0, WHITE);

            next_frame().await
        }
    }
}
