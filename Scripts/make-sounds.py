#!/usr/bin/env python3
from pathlib import Path
import math, struct, wave
root = Path(__file__).resolve().parents[1] / "Resources"
(root/'Sounds').mkdir(exist_ok=True)
for name,freqs in {'soft':[440,550],'rise':[440,554,659],'fall':[659,554,440],'bell':[660,990]}.items():
    rate=22050; length=.75
    with wave.open(str(root/'Sounds'/f'{name}.wav'),'wb') as w:
        w.setparams((1,2,rate,0,'NONE','not compressed'))
        frames=[]
        for i in range(int(rate*length)):
            t=i/rate; v=0
            for j,f in enumerate(freqs):
                dt=t-j*.12
                if dt>=0:v+=math.sin(2*math.pi*f*dt)*min(1,dt/.03)*math.exp(-8*dt)*.15
            v*=min(1,(length-t)/.06)
            frames.append(struct.pack('<h',int(max(-.8,min(.8,v))*32767)))
        w.writeframes(b''.join(frames))
