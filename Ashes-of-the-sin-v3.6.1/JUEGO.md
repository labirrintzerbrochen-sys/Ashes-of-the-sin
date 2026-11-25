# Ashes of the Sin

Plataformas de acción 2D en el infierno. Abrir con **Godot 4.7** y pulsar F5 (la escena principal es el menú).

## Controles
| Acción | Teclado / ratón | Mando |
|---|---|---|
| Mover | A/D o flechas | Stick / cruceta |
| Saltar (mantén para saltar más alto) | Espacio, W, ↑ | A |
| Atacar | J, X, clic izquierdo | X |
| Esquivar (dash con invulnerabilidad) | K, Shift, C, clic derecho | B / RB |
| Pausa | Esc, P | Start |

## Reglas
- 5 corazones al empezar cada mapa, 3 vidas. La lava, la sangre y caer al vacío matan al instante.
- Cada enemigo da puntos (vida × 100); a veces suelta un corazón. Cada 5000 puntos, vida extra.
- La cabeza de demonio se aplasta cayéndole encima. La mina explota si te acercas: golpéala de lejos.
- Los muros falsos llevan a un subnivel (portal azul) y, de ahí, a una zona oculta con una
  **Reliquia del Pecador** (+1 corazón máximo, una por nivel).
- Al final del Nivel 4 el **Cráneo Gigante** sella el portal de salida: derrótalo para ganar.
- Sin vidas: reintentar el nivel (pierdes 500 puntos) o volver al menú. El progreso se guarda al
  entrar en cada mapa (`user://guardado.cfg`) y el menú ofrece "Continuar".

## Código nuevo (carpeta `juego/`)
- `juego.gd` — autoload `Juego`: estado, flujo de mapas, vidas, guardado, audio, pausa, game over, final.
- `jugador.gd/.tscn` — el héroe gótico (movimiento, ataque, dash, daño, cámara).
- `hud.gd` — corazones, vidas, puntos, barra del jefe, banner de nivel, avisos.
- `menu_principal.*`, `pantalla_texto.*`, `panel_menu.gd`, `estilo.gd` — interfaz.
- `corazon.gd`, `reliquia.gd` — objetos recogibles.
- `audio/` — efectos y música generados con `herramientas/generar_audio.py`.
- `biomas/infierno/objetos/portal.gd` — ahora usa `Juego` y sella la salida final mientras el jefe viva.
- `tests/` — pruebas automáticas (`godot --headless --fixed-fps 60 -s tests/prueba_flujo.gd`).

Los mapas siguen siendo los generados por `herramientas/generar_bioma_infierno.py` (ver `niveles/LEEME.md`).

## Actualización: Azra, Monedas, Cofres y Powerups

**Protagonista:** El personaje ahora se llama **Azra** en todos los textos del juego.

**Nuevos niveles:**
- **Nivel 5 — Abismo de las Almas** (3 mapas): enemigos más agresivos, muchas monedas y cofres.
- **Nivel 6 — Trono de Cenizas** (3 mapas): el verdadero final, con la mayor concentración de enemigos y recompensas.

**Monedas (`juego/moneda.gd`):**
- Los enemigos ahora sueltan monedas doradas al morir (45% de probabilidad).
- Cada moneda vale 25 puntos × 5 = 125 puntos.
- El contador de monedas aparece en la esquina superior derecha del HUD.

**Cofres (`juego/cofre.gd`):**
- Repartidos por los mapas como `Marker2D` con grupo `"cofre"`.
- Al tocarlos sueltan 5–10 monedas y tienen 55% de probabilidad de dar un powerup.

**Powerups (`juego/powerup.gd`):**
- ⚡ **Velocidad** (azul): duplica la velocidad de movimiento durante 12 segundos.
- ⚔ **Fuerza** (rojo): duplica el daño del ataque durante 12 segundos.
- 🛡 **Escudo** (verde): absorbe el próximo golpe sin daño y se consume.
- Se muestran en el HUD con su tipo y tiempo restante.
