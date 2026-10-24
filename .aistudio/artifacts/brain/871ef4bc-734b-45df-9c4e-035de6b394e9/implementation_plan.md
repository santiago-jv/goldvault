# Redirección de Google Login hacia la APK en GoldVault

Resuelve el problema donde el inicio de sesión con Google desde la APK de Android deja al usuario atrapado en el navegador web tras autenticarse, implementando un puente automático de redirección hacia la aplicación nativa (`goldvault://login-callback`) sin necesidad de modificar la configuración actual de Supabase, junto con una pantalla de respaldo con botón manual y captura nativa de enlaces profundos en Android.

## User Review & Critical Decisions

> [!IMPORTANT]
> Estas decisiones fueron confirmadas para garantizar que el flujo funcione de inmediato sin tocar el panel de Supabase ni perder la sesión en ningún navegador de Android.

- **Puente Automático Web → APK sin tocar Supabase**: La APK iniciará el flujo OAuth apuntando a una ruta puente en el dominio web ya autorizado por Supabase (`?apk_redirect=1`), y en cuanto el navegador reciba el código o token de Google/Supabase, redirigirá automáticamente a `goldvault://login-callback` reenviando todos los parámetros de sesión a la APK.
- **Pantalla de Respaldo con Botón Manual**: Si el navegador móvil (Chrome Custom Tabs, Samsung Internet, Brave, etc.) bloquea la redirección automática sin gesto del usuario, se mostrará una tarjeta con estética GoldVault y un botón directo **"Abrir en la app GoldVault"** para saltar a la APK con un toque.

---

## 1. Overview & Core Concept

- **Qué hace**: Permite que al pulsar *"Continuar con Google"* dentro de la APK de Android, el navegador complete la autenticación con Google y devuelva inmediatamente al usuario a la aplicación instalada con su sesión activa y sincronizada.
- **Por qué ocurría el fallo**:
  1. Cuando una URL de esquema personalizado (`goldvault://login-callback`) no está en la lista blanca de *Redirect URLs* de Supabase, Supabase ignora ese destino y redirige por defecto al *Site URL* web (`https://goldvault-app.vercel.app`), dejando al usuario en la versión web.
  2. Incluso cuando el enlace profundo `goldvault://login-callback` se dispara desde el navegador, en Android hacía falta interceptar explícitamente los *Intents* de redirección en la actividad nativa y procesarlos con `getSessionFromUrl` en el estado de la aplicación.
- **Valor Principal**: Experiencia de inicio de sesión nativa, continua y a prueba de bloqueos de navegadores móviles, manteniendo compatibilidad tanto con el puente web automático como con enlaces profundos directos.

---

## 2. User Experience & Visual Design

- **Flujo del Usuario Paso a Paso**:
  1. **En la APK**: El usuario pulsa **"Continuar con Google"** en la pantalla de bienvenida de GoldVault.
  2. **En el Navegador Seguro**: Se abre la selección de cuenta de Google y se autoriza el acceso.
  3. **Puente Instantáneo**: Al volver de Google al puente web, el script ultraligero detecta que el login proviene de la APK y lanza de inmediato el enlace `goldvault://login-callback` con las credenciales cifradas (`code` / `access_token`).
  4. **Respaldo Visual (Fallback)**: Mientras se procesa el salto (o si el navegador requiere confirmación manual), el navegador muestra una tarjeta centrada con el diseño **GoldVault** (fondo oscuro `#0E0F12`, tarjeta `#14161B` con borde sutil y botón dorado `#D9B87A` *"Abrir GoldVault APK"*) en lugar de cargar toda la aplicación web por error.
  5. **Regreso a la APK**: Android trae la APK de GoldVault al primer plano, la app canjea la URL de sesión automáticamente y muestra los espacios y movimientos del usuario.

- **Identidad Visual y Tema**:
  - *Estética*: Bóveda financiera editorial oscura y cálida (GoldVault Dark & Light tokens).
  - *Paleta de Colores*: Fondo principal `#0E0F12`, superficie `#14161B`, texto principal `#ECE7DD`, texto secundario `#8B867C`, acento dorado `#D9B87A` con tinta `#17130B`.
  - *Tipografía y Jerarquía*: `Plus Jakarta Sans` con pesos contrastados (`600` y `800`) y botones de un solo toque con área táctil mínima de `48px`.

---

## 3. Key Product Decisions & Trade-Offs

