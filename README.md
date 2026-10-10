# MafiFlow 1.3.2

Aplicación gratuita de finanzas personales para Windows, creada por **Mafistudio**. Idiomas: español, inglés, francés, alemán y bengalí.

## Novedades

- El Consejero IA muestra inmediatamente un mensaje de espera animado **dentro de la conversación**.
- Cambia a «Esperando respuesta del proveedor…» cuando la conexión está establecida.
- Muestra el texto de respuesta progresivamente mediante streaming, sin congelar la interfaz.
- Conserva la corrección del gráfico circular de la versión 1.3.

## Ejecutar el código

Necesitas Python 3 y Tkinter. Ejecuta `python app.py`.

## Crear el EXE para Windows

**En GitHub:** abre la pestaña **Actions** → **Build Windows EXE** → **Run workflow**. Cuando termine, descarga el archivo **MafiFlow-1.3.2-Windows** desde **Artifacts**, descomprímelo y obtendrás `MafiFlow.exe`.

**En tu PC:** ejecuta `build.bat`. El ejecutable quedará en `dist\MafiFlow.exe`.

## Datos y privacidad

Los datos se guardan localmente en `%APPDATA%\MafiFlow\datos.json`. Haz una copia antes de actualizar. Las peticiones al Consejero IA envían mensajes y contexto financiero al proveedor que configures. **No publiques API Keys ni `datos.json` en GitHub.**

## Licencia

MIT. Comprueba las licencias de cualquier recurso de terceros antes de redistribuirlo.

Sitio de descarga: https://mafiageta.itch.io/mafiflow
