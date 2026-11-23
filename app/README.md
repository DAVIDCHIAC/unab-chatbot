# Módulo 5 · App Flutter (Android)

Aplicación móvil del **Chatbot de Apoyo Académico UNAB**. Consume los webhooks
de n8n y presenta cuatro módulos:

| Módulo | Workflow | Endpoint |
|--------|----------|----------|
| Chat institucional (RAG) | WF01 | `POST /webhook/unab/rag` |
| Calendario académico | WF02 | `POST /webhook/unab/calendario` · `POST /webhook/unab/calendario/lista` |
| Historial y avance | WF03 | `POST /webhook/unab/academico` · `POST /webhook/unab/academico/resumen` |
| Noticias y convocatorias | WF04 | `POST /webhook/unab/noticias` |

La app **no** guarda llaves de Gemini, contraseñas de Supabase ni el token del
MCP: toda la orquestación ocurre en n8n y en el servidor FastMCP.

---

## 1. Requisitos

| Herramienta | Versión mínima | Nota |
|-------------|----------------|------|
| Flutter | **3.35** (stable) | Necesario por `AppBarThemeData` / `InputDecorationThemeData` |
| Dart | 3.9 | Viene incluido con Flutter 3.35 |
| Android SDK | API 24+ | Android Studio o `sdkmanager` |
| JDK | 17 | Requerido por Gradle reciente |
| Dispositivo | Android 7.0+ | Físico con depuración USB o emulador |

> **Validado en este repositorio** con Flutter **3.50.0** / Dart **3.14.0**,
> Android SDK 36 y JDK 17: `flutter pub get`, `flutter analyze` (0 errores),
> `flutter test` (7/7) y `flutter build apk --release` (APK de 50.7 MB).

Verifica la instalación:

```powershell
flutter doctor -v
flutter devices
```

---

## 2. Proyecto Android

El repositorio ya incluye la carpeta `android/` generada con:

```powershell
flutter create --platforms=android --org co.edu.unab --project-name unab_chatbot .
```

Queda con `applicationId = co.edu.unab.unab_chatbot`, `namespace` equivalente y
`android:label="UNAB Chatbot"`. Solo necesitas regenerarla si la borras o si
clonas el proyecto sin esa carpeta:

```powershell
flutter create --platforms=android --org co.edu.unab --project-name unab_chatbot .
flutter pub get
```

`flutter create` **no sobrescribe** los archivos existentes de `lib/`, el
`pubspec.yaml` ni el `AndroidManifest.xml` ya editado.

El archivo `test/widget_test.dart` fue reemplazado por pruebas reales de los
modelos y de `json_utils`; puedes ejecutarlas con `flutter test`.

### 2.1 Permiso de Internet (obligatorio)

Abre `android/app/src/main/AndroidManifest.xml` y agrega el permiso **antes**
de `<application>`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>

    <application
        android:label="UNAB Chatbot"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>
```

Sin este permiso el APK **release** falla con `SocketException` aunque el
debug funcione. En este repositorio el permiso ya está agregado en
`android/app/src/main/AndroidManifest.xml`.

### 2.2 HTTP en local (solo pruebas)

n8n Cloud y el MCP usan HTTPS, así que no necesitas nada extra. Si pruebas
contra un n8n local por `http://` en el emulador, habilita temporalmente:

```xml
<application
    android:usesCleartextTraffic="true"
    ... >
```

En el emulador, `localhost` del computador es `10.0.2.2`.

---

## 3. Configurar la URL de n8n

La URL se inyecta en tiempo de compilación con `--dart-define`; no hay que
editar código:

```powershell
flutter run --dart-define=N8N_BASE_URL=https://TU-INSTANCIA.app.n8n.cloud
```

El valor por defecto es `https://TU-INSTANCIA.app.n8n.cloud` y la app muestra
un aviso amarillo en el chat cuando detecta que no se configuró.

Para compilar el APK:

```powershell
flutter build apk --release --dart-define=N8N_BASE_URL=https://TU-INSTANCIA.app.n8n.cloud
```

Salida: `build/app/outputs/flutter-apk/app-release.apk`.

> El APK release se firma con la llave **debug** que genera Flutter: sirve para
> instalar y demostrar, pero no para publicar en Play Store. Para producción
> crea un keystore y configura `signingConfigs.release` en
> `android/app/build.gradle.kts`.

> `--dart-define` queda grabado en el binario. Si cambias la URL debes volver a
> compilar; no basta con reiniciar la app.

