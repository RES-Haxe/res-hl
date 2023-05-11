package res.bios.hl;

import haxe.Timer;
import haxe.io.Float32Array;
import hl.UI;
import res.audio.IAudioBuffer;
import res.audio.IAudioStream;
import res.bios.common.FileStorage;
import res.input.Key;
import res.storage.Storage;
import sdl.Cursor;
import sdl.GL;
import sdl.Sdl;
import sdl.Window;

final VERTEX_SHADER:String = '#version 150

in vec2 inPos;
in vec2 inTexCoord;

out vec2 texCoord;

void main()
{
    gl_Position = vec4(inPos, 0.0f, 1.0f);
	texCoord = inTexCoord;
}';
final FRAGMENT_SHADER:String = '#version 150

in vec2 texCoord;
out vec4 fragColor;

uniform sampler2D uTexture;

void main()
{
    fragColor = texture(uTexture, texCoord);
}';

class BIOS extends res.bios.BIOS {
	final _scale:Int;
	final _windowTitle:String;

	@:allow(res.bios.hl)
	var audio:Audio;

	var _quit:Bool = false;
	var _window:Window;
	var _res:RES;

	final CODEMAP = [for (i in 0...2048) i];

	public function new(?windowTitle:String = 'RES (HashLink)', ?scale:Int = 1) {
		super('Hashlink (SDL)');

		_windowTitle = windowTitle;
		_scale = scale;

		initChars();
	}

	function initChars() {
		// ASCII
		for (i in 0...26)
			CODEMAP[97 + i] = Key.A + i;
		for (i in 0...12)
			CODEMAP[1058 + i] = Key.F1 + i;
		for (i in 0...12)
			CODEMAP[1104 + i] = Key.F13 + i;

		// NUMPAD
		CODEMAP[1084] = Key.NUMPAD_DIV;
		CODEMAP[1085] = Key.NUMPAD_MULT;
		CODEMAP[1086] = Key.NUMPAD_SUB;
		CODEMAP[1087] = Key.NUMPAD_ADD;
		CODEMAP[1088] = Key.NUMPAD_ENTER;
		for (i in 0...9)
			CODEMAP[1089 + i] = Key.NUMPAD_1 + i;
		CODEMAP[1098] = Key.NUMPAD_0;
		CODEMAP[1099] = Key.NUMPAD_DOT;

		// EXTRA
		var keys = [
			1225 => Key.LSHIFT,
			1229 => Key.RSHIFT,
			1224 => Key.LCTRL,
			1228 => Key.RCTRL,
			1226 => Key.LALT,
			1230 => Key.RALT,
			1227 => Key.LEFT_WINDOW_KEY,
			1231 => Key.RIGHT_WINDOW_KEY,
			1075 => Key.PGUP,
			1078 => Key.PGDOWN,
			1077 => Key.END,
			1074 => Key.HOME,
			1080 => Key.LEFT,
			1082 => Key.UP,
			1079 => Key.RIGHT,
			1081 => Key.DOWN,
			1073 => Key.INSERT,
			127 => Key.DELETE,
			1085 => Key.NUMPAD_MULT,
			1087 => Key.NUMPAD_ADD,
			1088 => Key.NUMPAD_ENTER,
			1086 => Key.NUMPAD_SUB,
			1099 => Key.NUMPAD_DOT,
			1084 => Key.NUMPAD_DIV,
			39 => Key.QWERTY_QUOTE,
			44 => Key.QWERTY_COMMA,
			45 => Key.QWERTY_MINUS,
			46 => Key.QWERTY_PERIOD,
			47 => Key.QWERTY_SLASH,
			59 => Key.QWERTY_SEMICOLON,
			61 => Key.QWERTY_EQUALS,
			91 => Key.QWERTY_BRACKET_LEFT,
			92 => Key.QWERTY_BACKSLASH,
			93 => Key.QWERTY_BRACKET_RIGHT,
			96 => Key.QWERTY_TILDE,
			167 => Key.QWERTY_BACKSLASH,
			1101 => Key.CONTEXT_MENU,
			1057 => Key.CAPS_LOCK,
			1071 => Key.SCROLL_LOCK,
			1072 => Key.PAUSE_BREAK,
			1083 => Key.NUM_LOCK,
		];
		for (sdl in keys.keys())
			CODEMAP[sdl] = keys.get(sdl);
	}

