# Historial de correcciones — MafiFlow 1.5.6

| Área | Antes | Ahora |
|------|-------|-------|
| Centro de ayuda | Ambas opciones mostraban siempre chevrón a la derecha | La opción abierta muestra chevrón arriba; la cerrada, chevrón abajo |
| Reportar un error | Volver a pulsar reiniciaba campos | Abre/cierra conservando texto sin enviarlo ni borrarlo |
| Sugerir una función | Volver a pulsar reiniciaba campos | Abre/cierra conservando texto |
| Cambiar de formulario | Podía confundirse el estado de un reporte y una idea | Cada formulario conserva su propio borrador al alternar |
| Informes desde PC | Asunto indicaba `MafiFlow Mobile` y una versión beta antigua | El correo identifica `MafiFlow (Windows)` |
| Microsoft Store | El proyecto solo contenía compilación ZIP EXE | GitHub Actions puede crear un paquete MSIX para Partner Center con identidad real |

Archivos modificados: `lib/main.dart`, `pubspec.yaml`, `.github/workflows/windows.yml`, `README-WINDOWS.md`.
Archivos añadidos: `test/help_center_test.dart`, `tools/Crear-MSIX.ps1`, `tools/Branding-Windows.ps1`, `tools/Compilar-y-Empaquetar.ps1`, `store_assets/`, `README-MICROSOFT-STORE.md`, `CAMBIOS-1.5.6.md`.

El resto de funciones financieras y los formatos de datos guardados no han sido alterados intencionalmente.
