"""Genera los efectos de sonido y la música (síntesis procedural, sin dependencias externas salvo numpy).
Uso:  python herramientas/generar_audio.py
"""
import os
import wave

import numpy as np

SR = 22050
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")
rng = np.random.default_rng(7)


def t(d):
    return np.linspace(0, d, int(SR * d), endpoint=False)


def env(n, a=0.005, r=0.1):
    e = np.ones(n)
    na, nr = max(1, int(SR * a)), max(1, int(SR * r))
    e[:na] = np.linspace(0, 1, na)
    e[-nr:] *= np.linspace(1, 0, nr)
    return e


def guardar(nombre, x, vol=0.8):
    x = x / (np.max(np.abs(x)) + 1e-9) * vol
    with wave.open(os.path.join(RAIZ, nombre + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


def barrido(f0, f1, d, forma="sq"):
    tt = t(d)
    f = np.linspace(f0, f1, len(tt))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sign(np.sin(ph)) if forma == "sq" else np.sin(ph)


def ruido(d):
    return rng.uniform(-1, 1, int(SR * d))


os.makedirs(RAIZ, exist_ok=True)
guardar("salto", barrido(260, 620, 0.18, "sin") * env(int(SR * 0.18), 0.003, 0.12), 0.55)
guardar("corte", ruido(0.16) * np.linspace(1, 0, int(SR * 0.16)) ** 2 * 0.6 + barrido(900, 200, 0.16, "sin") * 0.4, 0.6)
guardar("golpe", (ruido(0.12) * 0.5 + barrido(220, 70, 0.12, "sq") * 0.6) * env(int(SR * 0.12), 0.001, 0.1), 0.8)
guardar("herido", (barrido(420, 90, 0.35, "sq") * 0.7 + ruido(0.35) * 0.3) * env(int(SR * 0.35), 0.002, 0.25), 0.8)
guardar("esquivar", ruido(0.2) * np.sin(np.linspace(0, np.pi, int(SR * 0.2))) * 0.5, 0.45)
guardar("recoger", np.concatenate([barrido(660, 660, 0.07, "sin"), barrido(880, 880, 0.07, "sin"), barrido(1320, 1320, 0.16, "sin")]) * 0.8, 0.6)
guardar("reliquia", np.concatenate([barrido(f, f, 0.12, "sin") * env(int(SR * 0.12), 0.003, 0.1) for f in (523, 659, 784, 1046, 1318)]), 0.7)
guardar("portal", (barrido(120, 700, 0.7, "sin") * 0.7 + barrido(180, 900, 0.7, "sin") * 0.4) * env(int(SR * 0.7), 0.05, 0.4), 0.7)
guardar("explosion", ruido(0.6) * np.linspace(1, 0, int(SR * 0.6)) ** 1.5 + barrido(90, 30, 0.6, "sin") * 0.8, 0.9)
guardar("muerte", (barrido(300, 40, 1.0, "sq") * 0.6 + barrido(150, 20, 1.0, "sin") * 0.6) * env(int(SR * 1.0), 0.01, 0.6), 0.8)
guardar("menu", barrido(500, 500, 0.05, "sin") * env(int(SR * 0.05), 0.002, 0.04), 0.4)
guardar("jefe_muere", (ruido(1.6) * np.linspace(1, 0, int(SR * 1.6)) ** 1.2 * 0.7 + barrido(200, 25, 1.6, "sin")) , 0.95)
guardar("victoria", np.concatenate([barrido(f, f, 0.22, "sin") * env(int(SR * 0.22), 0.005, 0.18) for f in (392, 523, 659, 784, 1046)]), 0.7)


def musica(nombre, dur, base, notas, pulso, tempo):
    n = int(SR * dur)
    tt = np.arange(n) / SR
    x = np.zeros(n)
    # Bordón grave con vibrato lento (periodos enteros para que el bucle sea continuo)
    for mult, amp in ((1, 0.55), (1.5, 0.25), (2.0, 0.18), (0.5, 0.4)):
        f = base * mult
        f = round(f * dur) / dur  # ciclos enteros en el bucle
        x += amp * np.sin(2 * np.pi * f * tt + 0.8 * np.sin(2 * np.pi * (2 / dur) * tt))
    x *= 0.6 + 0.4 * np.sin(2 * np.pi * (1 / dur) * tt) ** 2
    # Campanas / notas sueltas
    paso = dur / len(notas)
    for i, (nota, vol) in enumerate(notas):
        if nota == 0:
            continue
        i0 = int(i * paso * SR)
        m = int(SR * 1.8)
        tn = np.arange(m) / SR
        f = round(nota * 1.0)
        v = (np.sin(2 * np.pi * f * tn) + 0.4 * np.sin(2 * np.pi * f * 2.01 * tn)) * np.exp(-tn * 2.2) * vol
        fin = min(n, i0 + m)
        x[i0:fin] += v[: fin - i0]
    # Pulso grave (latido)
    if pulso:
        paso_p = 60.0 / tempo
        k = 0.0
        while k < dur:
            i0 = int(k * SR)
            m = int(SR * 0.25)
            tn = np.arange(m) / SR
            kick = np.sin(2 * np.pi * (60 - 25 * tn * 4) * tn) * np.exp(-tn * 14) * pulso
            fin = min(n, i0 + m)
            x[i0:fin] += kick[: fin - i0]
            k += paso_p
    guardar(nombre, x, 0.5)


menor = [110, 131, 147, 165, 196]
musica("musica_ambiente", 24.0, 55.0,
       [(menor[i % 5] * 2 * (1 if i % 3 else 2), 0.3) if i % 2 == 0 else (0, 0) for i in range(12)], 0.0, 60)
musica("musica_jefe", 16.0, 49.0,
       [(menor[(i * 2) % 5] * 4, 0.28) if i % 2 == 0 else (0, 0) for i in range(16)], 0.9, 120)
musica("musica_menu", 24.0, 41.0,
       [(menor[i % 5] * 4, 0.22) if i % 3 == 0 else (0, 0) for i in range(12)], 0.0, 60)
print("audio listo")
