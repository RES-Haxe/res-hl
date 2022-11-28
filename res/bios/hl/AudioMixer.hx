package res.bios.hl;

import res.audio.AudioChannel;
import res.audio.IAudioBuffer;

class AudioMixer extends res.audio.AudioMixer {
	final audio:Audio;

	public function new(audio:Audio) {
		this.audio = audio;
	}

	public function createAudioChannel(buffer:IAudioBuffer, loop:Bool):AudioChannel {
		final newChannel = new res.bios.hl.AudioChannel(cast buffer, loop);
		audio.addChannel(newChannel);
		return newChannel;
	}
}
