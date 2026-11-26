#!/usr/bin/env python3
"""Generate the original, nonverbal prototype sound palette using stdlib only.

No external recordings, voices, copyrighted samples, or runtime network calls.
"""
import math
from pathlib import Path
import random
import struct
import wave

RATE = 44100
DEST = Path(__file__).resolve().parents[1] / "game/assets/audio"


def write(name, seconds, sample):
    rng = random.Random(271126)
    frames = bytearray()
    for i in range(int(seconds * RATE)):
        t = i / RATE
        value = max(-0.96, min(0.96, sample(t, seconds, rng)))
        frames.extend(struct.pack("<h", round(value * 32767)))
    with wave.open(str(DEST / f"{name}.wav"), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(frames)


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    sine = lambda f, t: math.sin(math.tau * f * t)
    write("ambience", 12, lambda t, d, r: .22*sine(55,t)+.09*sine(82.5,t)+.06*sine(110,t)*(0.7+0.3*sine(0.25,t))+.025*sine(164.75,t))
    write("step", .16, lambda t, d, r: (r.uniform(-1,1)*.5+sine(95,t)*.4)*math.exp(-t*38)*min(1,t*300))
    write("warning", 1.2, lambda t, d, r: (.3*sine(330,t)+.12*sine(495,t))*math.sin(math.pi*t/d)**2)
    write("seal", 2.3, lambda t, d, r: sum(.15*sine(f,t) for f in [220,330,440,554.37])*math.exp(-t*1.8)*min(1,t*25))
    write("fail", .5, lambda t, d, r: (.3*sine(83,t)+.22*sine(91,t)+.05*r.uniform(-1,1))*math.exp(-t*7)*min(1,t*100))
    write("echo", .55, lambda t, d, r: (.4*sine(440,t)+.13*sine(880,t))*math.exp(-t*8)*min(1,t*90))
    write("pickup", .75, lambda t, d, r: (.26*sine(660,t)+.2*sine(990,t))*math.exp(-t*6)*min(1,t*70))
    write("blink", .85, lambda t, d, r: (.3*math.sin(math.tau*(240*t-80*t*t))+.1*sine(60,t))*math.sin(math.pi*t/d)**2)
    write("heartbeat", .45, lambda t, d, r: .6*sine(65,t)*math.exp(-t*16)*min(1,t*120))
    print(f"Generated 9 original PCM WAV files in {DEST}")


if __name__ == "__main__":
    main()