- **Decisión 1: Puente pre-Flutter en `index.html` + Pantalla de Respaldo**
  - *Enfoque elegido*: Interceptar `?apk_redirect=1` en el arranque HTML antes de cargar el motor de Flutter, construyendo el enlace profundo `goldvault://login-callback` y un `intent://` de Android con todos los parámetros (`?code=...` y `#access_token=...`).
  - *Por qué*: Ejecutar la redirección antes de descargar el bundle de Flutter Web hace que el regreso a la APK sea instantáneo (<100ms) y evita que el navegador consuma el código PKCE de un solo uso antes de entregárselo a la APK.
  - *Alternativas consideradas*: Redirigir después de inicializar `Supabase.initialize()` en la web — descartado porque si la web consume el `?code=` PKCE primero, el código queda invalidado cuando llega a la APK.

- **Decisión 2: Captura Nativa de Deep Links en `MainActivity.kt` hacia Dart**
  - *Enfoque elegido*: Escuchar `intent?.data` tanto en `onCreate` como en `onNewIntent` dentro de `MainActivity.kt` y enviarlo por el `MethodChannel` existente a `GoldVaultState`, donde `sb.auth.getSessionFromUrl(uri)` establece la sesión de inmediato.
  - *Por qué*: Garantiza que aunque la APK ya esté abierta en segundo plano (`singleTop`), el regreso desde el navegador dispare siempre la recuperación de sesión sin depender únicamente del listener interno del plugin.

---

## 4. Technical Architecture & Data Strategy

### Diagrama de Arquitectura del Flujo OAuth (APK ↔ Web Bridge ↔ Android Intent)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         1. GoldVault APK (Flutter)                      │
│  • Usuario pulsa "Continuar con Google"                                 │
│  • Llama signInWithOAuth(redirectTo: "...vercel.app/?apk_redirect=1")   │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │ Abre navegador del sistema
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     2. Google OAuth & Supabase Auth                     │
│  • Autentica cuenta de Google                                           │
│  • Redirige a URL autorizada: ?apk_redirect=1&code=... (#access_token)  │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                3. Puente Web Pre-Bootstrap (web/index.html)             │
│  • Detecta apk_redirect=1 ANTES de iniciar Supabase Web                 │
│  • No consume el código PKCE en el navegador                            │
│  • Dispara window.location.replace("goldvault://login-callback?...")    │
│  • Muestra tarjeta GoldVault con botón "Abrir GoldVault APK" (Fallback) │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │ Android Intent (VIEW)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│             4. Android MainActivity.kt -> GoldVaultState (Dart)         │
│  • AndroidManifest captura scheme "goldvault" / "io.supabase.goldvault" │
│  • MainActivity.onNewIntent / onCreate captura el URI del Intent        │
│  • Envía URI a Dart -> sb.auth.getSessionFromUrl(uri) -> syncAll()      │
└─────────────────────────────────────────────────────────────────────────┘
```

### Mapeo de Componentes Interactivos y Estado

- **Interceptación Temprana en Web (`web/index.html`)**:
  - Verifica si la URL contiene `apk_redirect=1` en el query string o en el hash.
  - Si está presente, detiene la carga de `flutter_bootstrap.js` para que la instancia web de Supabase no consuma el código PKCE.
  - Construye la URL `goldvault://login-callback` conservando intactos `window.location.search` y `window.location.hash`, además de una URL alternativa `intent://login-callback...#Intent;scheme=goldvault;package=app.goldvault.goldvault;end`.
  - Ejecuta la redirección automática inmediata y renderiza una interfaz limpia con el botón manual **"Abrir en la app GoldVault"** por si el navegador bloquea la redirección automática.
- **Inicio de OAuth y Recepción en APK (`GoldVaultState`)**:
  - En Android nativo (`!kIsWeb`), `googleLogin()` utiliza `$prodWebUrl/?apk_redirect=1` como `redirectTo` con `LaunchMode.externalApplication`.
  - Expone un manejador `handleAuthDeepLink(String rawUrl)` conectado al canal nativo `app.goldvault/bank_notifications` que recibe cualquier enlace `goldvault://login-callback` (desde el puente web o directo) e invoca `sb.auth.getSessionFromUrl(Uri.parse(rawUrl))`.
- **Receptor de Intents en Android (`MainActivity.kt` & `AndroidManifest.xml`)**:
  - Sobrescribe `onNewIntent(intent: Intent)` y verifica `intent?.data` al iniciar para almacenar y transmitir cualquier URI de autenticación (`goldvault://` o `io.supabase.goldvault://`) hacia Flutter tan pronto como el motor Dart esté listo.
