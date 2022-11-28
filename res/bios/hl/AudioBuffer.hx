package res.bios.hl;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import openal.AL;
import res.audio.IAudioBuffer;
import res.audio.IAudioStream;
import res.audio.Tools;
import res.tools.MathTools;

class AudioBuffer implements IAudioBuffer {
	public final numChannel:Int;

	public final numSamples:Int;

	public final sampleRate:Int;

	public final buffer:Buffer;

	public function new(audioStream:IAudioStream) {
		this.numChannel = audioStream.numChannels;
		this.numSamples = audioStream.numSamples;
		this.sampleRate = audioStream.sampleRate;

		final bytesOutput = new BytesOutput();

		for (_ => sample in audioStream) {
			final avgAmp = MathTools.avg([for (_ => amp in sample) amp]);
			bytesOutput.writeInt16(Tools.quantize(avgAmp, 16));
		}

		final bufId = Bytes.alloc(4);
		AL.genBuffers(1, bufId);

		buffer = Buffer.ofInt(bufId.getInt32(0));

		final pcmData = bytesOutput.getBytes();

		AL.bufferData(buffer, AL.FORMAT_MONO16, hl.Bytes.fromBytes(pcmData), pcmData.length, sampleRate);
	}
}
