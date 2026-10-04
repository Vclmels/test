# Estado de las animaciones extraídas

`PullBackRod`, `ReelInn` y `ReelOutt` se conservan sin modificar en
`animations/`. Son AnimationClips humanoides de Unity: sus datos apuntan a
decenas de huesos que no están presentes en `FishingRod.smd`, el cual solo
contiene el hueso `root`.

StudioMDL no puede importar esos archivos directamente. Para compilarlas como
secuencias funcionales de Garry's Mod hace falta el modelo original riggeado
(o un rig reconstruido con los mismos huesos) y exportar cada clip a SMD/DMX.

## Escena para animar en primera persona

`FishingRod_Arms_Rig.blend` contiene la caña con un rig nuevo y los dos brazos
riggeados importados desde `hands_reference.smd` (viewmodel de CS:S decompilado
con Crowbar). Las texturas de la caña y la textura `textures/CSS_v_hands.png`
están empaquetadas en el `.blend`. El cuchillo no se importó.

- `hands_reference_skeleton`: animá los brazos y dedos. La mano derecha agarra
  el mango; `FishingRodRig` está vinculado a `v_weapon.Right_Hand`, por lo que
  acompaña el lanzamiento. La mano izquierda está colocada cerca del carrete.
- `FishingRodRig`: `reel` permite mover el carrete; `rod_lower`, `rod_mid`,
  `rod_upper` y `rod_tip` permiten flexionar la vara. Ambos rigs se pueden posar
  en **Pose Mode**.
- Para lanzar y recoger, creá acciones separadas en el Action Editor para los
  dos armatures. Animá el brazo derecho y la flexión de la caña para lanzar;
  animá la mano izquierda y `reel` para recoger el hilo.

Esta escena es una fuente de trabajo para crear animaciones: el
`FishingRod.smd` y `fishing_rod.qc` existentes siguen teniendo el `root`
original. Antes de compilar las nuevas animaciones hay que exportar el modelo
y sus acciones desde Blender Source Tools y adaptar el QC del viewmodel.

## Amague hacia atrás y lanzamiento

Abrí `FishingRod_Cast_Animated.blend` para reproducir la animación de 60
fotogramas a 24 FPS. Fotogramas 1–15: preparación y amague hacia atrás;
18–30: impulso y lanzamiento; 34–60: oscilación y estabilización de la vara.
Las acciones en el Dope Sheet / Action Editor son
`TF_Cast_BackSwing_Throw_Arms` (manos) y
`TF_Cast_BackSwing_Throw_Rod` (caña). El archivo
`create_cast_animation.py` permite recrear estas dos acciones desde
`FishingRod_Arms_Rig.blend` mediante Blender en modo batch.

### Lanzamiento rehecho con manos animadas

`FishingRod_Cast_Realistic.blend` es la versión nueva. Dura 78 cuadros a
30 FPS: 1–28 retracción de la caña y brazos, 34–48 impulso y liberación
del hilo con los dedos de la mano izquierda, 53–78 recuperación. La mano
derecha mueve el mango; la izquierda sigue el carrete y abre pulgar e índice
al lanzar. La caña tiene flexión y rebote en huesos independientes.

Las acciones son `TF_Realistic_Cast_Arms_Hands_Release` y
`TF_Realistic_Cast_Rod_Flex`. Para recrearlas desde el rig base, ejecutá
`create_cast_realistic.py` con Blender en modo batch. Podés comparar la
primera versión en `FishingRod_Cast_Animated.blend`.

## Integración en el addon

`export_cast_viewmodel.py` hornea `FishingRod_Cast_Realistic.blend` en los
archivos `cast_viewmodel/cast_reference.smd`, `cast_viewmodel/idle.smd` y
`cast_viewmodel/cast.smd`. El QC `cast_viewmodel/cast_viewmodel.qc` compila el
modelo animado `models/fishing/v_fishing_rod_cast.mdl` (ambas manos y caña)
con las secuencias `idle` y `cast`. Los archivos compilados están incluidos
en `models/fishing/` del addon y la textura de manos junto con su VMT en
`materials/models/fishing/`.

El SWEP `lua/weapons/fishing_rod/shared.lua` utiliza este viewmodel en
primera persona y reproduce `cast` al lograr un lanzamiento. Una vez
terminada la secuencia, cambia a la vista en tercera persona que ya usaba
el addon para esperar la picada. La caña original `models/fishing/pole.mdl`
se mantiene como modelo de mundo y entidad.

## Secuencias de Recogida y Pelea del Pez (`reel_hold`, `reel_in_fish`, `reel_ready`)

`cast_viewmodel/cast_viewmodel.qc` incluye las secuencias de lucha contra el pez exportadas desde `FishingRod_Arms_Rig.blend` con `export_reel_animations.py`:

1. **`reel_hold`** (`reel_hold.smd`, loop): El jugador mantiene la mano izquierda en la palanca/manivela en reposo (`Action.002` fotograma 6).
2. **`reel_in_fish`** (`reel_in_fish.smd`, 13 fotogramas a 18 FPS, loop): Giro de 360° en sincronía de la palanca (`FishingRodRigAction.006` en `FishingRodRig`) y la mano izquierda (`Action.003` en `hands_reference_skeleton`).
3. **`reel_ready`** (`reel_ready.smd`, fotogramas 0 a 6): Transición rápida desde el reposo hasta tomar la manivela.

En `lua/weapons/fishing_rod_physics/shared.lua`, el hook `TrueFishingPhysicsCastView`:
- Cuando hay un pez enganchado (`HookedFishID > 0`) y el jugador mantiene **Click Izquierdo (`IN_ATTACK`)**: reproduce `reel_in_fish` girando el brazo y la palanca al unísono.
- Si el jugador **suelta Click Izquierdo**: el viewmodel conmuta a `reel_hold`, quedándose trabado sosteniendo la palanca hasta que el pez sea pescado.
- Al pescarse el pez o terminar la lucha: el viewmodel vuelve limpiamente a `idle`.

