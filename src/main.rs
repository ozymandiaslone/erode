use macroquad::prelude::*;
use mlua::prelude::*;
use std::fs;

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

async fn send_fns_to_lua(lua: &Lua) -> LuaResult<()> {

    let globals = lua.globals();

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
#[macroquad::main("ERODE")]
async fn main() {

    // maybe in the future to manage levels,
    // I should create / kill a lua runtime
    // for each level, that way I think
    // I could potentially even maybe 
    // reuse the rust loop logic, where
    // each lua level has a sorta generic
    // update fn which does whatever it wants
    let lua = Lua::new();
    set_fullscreen(true);
    send_fns_to_lua(&lua).await.expect("Failed to send fns to lua!");

    let lua_script = fs::read_to_string("levels/street.lua").expect("Uh oh! Couldn't load level");
    lua.load(&lua_script).exec().expect("failed to load lua script!!");

    if let Ok(setup_fn) = lua.globals().get::<_, mlua::Function>("setup") {
        if let Err(e) = setup_fn.call::<_, ()>(()) {
            eprintln!("ERROR: Lua setup failed: {}", e);
        }
    }
    else {
        eprintln!("ERROR: No lua setup found :(");
    }

    
    loop {
        clear_background(BLUE);
        // Fetch the Lua `update` function and call it if it exists
        if let Ok(update_fn) = lua.globals().get::<_, mlua::Function>("update") {
            if let Err(e) = update_fn.call::<_, ()>(()) {
                eprintln!("Lua update function failed: {}", e);
            }
        } else {
            eprintln!("No 'update' function found in Lua");
        }
        // Proceed to the next frame
        //
        let fps = get_fps();
        draw_text(&format!("FPS: {}", fps), 20.0, 20.0, 30.0, WHITE);
        next_frame().await
    }
}