### 3.1 Aviso de `material.dart` en Flutter ≥ 3.47

`flutter analyze` puede mostrar 17 avisos **informativos** del tipo
`'package:flutter/material.dart' is deprecated ... Use package:material_ui/...`.
Son esperados: `material_ui` exige Flutter ≥ 3.47 y este proyecto mantiene
compatibilidad desde 3.35. No son errores y el APK compila sin problemas.
Para ocultarlos localmente puedes ejecutar `flutter analyze --no-fatal-infos`.

---

## 4. Ejecutar

```powershell
# 1. Verifica que los 4 workflows estén activos en n8n
# 2. Conecta el dispositivo o inicia el emulador
flutter devices

# 3. Ejecuta en modo debug
flutter run --dart-define=N8N_BASE_URL=https://TU-INSTANCIA.app.n8n.cloud
```

### Flujo de demostración

1. **Login**: pulsa *Probar con el estudiante demo* (código `10045234`).
2. **Chat**: pregunta `¿Cuáles son los requisitos de grado?`.
   El agente WF01 consulta el RAG por MCP.
3. **Calendario**: revisa los eventos y pregunta
   `¿Cuándo son los exámenes finales?`.
4. **Académico**: observa avance, alertas, cursos bloqueados por prerrequisito
   y proyección de grado. Pregunta `¿Qué puedo matricular el próximo semestre?`.
5. **Noticias**: filtra por *Becas* y abre una convocatoria.

El estudiante demo está en **semestre 3**, reprobó `IS201` (Cálculo Integral,
nota 2.4) y por eso `IS301` (Cálculo Multivariado) aparece bloqueado: es el caso
ideal para mostrar la recomendación de matrícula.

> Las fechas y noticias del demo son relativas a la fecha actual. Antes de
> grabar, ejecuta `database/08_actualizar_demo.sql` en Supabase.

---

## 5. Estructura del código

```
app/
├─ lib/
│  ├─ main.dart                 # MultiProvider + MaterialApp
│  ├─ config/app_config.dart    # URL de n8n, rutas y timeouts
│  ├─ theme/app_theme.dart      # Paleta UNAB y estilos Material 3
│  ├─ models/                   # ChatMessage, CalendarEvent, NewsItem, AcademicSummary
│  ├─ services/n8n_service.dart # Cliente HTTP y mapeo de errores
│  ├─ providers/                # Session, Chat, Calendar, Academic, News
│  ├─ screens/                  # Splash, Login, Home, Chat, Calendario, Académico, Noticias
│  ├─ widgets/                  # Burbujas, tarjetas, chips, estados vacío/error
│  └─ utils/                    # Formato de fechas y lectura tolerante de JSON
├─ pubspec.yaml
└─ analysis_options.yaml
```

Decisiones relevantes:

- **Sin `intl`**: los formatos en español se implementan en
  `utils/formatters.dart` para evitar conflictos de versión.
- **Sin `google_fonts`**: se usa la tipografía del sistema; la app funciona sin
  red adicional y sin descargas en tiempo de ejecución.
- **JSON tolerante**: `utils/json_utils.dart` acepta `int`, `double` o `String`
  porque Postgres/n8n pueden serializar distinto.
- **Errores accionables**: timeouts, `SocketException`, `404` (workflow
  inactivo) y respuestas vacías se muestran con instrucciones concretas.

---

## 6. Contrato con n8n

### 6.1 Chat

```json
{
  "session_id": "ses-1750000000000",
  "pregunta": "¿Cuáles son los requisitos de grado?",
  "id_estudiante": "10045234",
  "canal": "android"
}
```

Respuesta:

```json
{
  "ok": true,
  "session_id": "ses-1750000000000",
  "tipo": "rag",
  "respuesta": "Para obtener el título ...",
  "latencia_ms": 4210
}
```

### 6.2 Calendario (listado)

```json
{ "texto": "examen", "categoria": "examenes" }
```

```json
{
  "ok": true,
  "total": 3,
  "eventos": [
    {
      "id": 12,
      "periodo": "2026-20",
      "evento": "Exámenes finales",
      "categoria": "examenes",
      "fecha_inicio": "2026-11-24",
      "fecha_fin": "2026-11-28",
      "descripcion": "Semana de exámenes finales",
      "dias_faltantes": 9
    }
  ]
}
```

### 6.3 Resumen académico

```json
{ "id_estudiante": "10045234" }
```

