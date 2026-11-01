# MafiFlow PC reconstruido — 1.5.12+28 / MSIX 1.5.12.0

## Descargas y copia manual de .github

El proyecto completo incluye todos los archivos de la aplicación. También se entregan los dos workflows en una carpeta visible **GITHUB_COPIAR_MANUALMENTE**, en un ZIP separado sin carpetas con punto y como archivos .yml individuales.

1. Extraer el proyecto y copiar el contenido de MafiFlow-main a la raíz del repositorio de PC: lib, test, tools, assets, store_assets, store_listing, pubspec.yaml y resto de archivos. No subir el ZIP como un único archivo.
2. **Paso imprescindible para este error:** en la web de GitHub abrir `.github/workflows/microsoft-store.yml`, pulsar el lápiz y sustituir **todo su contenido** por el archivo visible `GITHUB_COPIAR_MANUALMENTE/microsoft-store.yml`. No pegar solo los scripts de tools. Si el workflow MSIX anterior está en otro archivo .yml, sustituir el contenido de ese archivo por este mismo workflow para no seguir ejecutando el antiguo.
3. Hacer lo mismo con `.github/workflows/windows.yml` usando el archivo visible windows.yml. Este segundo workflow genera la aplicación EXE; no es el destinado a subir a Store.
4. Si la carpeta no existe en GitHub, usar Add file → Create new file y escribir la ruta completa `.github/workflows/microsoft-store.yml`, pegar el contenido y guardar el commit. Repetir con windows.yml.
5. Confirmar que pubspec.yaml dice `version: 1.5.12+28`.
6. En Actions seleccionar exactamente **MafiFlow PC - MSIX 1.5.12 RECONSTRUIDO**, y crear una ejecución nueva con Run workflow en la rama actualizada. Si no aparece ese nombre, el workflow nuevo todavía no está en esa rama. No volver a ejecutar el job del commit anterior.
7. El artefacto de éxito se llama **MafiFlow-MicrosoftStore-MSIX-1.5.12.0-RECONSTRUIDO** y contiene **MafiFlow_Store_x64_1.5.12.0.msix**, junto con verificaciones y evidencia de commit/versión/SHA256.

## Base utilizada y causa confirmada

Se ha reconstruido desde `MafiFlow_Windows_1.5.11_Perfiles_MSStore_Source (1).zip`, la base Windows con la que se generó el último paquete de referencia. Se inspeccionó además el MSIX real contenido en `MafiFlow-MicrosoftStore-MSIX-1.5.10.0-LOGO-CORRECTO (1).zip`: aunque el ZIP externo tiene un nombre antiguo, el archivo interno y su manifiesto son **1.5.11.0**. Los datos exactos y el hash del paquete de referencia están en BASE_MSIX_1.5.11.json.

Se reprodujo la excepción usando ese manifiesto real: identidad, Publisher y PublisherDisplayName son correctos; solamente Identity.Version es 1.5.11.0 cuando se espera 1.5.12.0. Los logs enviados corresponden a un empaquetado que todavía tiene el argumento --version 1.5.11.0 en el workflow antiguo, combinado con el verificador actualizado. Por eso actualizar solamente los archivos visibles y omitir .github no puede resolverlo.

## Reparación

La versión de la aplicación, versión MSIX derivada, argumentos del empaquetador, nombre del archivo, versión esperada por el verificador y artefacto de GitHub quedan coordinados mediante pubspec.yaml y tools/Leer-Version.ps1. También se actualizó la compilación manual y el generador auxiliar para leer esa versión. No se cambia ni se omite ninguna comprobación de identidad.

Las funciones móviles se reaplicaron a la base Windows: ahorro inicial, depósito/retiro/gasto desde ahorro, metas cumplidas y reinicio, correcciones de saldo, borrado del perfil, contexto/historial IA, Otro al final y el orden visual final de Inicio/Ajustes. Se conservan los selectores de archivos JSON, el centro de ayuda Windows, traducciones, almacenamiento, identidad Store, logos e iconos originales. Los documentos viejos se guardan en documentacion_historica para evitar seguir instrucciones de otras versiones.

## Validación

- Inspección del manifiesto del MSIX de referencia 1.5.11.0 y reproducción del error concreto de versión.
- Seis pruebas sintéticas de versión/identidad: versión derivada y ruta, identidad válida y rechazo de cada uno de los cuatro campos incorrectos.
- Dos pruebas de integración simulada del empaquetador con pubspec 1.5.12+28 y 1.5.13+29. Se comprueban --version, --output-name, ruta y ExpectedVersion. Dart y el verificador completo se sustituyen por dobles de prueba: estas pruebas no compilan un MSIX.
- Comprobaciones estáticas de conexiones de UI, traducciones, versiones, orden de empaquetado e identidad; YAML y sintaxis PowerShell; comparación de módulos y recursos; integridad CRC y contenido de los ZIP entregados; igualdad de los workflows visibles y los de .github.

No se ejecutó Flutter analyze/test/build ni se creó o instaló un nuevo MSIX en este entorno, donde Flutter/Dart no están disponibles en PATH. Las pruebas Dart y la compilación real quedan incluidas en GitHub Actions. El ZIP del proyecto contiene fuentes. El paquete 1.5.11.0 solo se usó como referencia y no se entrega modificado como si fuera un MSIX nuevo.

Antes de publicar en Partner Center, la versión 1.5.12.0 debe superar la mayor versión del producto allí registrada. Probar actualización con copia de seguridad de los datos existentes y revisar el MSIX que genere esta ejecución.