	function gameLoop() {
		var lastTime = Timer.stamp();

		while (!_quit && Sdl.processEvents((event) -> {
			final mousePos = {
				x: Std.int(event.mouseX / _window.width * _res.width),
				y: Std.int(event.mouseY / _window.height * _res.height)
			};

			switch (event.type) {
				case KeyDown:
					var keyCode = event.keyCode;
					if (keyCode & (1 << 30) != 0)
						keyCode = (keyCode & ((1 << 30) - 1)) + 1000;
					_res.keyboard.keyDown(CODEMAP[keyCode]);
					return true;
				case KeyUp:
					var keyCode = event.keyCode;
					if (keyCode & (1 << 30) != 0)
						keyCode = (keyCode & ((1 << 30) - 1)) + 1000;
					_res.keyboard.keyUp(CODEMAP[keyCode]);
					return true;
				case TextInput:
					// Copied from Heaps :[
					var c = event.keyCode & 0xFF;
					var charCode = if (c < 0x7F) c; else if (c < 0xE0) ((c & 0x3F) << 6) | ((event.keyCode >> 8) & 0x7F); else if (c < 0xF0)
						((c & 0x1F) << 12) | (((event.keyCode >> 8) & 0x7F) << 6) | ((event.keyCode >> 16) & 0x7F); else
						((c & 0x0F) << 18) | (((event.keyCode >> 8) & 0x7F) << 12) | (((event.keyCode >> 16) & 0x7F) << 6) | ((event.keyCode >> 24) & 0x7F);
					_res.keyboard.input(String.fromCharCode(charCode));
					return true;
				case MouseMove:
					_res.mouse.moveTo(mousePos.x, mousePos.y);
					return true;
				case MouseDown:
					_res.mouse.push(switch (event.button) {
						case 1: LEFT;
						case 2: MIDDLE;
						case 3: RIGHT;
						case _: LEFT;
					}, mousePos.x, mousePos.y);
					return true;
				case MouseUp:
					_res.mouse.release(switch (event.button) {
						case 1: LEFT;
						case 2: MIDDLE;
						case 3: RIGHT;
						case _: LEFT;
					}, mousePos.x, mousePos.y);
					return true;
				case WindowState:
					switch (event.state) {
						case Resize:
							GL.viewport(0, 0, _window.width, _window.height);
							return true;
						case _:
							return false;
					}
				case Quit:
					return true;
				case _:
					return false;
			}

			return false;
		})) {
			final currentTime = Timer.stamp();
			final delta = currentTime - lastTime;

			lastTime = currentTime;
			GL.clear(GL.COLOR_BUFFER_BIT);
			audio.update(delta);
			_res.update(delta);
			_res.render();
			GL.drawArrays(GL.TRIANGLE_STRIP, 0, 4);
			_window.present();
			Sdl.delay(Std.int(Math.max(0, ((1 / 60) - delta) * 1000)));
		}
		Sdl.quit();
	}

	function initOpenGL() {
		UI.closeConsole();

		Sdl.init();

		_window = new Window(_windowTitle, _res.width * _scale, _res.height * _scale);
		_window.vsync = true;

		GL.init();

		function compileShader(code:String, type:Int) {
			final shader = GL.createShader(type);
			GL.shaderSource(shader, code);
			GL.compileShader(shader);

			final log = GL.getShaderInfoLog(shader);

			if (log.length > 0)
				throw log;

			return shader;
		}

		final shaderProgram = GL.createProgram();
		GL.attachShader(shaderProgram, compileShader(VERTEX_SHADER, GL.VERTEX_SHADER));
		GL.attachShader(shaderProgram, compileShader(FRAGMENT_SHADER, GL.FRAGMENT_SHADER));
		GL.linkProgram(shaderProgram);

		final posAttrib = GL.getAttribLocation(shaderProgram, 'inPos');
		final texAttrib = GL.getAttribLocation(shaderProgram, 'inTexCoord');

		final log = GL.getProgramInfoLog(shaderProgram);

		if (log.length > 0)
			throw log;

		GL.useProgram(shaderProgram);

		final vertecies = Float32Array.fromArray([
			-1.0,  1.0, 0.0, 0.0,
			-1.0, -1.0, 0.0, 1.0,
			 1.0,  1.0, 1.0, 0.0,
			 1.0, -1.0, 1.0, 1.0,
		]).getData();

		final vbo = GL.createBuffer();
		GL.bindBuffer(GL.ARRAY_BUFFER, vbo);
		GL.bufferData(GL.ARRAY_BUFFER, vertecies.byteLength, hl.Bytes.fromBytes(vertecies.bytes), GL.STATIC_DRAW);

		final vao = GL.createVertexArray();
		GL.bindVertexArray(vao);

		GL.enableVertexAttribArray(posAttrib);
		GL.enableVertexAttribArray(texAttrib);

		GL.vertexAttribPointer(posAttrib, 2, GL.FLOAT, false, 16, 0);
		GL.vertexAttribPointer(texAttrib, 2, GL.FLOAT, false, 16, 8);

		GL.clearColor(0.0, 0.0, 0.0, 1.0);
	}

	public function connect(res:RES) {
		_res = res;

		initOpenGL();
		audio = new Audio();
	}

	public function createAudioBuffer(audioStream:IAudioStream):IAudioBuffer {
		return new AudioBuffer(audioStream);
	}

	public function createAudioMixer():AudioMixer {
		return new AudioMixer(audio);
	}

	public function createCRT(width:Int, height:Int):CRT {
		return new CRT(width, height);
	}

	public function createStorage():Storage {
		return new FileStorage();
	}

	override function setCursorVisibility(value:Bool) {
		Cursor.show(value);
	}

	public function startup() {
		gameLoop();
	}

	override public function shutdown() {
		_quit = true;
	}
}
