//! Horizon on Android (crate horizon-android): the binary's `game.rs` behind a NativeActivity.
//! The game folder is the app's external files folder, with the prepared resources
//! pushed to `<files>/.local/horizon-client/26.3` (the client's default) (adb can write there, the app needs no permission).
mod game;

use horizon_client::{crash, logging};
use winit::platform::android::activity::AndroidApp;

#[unsafe(no_mangle)]
fn android_main(app: AndroidApp) {
    let home = app
        .external_data_path()
        .or_else(|| app.internal_data_path())
        .expect("Android gives the app a files folder");
    // SAFETY: nothing else runs yet; the game reads these on this thread later.
    unsafe {
        std::env::set_var("HOME", &home);
        std::env::set_var("HORIZON_HOME", &home);
    }
    std::env::set_current_dir(&home).expect("the files folder exists");
    let _ = horizon_client::window::ANDROID_APP.set(app);
    logging::init(&home, "Render thread");
    crash::install(home.clone(), "client");
    if let Err(error) = game::run() {
        log::error!("Horizon: {error}");
        crash::report_error(&home, "client", &*error);
    }
    logging::flush();
}
