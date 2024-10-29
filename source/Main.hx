import flixel.FlxG;
import openfl.display.FPS;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite {
	public static var fpsVar:FPS;

	final gameWidth = 1280;
	final gameHeight = 720;
	final initialState:Class<flixel.FlxState> = TitleState;
	var framerate = 60u32;
	final skipSplash = true; // Whether to skip the flixel splash screen that appears in release mode.
	final startFullscreen = false;

	public function new() {
		super();

		CrashHandler.init();
		var o = null;
		o();

		#if !debug
		initialState = TitleState;
		#end

		addChild(new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen));
	
		#if !mobile
		fpsVar = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		#end

		ClientPrefs.loadPrefs();
		Main.fpsVar.x = ClientPrefs.showFPS ? 10 : -100;

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
	}
}