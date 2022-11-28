package res.bios.hl;

import haxe.io.Bytes;
import sdl.GL;

class CRT extends res.display.CRT {
	var texture:Texture;

	var pixelsData:hl.Bytes;

	final width:Int;
	final height:Int;

	public function new(width:Int, height:Int) {
		super([A, B, G, R]);

		texture = GL.createTexture();
		GL.bindTexture(GL.TEXTURE_2D, texture);
		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);

		this.width = width;
		this.height = height;

		pixelsData = hl.Bytes.fromBytes(Bytes.alloc(width * height * 4));
	}

	override function vblank() {
		GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, pixelsData);
	}

	public function beam(x:Int, y:Int, index:Int, palette:Palette) {
		pixelsData.setI32((y * width + x) * 4, palette.get(index).output);
	}
}
