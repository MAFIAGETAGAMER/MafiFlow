# Auditoría de los workflows de MafiFlow — 23/10/2026

## Respuesta directa

Se compararon `windows.yml` de la fuente Windows 1.5.6, `microsoft-store.yml` de la fuente 1.5.9 (idéntico en el ZIP completo y la parte 1) y el workflow 1.5.10 preparado en esta sesión. En los tres, el branding se aplica DESPUÉS de `flutter create` y ANTES de `flutter build windows`. No se encontró otro `flutter create` posterior al branding en esos workflows.

El EXE y el MSIX no se compilan por dos rutas independientes en estos archivos: el mismo job compila Release una vez, publica esa carpeta y después `Crear-MSIX.ps1` copia esa misma carpeta al paquete. No ejecuta `dart run msix:create`, ni realiza un segundo build.

Por ello, el olvido de asignar el logo después de generar Windows NO se observa en los YAML disponibles. Esto no acredita cuál fue el YAML realmente ejecutado para publicar 1.5.9. No se tienen el repositorio remoto, commit, log de Actions ni artefacto descargado de esa ejecución.

## Evidencia del paquete instalado

Se leyó el AppxManifest.xml de la instalación en `C:\Program Files\WindowsApps\Mafistudio.MafiFlow_1.5.9.0_x64__86swettsa658c`:

| Dato | Instalado | Generador disponible 1.5.9 |
|---|---|---|
| Package Identity | Mafistudio.MafiFlow | Mafistudio.MafiFlow |
| Publisher | CN=728E4776-BB76-436A-88FF-F627802F7887 | Igual |
| Versión | 1.5.9.0 | 1.5.9.0 |
| Application Id | mafiflow | MafiFlow |
| Ejecutable declarado | mafiflow.exe | MafiFlow.exe |
| Directorio de logos | Images | Assets |
| Activación | EntryPoint=Windows.FullTrustApplication | uap10:RuntimeBehavior=packagedClassicApp |

El EXE instalado tiene el icono Flutter, extraído e inspeccionado visualmente. Windows no distingue mayúsculas en el nombre del archivo; esa diferencia sola no prueba otro binario. El conjunto de diferencias del manifiesto demuestra que el instalado no es la salida directa, sin modificaciones, del generador disponible. No permite identificar el pipeline exacto ni si se modificó o reempaquetó posteriormente.

La fuente 1.5.9 ya incluía un verificador de icono después del empaquetado. El EXE instalado con Flutter no habría superado esa comprobación contra el ICO oficial, si se hubiera ejecutado y respetado su fallo. No puede suponerse que el ZIP disponible fue el que se publicó solo porque ambos dicen 1.5.9.

## Pruebas ejecutadas ahora

1. Compilación real del recurso RC con Windows SDK 10.0.26100.0. La ruta anterior con una sola barra inversa falla con RC2135: el compilador interpreta una secuencia de escape. La ruta corregida con doble barra compila. Este defecto produce error; no genera por sí mismo un EXE exitoso con Flutter.
2. Compilación de un EXE mínimo de prueba con ese recurso y el ICO oficial. No es MafiFlow ni acredita un build Flutter.
3. El verificador original rechazaba también el EXE correcto: el compilador normaliza el campo planes del ICO PNG de 0 a 1. Se corrigió esa comparación en ambos verificadores. Las imágenes y el resto de los metadatos siguen comparándose; los datos de las 10 imágenes deben coincidir byte por byte.
4. Verificador corregido: ACEPTA el EXE de prueba con las 10 resoluciones oficiales y RECHAZA el EXE instalado con Flutter.
5. Paquetes ZIP sintéticos de prueba del verificador, que NO son aplicaciones instalables: ACEPTA el caso con 90 logos originales, el identificador correcto y el EXE esperado; RECHAZA un logo alterado, el Application Id incorrecto y un EXE que no coincide con Release. El resources.pri del fixture es ficticio: esto no valida MakePri, MakeAppx ni instalación.
6. Sintaxis PowerShell y conservación byte por byte de lib/main.dart, pruebas y todas las imágenes originales.

## Cambios adicionales respecto de la entrega anterior

La revisión R2 conserva el Application Id instalado `mafiflow`, además de Identity y Publisher. El verificador ahora lo exige. Se subsana así un dato que la entrega anterior no había contrastado con el manifiesto instalado.

El branding se aplica tras generar Windows y se reaplica inmediatamente antes del build. Después se verifica el recurso del EXE. Antes de empaquetar se vuelve a verificar; después se comprueba el EXE extraído del MSIX, los logos y que el EXE empaquetado sea idéntico al de Release. Si Flutter u otro paso deja un icono distinto, la comprobación falla antes de entregar un paquete válido en el workflow.

Orden final:

`clean → create Windows → branding → dependencias/análisis/pruebas → branding → build → verificar EXE → empaquetar misma carpeta Release → verificar EXE dentro de MSIX y logos`

Asignar el ICO solo antes de crear Windows no basta si la carpeta se genera luego con el icono de plantilla. Cambiar el ICO después del build tampoco modifica el EXE ya compilado: hay que recompilar. Flutter documenta el ICO en `windows/runner/resources/app_icon.ico`; el build Windows revisado invoca CMake/MSBuild y no vuelve a copiar el icono de plantilla como parte ordinaria del build.

El YAML completo que se entrega debe reemplazar al workflow activo utilizado para construir la app; no basta con guardar un YAML al lado sin ejecutarlo. Si el repositorio conserva otro `windows.yml`, hay que revisar qué ejecución y artefacto se descargan. No se inspeccionó el estado remoto del repositorio.

## Qué falta antes de publicar

La versión preparada sigue siendo 1.5.10.0, superior a la instalada comprobada. No se ha publicado nada. Flutter no está instalado/disponible en PATH aquí; no se ejecutaron su análisis, pruebas ni build completo. Falta UNA ejecución del workflow R2, que automatiza las comprobaciones, y después abrir el artefacto Windows correcto antes de enviarlo a Store. No hace falta publicar repetidas actualizaciones para comprobar si el EXE lleva el logo: la verificación se hace sobre el artefacto compilado.

Para identificar exactamente el origen de la publicación anterior, faltan el YAML/commit/log de la ejecución que generó el paquete subido a Partner Center. Con los archivos locales sí puede descartarse que el YAML disponible simplemente haya omitido el branding después de create; no puede atribuirse ese orden al pipeline publicado desconocido.

Fuentes primarias consultadas:
- https://docs.flutter.dev/platform-integration/windows/building
- https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/lib/src/windows/build_windows.dart
