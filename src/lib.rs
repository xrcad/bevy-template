use bevy::prelude::*;

/// Android entry point. The #[bevy_main] macro generates the
/// android_main function that NativeActivity calls into.
#[bevy_main]
fn main() {
    run();
}

pub fn run() {
    App::new()
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                resizable: true,
                ..default()
            }),
            ..default()
        }))
        .run();
}
