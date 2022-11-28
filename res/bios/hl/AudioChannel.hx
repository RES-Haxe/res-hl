package res.bios.hl;

import haxe.io.Bytes;
import openal.AL;

class AudioChannel extends res.audio.AudioChannel {
	final source:Source;
	final loop:Bool;

	var ended:Bool = false;
	var playing:Bool = false;

	public function new(buffer:AudioBuffer, loop:Bool) {
		this.loop = loop;

		final idBytes = Bytes.alloc(4);
		AL.genSources(1, idBytes);
		source = Source.ofInt(idBytes.getInt32(0));

		AL.sourcei(source, AL.BUFFER, buffer.buffer.toInt());
		AL.sourcei(source, AL.LOOPING, loop ? 1 : 0);
	}

	function start() {
		playing = true;
		AL.sourcePlay(source);
	}

	function pause() {
		playing = false;
		AL.sourcePause(source);
	}

	function resume() {
		start();
	}

	override function stop() {
		ended = true;
		playing = false;
		super.stop();
	}

	public function update(delta:Float) {
		final state = AL.getSourcei(source, AL.SOURCE_STATE);
		final position = AL.getSourcef(source, AL.SEC_OFFSET);

		if (state == AL.STOPPED) {
			final size = 4;
			AL.deleteSources(1, hl.Bytes.fromValue(source.toInt(), size));
			stop();
		}
	}

	public function isEnded():Bool {
		return ended;
	}

	public function isPlaying():Bool {
		return playing;
	}
}
