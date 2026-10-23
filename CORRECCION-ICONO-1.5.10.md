# MafiFlow 1.5.10.0: icono de Windows

Diagnóstico comprobado el 23 de octubre de 2026: la instalación local tiene versión 1.5.9.0, identidad `Mafistudio.MafiFlow`, publisher `CN=728E4776-BB76-436A-88FF-F627802F7887` y familia `Mafistudio.MafiFlow_86swettsa658c`. El icono extraído de su `MafiFlow.exe` es Flutter. Además, la comparación binaria contra el ICO oficial falla. La caché no explica por sí sola este ejecutable incorrecto.

Base: `MafiFlow_1.5.9_LOGO_OFICIAL_MSIX.zip`, el proyecto completo más reciente encontrado. Se conservan todos sus archivos de aplicación, pruebas, logos y recursos Store. `/mnt/data/MafiFlow.png` no está disponible en este equipo; se conserva `assets/MafiFlow-official.png` del proyecto 1.5.9, inspeccionado visualmente: M blanca con hojas verdes sobre fondo verde. No se ha podido comparar con el archivo original ausente.

La fuente 1.5.9 ya copiaba el ICO después de `flutter create` y verificaba el MSIX. Por tanto, no está demostrado qué workflow generó el EXE instalado. Se corrige también el escape de la ruta RC: el archivo RC debe contener `IDI_APP_ICON ICON "resources\\app_icon.ico"`. No se modifica `lib/main.dart` ni la funcionalidad.

## Compilar

Extrae el ZIP y sube el contenido de `MafiFlow-main` a la raíz del repositorio. El workflow completo está en `.github/workflows/microsoft-store.yml`; también se entrega por separado.

Ejecuta el workflow manualmente e indica la versión máxima de Partner Center en `published_version`. Para ejecución por push, configura la variable de repositorio `MAFIFLOW_PUBLISHED_VERSION`. La versión nueva es 1.5.10.0, superior a la instalada comprobada (1.5.9.0). Si Partner Center contiene otra igual o superior, el workflow se detiene: hay que incrementar las versiones del pubspec, workflow y scripts juntos.

Para compilar localmente desde la raíz del proyecto:

```powershell
./tools/Compilar-y-Empaquetar.ps1 -PublishedVersion '1.5.9.0'
```

Orden aplicado: `flutter clean` → `flutter create --platforms=windows --project-name mafiflow --org com.mafistudio .` → `tools/Branding-Windows.ps1` → dependencias/análisis/pruebas → `flutter build windows --release` → verificación del EXE → MakePri/MakeAppx → verificación del MSIX.

`Branding-Windows.ps1` copia `assets/MafiFlow.ico` a `windows/runner/resources/app_icon.ico`, compara SHA256 y configura `windows/runner/Runner.rc`. No ejecutes `flutter create` después del branding. `flutter clean` elimina salidas de compilación anteriores; no borra datos del usuario instalado.

Esta fuente utiliza MakeAppx, no `dart run msix:create`: se mantiene esa ruta para conservar identidad, Application Id `mafiflow` (comprobado en la instalacion) y recursos actuales. Si otro repositorio usa msix:create, aplica el mismo branding ANTES del build y de msix:create; configura `logo_path: assets/MafiFlow-official.png`, la misma identidad/publisher y una versión superior. Sustituir solo `logo_path` no corrige el recurso ICO del EXE.

Salida esperada: `dist/MafiFlow_Store_x64_1.5.10.0.msix` y su `.verification.json`. El verificador abre el EXE como recurso, sin ejecutarlo, y compara todos los frames ICO byte por byte. También valida identidad, versión, logos del manifiesto, variantes PNG y presencia de resources.pri. Un fallo detiene el empaquetado.

## Qué icono estás viendo

| Lugar | Recurso relevante |
|---|---|
| Ficha web/Store | Imágenes de la ficha en Partner Center |
| EXE, ventana, Alt+Tab y aplicación abierta | ICO integrado mediante Runner.rc; comprobar también que se abre el EXE nuevo |
| Inicio, mosaicos y accesos del paquete | AppxManifest.xml, Assets y resources.pri |
| Barra de tareas anclada | Puede conservar el acceso/icono anterior; comprobar primero ventana y EXE nuevos |
| Logo dibujado dentro de la interfaz | Assets Flutter; independiente del icono nativo |

## Prueba de actualización y caché

1. Antes de actualizar, guarda una copia de seguridad/exportación de datos y registra la versión con `Get-AppxPackage Mafistudio.MafiFlow | Select Name,Version,PackageFamilyName`. Crea un dato reconocible para comprobar persistencia.
2. Compila y exige que pasen análisis, pruebas, verificación del EXE y del MSIX. Abre `build/windows/x64/runner/Release/MafiFlow.exe` con TODA su carpeta Release presente y comprueba ventana, Alt+Tab y barra de tareas.
3. El MSIX generado no está firmado para instalación directa: súbelo a Partner Center y prueba la distribución firmada mediante un flight privado. No desinstales la versión existente para probar la actualización. Comprueba que pasa de 1.5.9.0 a 1.5.10.0, conserva la misma familia y los datos, y que abre desde Inicio con el icono oficial.
4. Prueba aparte una instalación nueva en una cuenta/equipo de prueba sin datos. Comprueba también navegación, formularios y funciones habituales. Un ZIP o un verificador de recursos no acredita estas pruebas.
5. Si EXE y ventana nuevos muestran el icono correcto pero el anclado sigue con Flutter: cierra MafiFlow, desancla el acceso anterior, abre desde Inicio y vuelve a anclar. Confirma en el Administrador de tareas que no estás abriendo una copia antigua. Cierra sesión y entra de nuevo si persiste. Solo tras estas comprobaciones considera reconstruir la caché de iconos; no borres datos de la app ni desinstales para limpiar iconos.

## Alcance de la validación

Se comprobó el icono Flutter del EXE instalado y la sintaxis PowerShell. El informe adjunto registra las comprobaciones de integridad del ZIP y preservación de archivos. Flutter no está disponible en esta sesión: NO se han ejecutado flutter analyze, flutter test, flutter build windows ni una instalación/actualización de la versión nueva. El ZIP es fuente preparada para compilar, no un MSIX nuevo probado. Los informes históricos 1.5.9 incluidos se refieren a esa versión anterior.

Referencias oficiales: https://docs.flutter.dev/platform-integration/windows/building y https://pub.dev/packages/msix.

Revision R2: consultar ANALISIS-WORKFLOWS-WINDOWS.md. Se corrigio la normalizacion de cabecera del ICO en el verificador, se preserva Application Id mafiflow y se exige que el EXE empaquetado coincida con Release. Se probaron aceptacion y rechazo con fixtures; no es un build Flutter.
