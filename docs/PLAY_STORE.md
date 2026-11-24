# Publicar la beta en Google Play (P-07)

Guía para subir **Retro Pinball** (`com.pasaporten25.retropinball`) a una pista de pruebas.
El paquete no se puede cambiar nunca después de la primera subida.

> Las reglas de Play Console cambian seguido. Lo de abajo vale a noviembre de 2026; si un paso no
> coincide con lo que ves en la consola, manda la consola.

## 1. Clave de subida (una sola vez)

Play firma la app con su propia clave (*Play App Signing*); vos firmás cada AAB con una **clave de
subida**. Creala fuera del repo y guardá la contraseña en tu gestor de contraseñas:

```powershell
New-Item -ItemType Directory -Force "$HOME\.keystores"
```

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v -keystore "$HOME\.keystores\retropinball-upload.jks" -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Hacé una copia de seguridad del `.jks` (si se pierde, se puede pedir a Google un reseteo de la clave de
subida, pero tarda). `.gitignore` ya excluye `*.jks` y `*.keystore`.

## 2. Armar el AAB

```powershell
.\tools\release.ps1
```

El script corre los tests, suma 1 a `version/code` (Play rechaza un código repetido), instala la
plantilla de Gradle si falta (`android/`, ignorada por git) y exporta el preset **Android Play (AAB)** a
`build/retro-pinball.aab`. Pide la contraseña de la clave si no está en
`GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`. Después commiteá `export_presets.cfg` con la versión nueva.

Opciones: `-NoBump` (mismo código), `-VersionName 0.9.1`, `-SkipTests`.

La primera exportación con Gradle baja dependencias y tarda unos minutos.

## 3. Crear la app en Play Console

*Todas las apps → Crear app*:

- Nombre: **Retro Pinball** · Idioma predeterminado: **Español (Latinoamérica) – es-419**
- **Juego** · **Gratis** (una app gratis no puede pasar a paga después; las compras dentro de la app
  sí se pueden agregar más adelante, ver P-09).

## 4. Contenido de la app (*Política → Contenido de la app*)

| Declaración | Respuesta |
|---|---|
| Política de privacidad | `https://github.com/pasaporteN25/RetroPainball/blob/master/docs/PRIVACY.md` |
| Anuncios | No contiene anuncios |
| Acceso a la app | Toda la funcionalidad está disponible sin acceso especial |
| Clasificación de contenido | Cuestionario IARC, categoría *Juego*: sin violencia, sangre, sexo, lenguaje, drogas, apuestas, compras ni interacción entre usuarios. Drácula y Alicia son temas de fantasía sin violencia gráfica. Esperable: *Para todos* / PEGI 3 |
| Público objetivo | **13 años o más**. Si incluís menores de 13 se aplica la política de Familias (más requisitos); se puede ampliar después |
| Seguridad de los datos | *¿Recopila o comparte datos?* → **No**. Todo queda en el dispositivo (récords, opciones, partida) y no hay Internet |
| Apps gubernamentales, funciones financieras, salud, noticias | No |

## 5. Ficha de Play Store (*Crecimiento → Presencia en Play Store*)

Gráficos en `docs/play/` (se regeneran con `tools/generate_app_branding.gd` y
`tools/capture_screenshots.gd`; la carpeta tiene `.gdignore` y no entra en el AAB):

| Pide Play | Archivo |
|---|---|
| Ícono 512 × 512 | `docs/play/icon_512.png` |
| Gráfico de funciones 1024 × 500 | `docs/play/feature_graphic.png` |
| Capturas de teléfono (2 a 8) | `docs/play/screenshots/*.png` (780 × 1560) |

**Descripción breve** (máx. 80):

> Pinball retro con cuatro mesas temáticas, récords arcade y física real.

**Descripción completa**:

> Retro Pinball es un pinball vertical pensado para jugar con los dos pulgares, con estética neón y
> cuatro mesas, cada una con su arte, sus reglas y su propio récord:
>
> • Kernel Panic: un circuito de terminal con carriles BOOT y BUS, blancos IRQ y daemons como bumpers.
> • 20.000 Leguas bajo el mar: activá los sonares, golpeá al kraken y descendé con el Nautilus.
> • Drácula: rampa de Carfax, el ataúd del conde y multibola a medianoche.
> • Alicia: naipes, hongos, la tetera del Sombrerero y una Alicia que cambia de tamaño.
>
> Lanzador con skill shot, salvabolas, kickback, multiplicador de bonus, bola extra, nudge y TILT.
> Top 10 de puntajes por mesa y estadísticas de cada mesa.
> La partida se guarda sola: si salís, la continuás donde quedó.
>
> Sin anuncios, sin conexión a Internet y sin recopilar datos.
>
> Versión beta: ¡contanos qué te parece la sensación de los flippers!

Categoría: **Juegos → Arcade**. Etiquetas sugeridas: Pinball, Arcade, Retro.

## 6. Pistas de prueba

Una **cuenta personal creada después de noviembre de 2023** no puede publicar en *Producción* hasta
correr una **prueba cerrada con al menos 12 testers que la tengan instalada durante 14 días seguidos**.
Por eso conviene:

1. **Prueba interna** (*Pruebas → Prueba interna*): hasta 100 testers por mail, sin revisión de
   Google, disponible en minutos. Subí ahí el primer AAB, instalalo vos desde el link y verificá que
   arranca bien.
2. **Prueba cerrada** (*Pruebas → Prueba cerrada → Alfa*): subí el mismo AAB (o promové la versión
   interna) y cargá los testers con una lista de mails o un Grupo de Google. Pasa por revisión (horas a
   pocos días). Este es el tramo que cuenta para los 12 testers / 14 días.
3. Compartí el **link de participación** (*Testers → Copiar vínculo*): cada tester lo abre con la
   cuenta de Google que cargaste, acepta y descarga la app desde Play.

El *Informe previo al lanzamiento* corre la app en teléfonos reales de Google: revisá crashes y
capturas ahí antes de invitar gente.

## 7. Cada versión nueva

1. `.\tools\release.ps1 -VersionName 0.9.x`
2. Commit de `export_presets.cfg`.
3. Play Console → la pista → *Crear versión* → subir `build/retro-pinball.aab` → notas de la versión.

## Instalar el AAB sin Play (opcional)

Un AAB no se instala con `adb install`. Para probar en tu teléfono sin pasar por Play usá el preset
debug (`build/pinball-debug.apk`, ver README). Ojo: el APK debug y la versión de Play usan claves
distintas; para pasar de una a otra hay que desinstalar primero (se pierden los récords locales).
