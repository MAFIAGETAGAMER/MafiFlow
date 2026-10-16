# MafiFlow Windows 1.5.1 Beta

Esta versión reutiliza la interfaz Flutter de MafiFlow Mobile: navegación inferior, temas, idiomas, calculadora, calendarios, pagos recurrentes, estadísticas y centro de ayuda.

## Compilación en GitHub

Sube los archivos del proyecto a un repositorio GitHub y ejecuta **Actions > Build MafiFlow Windows EXE > Run workflow**. El artefacto `MafiFlow-Windows-1.5.1` contiene el directorio Windows Release completo. **No se debe distribuir únicamente el archivo .exe**: también necesita las DLL y los datos de la carpeta.

## Transferir datos de Android a Windows

1. En Android, entra en Ajustes > Exportar JSON. La copia se coloca en el portapapeles, sin la clave API.
2. Pega ese contenido en un archivo de texto y guárdalo como `MafiFlow-backup.json`, o transfiere el texto directamente al PC.
3. En Windows, Ajustes > Importar JSON > **Abrir archivo JSON** (o pega el texto). Confirma la sustitución de los datos locales.
4. En Windows, Ajustes > Exportar JSON copia el JSON al portapapeles y también permite guardarlo como archivo `.json`.

**Advertencia:** Importar reemplaza los datos actuales de Windows. Exporta una copia antes de importar. La clave API no se incluye en las exportaciones. Esta función es para copias JSON generadas por MafiFlow Mobile, no para el `datos.json` histórico de la aplicación Tkinter.

## Límites de verificación

No se ha ejecutado una compilación Windows real en este entorno. GitHub Actions incluye `flutter analyze` y `flutter build windows --release` para comprobar el proyecto. El centro de ayuda abre el cliente de correo; el envío directo requiere un servicio externo.
