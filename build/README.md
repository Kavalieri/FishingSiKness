# Build System

Este directorio contiene scripts y configuración para el sistema de build del proyecto.

## Estructura

- `version.json` - Metadatos del juego y versión
- `version-history.json` - Historial de versiones detallado
- `release-system/` - Scripts de build para diferentes plataformas
- `builds/` - Directorio de salida para builds compilados (gitignored)

## Versionado

- **`version.txt`** (raíz del proyecto) - Versión principal actualizada automáticamente por release-please
- **`version.json`** - Versión y metadatos del juego **actualizada manualmente**
- **`.release-please-manifest.json`** - Estado interno de release-please

> **Nota**: `build/version.json` debe actualizarse manualmente cuando se haga una release.
> Release-please solo actualiza automáticamente `version.txt` y el changelog.

## Scripts de Build

Ver `build/release-system/` para scripts específicos de cada plataforma.
