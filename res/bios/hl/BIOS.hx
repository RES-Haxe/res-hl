package res.bios.hl;

import haxe.Timer;
import haxe.io.Float32Array;
import res.audio.IAudioBuffer;
import res.audio.IAudioStream;
import res.bios.common.FileStorage;
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

	public function new(?windowTitle:String = 'RES (HashLink)', ?scale:Int = 1) {
		super('Hashlink (SDL)');

		_windowTitle = windowTitle;
		_scale = scale;
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
					_res.keyboard.keyDown(event.keyCode);
					return true;
				case KeyUp:
					_res.keyboard.keyUp(event.keyCode);
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
