package res.bios.hl;

import openal.ALC;

class Audio {
	public final device:Device;
	public final context:Context;
	public final channels:Array<AudioChannel> = [];

	public function new() {
		device = ALC.openDevice(null);
		context = ALC.createContext(device, null);
		ALC.makeContextCurrent(context);
	}

	public function addChannel(channel:AudioChannel) {
		channels.push(channel);
	}

	public function update(delta:Float) {
		for (channel in channels) {
			if (channel.isEnded())
				channels.remove(channel);
			else
				channel.update(delta);
		}
	}
}