```json
{
  "ok": true,
  "estado": { "nombre_completo": "Jhon García", "semestre_actual": 3, "...": "..." },
  "avance": { "porcentaje_avance": 18.8, "...": "..." },
  "proyeccion": { "semestres_restantes_estimados": 7, "...": "..." },
  "alertas": [ { "cursos_reprobados": 1, "alertas": ["Tiene asignaturas reprobadas"] } ],
  "bloqueados": [ { "curso_bloqueado": "IS301", "nombre_curso": "Cálculo Multivariado", "...": "..." } ],
  "historial": [ { "codigo_curso": "IS201", "curso": "Cálculo Integral", "nota": 2.4, "estado": "reprobado" } ]
}
```

### 6.4 Noticias

```json
{ "texto": "becas", "categoria": "beca", "canal": "android" }
```

```json
{
  "ok": true,
  "total": 2,
  "noticias": [
    {
      "id": 4,
      "titulo": "Beca Excelencia UNAB 2027",
      "resumen": "Dirigida a estudiantes con promedio superior a 4.0",
      "url": "https://www.unab.edu.co/...",
      "fuente": "UNAB",
      "categoria": "beca",
      "fecha_publicacion": "2026-11-10",
      "dias_publicada": 5
    }
  ]
}
```

---

## 7. Capturas para el informe

Guarda las imágenes en `../docs/capturas/` con estos nombres:

| Archivo | Contenido |
|---------|-----------|
| `01-login.png` | Pantalla de identificación con el botón del estudiante demo |
| `02-chat.png` | Chat con una respuesta RAG y enlaces |
| `03-calendario.png` | Listado filtrado por *Exámenes* |
| `04-academico.png` | Encabezado con avance, alertas y cursos bloqueados |
| `05-noticias.png` | Noticias filtradas por *Becas* |
| `06-n8n.png` | Workflow WF01 abierto en n8n |
| `07-mcp.png` | Respuesta de `/health` del servidor MCP |

---

## 8. Solución de problemas

| Síntoma | Causa probable | Solución |
|---------|----------------|----------|
| Aviso amarillo “Falta configurar la URL de n8n” | No se pasó `--dart-define` | Recompila con la URL real |
| `404` en el chat | Workflow inactivo o URL de *test* | Activa el workflow y usa la Production URL |
| `SocketException` en release | Falta `INTERNET` en el manifest | Agrega el permiso y recompila |
| Timeout a los 90 s | WF01 esperando al MCP/Gemini | Revisa `/health` del MCP y los logs de n8n |
| “n8n devolvió una respuesta vacía” | Nodo *Respond to Webhook* mal conectado | Revisa el mapa de nodos en `../n8n/README.md` |
| Respuesta sin acentos | Codificación distinta a UTF-8 | El servicio ya usa `utf8.decode`; revisa el nodo Code |
| Calendario vacío | Fechas del demo vencidas | Ejecuta `database/08_actualizar_demo.sql` |
| `flutter pub get` falla por SDK | Flutter < 3.35 | Actualiza con `flutter upgrade` |
| `Gradle task assembleDebug failed` | JDK incorrecto | Usa JDK 17 (`flutter doctor -v`) |

---

## 9. Seguridad y alcance

- El login por código es **demostrativo**: no valida identidad. En producción
  debe integrarse con Supabase Auth y validar el `id_estudiante` en el backend.
- Los webhooks de n8n se dejan públicos para facilitar la demo. Para producción,
  activa *Header Auth* en cada nodo Webhook y envía el header desde la app
  (ver `../n8n/README.md`, sección 8).
- No incluyas `.env`, llaves ni contraseñas en la app ni en el repositorio.
- La app solo realiza peticiones HTTPS a n8n; no se conecta directamente a
  Supabase ni al servidor MCP.

---

## 10. Checklist de verificación

- [x] `flutter doctor` sin errores críticos.
- [x] `flutter pub get` resuelve dependencias.
- [x] `flutter analyze` sin errores (solo avisos informativos de `material.dart`).
- [x] `flutter test` (7 pruebas de modelos y `json_utils`).
- [x] `INTERNET` agregado al manifest.
- [x] `flutter build apk --release` genera el APK.
- [ ] Los 4 workflows están **activos** en n8n.
- [ ] `GET https://<mcp>/health` responde `{"status":"ok"}`.
- [ ] Login con `10045234` y las cuatro pestañas cargan datos.
- [ ] Capturas guardadas en `docs/capturas/`.
