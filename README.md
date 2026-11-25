# Gestor de tareas local (Flutter + SQLite con Drift)

Práctica de Programación de Dispositivos Móviles (UAA, 7.º semestre).
App Flutter que administra tareas en una base **SQLite local**: sin servidor,
sin MySQL y sin internet. Los datos se conservan al cerrar y volver a abrir la app.

## Tecnología elegida y por qué

| Paquete | Uso |
|---|---|
| `drift` | ORM/consultas tipadas sobre SQLite. Define la tabla en Dart y genera el código. |
| `drift_flutter` | Abre la base en la ubicación correcta de cada plataforma con una sola llamada (`driftDatabase`). |
| `drift_dev` + `build_runner` (dev) | Generan el archivo `*.g.dart` a partir de la definición de la tabla. |

**Por qué Drift y no `sqflite`:** `sqflite` solo funciona en Android/iOS/macOS;
en Windows/Linux necesita `sqflite_common_ffi` y en web no tiene soporte oficial.
Drift usa el mismo código en **móvil, escritorio y web** (en web corre SQLite
compilado a WebAssembly), lo que cumple el requisito de un solo proyecto para
los tres entornos. Además ofrece consultas `watch()` (Stream) que actualizan la
interfaz automáticamente después de cada escritura.

## Diseño de la tabla `tareas`

| Columna | Tipo en Dart (Drift) | Tipo en SQLite | Restricciones |
|---|---|---|---|
| `id` | `IntColumn` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` |
| `titulo` | `TextColumn` | `TEXT` | `NOT NULL`, longitud 1–200 |
| `completada` | `BoolColumn` | `INTEGER` (0/1) | `NOT NULL`, `DEFAULT 0`, `CHECK (completada IN (0, 1))` |

- **Identificación de cada registro:** `id` lo asigna SQLite al insertar
  (autoincremental); nunca lo pone la app. Editar, cambiar estado y eliminar
  se hacen por `id` (`WHERE id = ?`).
- **Booleano:** SQLite no tiene tipo `BOOLEAN`; Drift lo guarda como `INTEGER`
  0/1 y lo convierte a `bool` en Dart.
- **Validación del título:** se aplica `trim()` y se rechazan títulos vacíos
  antes de llegar a la base.

## Cómo ejecutar

```powershell
flutter pub get
dart run build_runner build                                # regenera *.g.dart (solo si cambias la tabla)
flutter analyze
flutter test
flutter run -d windows                                     # escritorio
flutter run -d chrome --web-port 5000                      # web (puerto FIJO)
```

> En Windows hay que activar el **Modo de desarrollador** (`start ms-settings:developers`):
> Flutter necesita enlaces simbólicos para compilar con plugins.
>
> `lib/data/database.g.dart` se incluye en el repositorio para que el proyecto
> compile justo después de `git clone`.
>
> En web el almacenamiento depende del **origen** (`http://localhost:5000`).
> Sin puerto fijo, cada ejecución usa otro origen y los datos parecen perdidos.

## Estado

- [x] Etapa 0: proyecto base creado con `flutter create`
- [x] Etapa 1: tecnología elegida y diseño de la tabla (este README)
- [ ] Etapa 2: persistencia real (crear y consultar)
- [ ] Etapa 3: editar, cambiar estado, eliminar y validación
- [ ] Etapa 4: web configurada, pruebas automatizadas y resultados
