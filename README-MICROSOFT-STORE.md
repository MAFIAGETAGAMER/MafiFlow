# MafiFlow 1.5.9.0 — logo oficial y Microsoft Store

Fuente base: MafiFlow_1.5.8_FORMULARIOS_CORREGIDOS_MSIX.zip.
lib/main.dart y test/help_center_test.dart se conservan byte por byte; no se modificaron lógica financiera, formularios ni datos. Versión Flutter 1.5.9+25; paquete Store 1.5.9.0.

## Generar y descargar el paquete real

1. Sube el contenido completo de MafiFlow-main al repositorio, incluyendo carpetas ocultas.
2. Elimina el workflow antiguo .github/workflows/windows.yml del repositorio si todavía existe. Lo sustituye .github/workflows/microsoft-store.yml; conserva este único flujo para evitar compilaciones duplicadas.
3. Abre Actions → Compilar MafiFlow Windows y Microsoft Store MSIX → Run workflow. También se ejecuta al hacer push a main. No requiere campos ni secretos de firma.
4. Tras pasar análisis, pruebas y compilación, descarga MafiFlow-Microsoft-Store-MSIX-1.5.9. Dentro estarán el MSIX sin firmar y el informe *.verification.json.
5. Sube el MSIX a la actualización de la aplicación existente en Partner Center. Este proyecto no publica automáticamente.
6. Para el logo de la ficha, utiliza las imágenes de store_listing en los campos de logotipo correspondientes de Partner Center. Cambiar el paquete no garantiza que cambien los gráficos cargados por separado en la ficha. No uses StoreLogo.png de 50 px para un campo que pida 300 px.

Identidad configurada:
- Identity Name: Mafistudio.MafiFlow
- Publisher: CN=728E4776-BB76-436A-88FF-F627802F7887
- PublisherDisplayName: Mafistudio
- DisplayName de la aplicación: MafiFlow
- Version: 1.5.9.0, arquitectura x64

## Iconos

assets/MafiFlow-official.png conserva el adjunto original. Se mantiene su proporción y transparencia, centrado sin recortar ni redibujar.
assets/MafiFlow.ico: 16, 20, 24, 32, 40, 48, 64, 96, 128 y 256 px; se copia al recurso nativo IDI_APP_ICON antes de compilar.
store_assets: 90 PNG para logos de paquete, menú Inicio y mosaicos, escalas hasta 400% y variantes targetsize/unplated/lightunplated. MakePri genera resources.pri antes de MakeAppx.
store_listing: logos de 300, 150 y 71 px para la ficha.
assets/logo.png (imagen interna de la aplicación) se conserva del ZIP original.

## Comprobaciones automáticas del paquete

tools/Verificar-MSIX.ps1 abre el MSIX real, revisa identidad, versión, rutas del manifiesto y resources.pri. Compara por SHA-256 los 90 PNG empaquetados contra los assets oficiales y compara los diez recursos del icono de MafiFlow.exe con el ICO esperado. Si hay diferencias, el flujo falla antes de subir el artefacto MSIX. El informe no equivale a una prueba de ejecución o certificación Store.

Alternativa local, con Flutter, Visual Studio C++ y Windows SDK instalados:

```powershell
.\tools\Compilar-y-Empaquetar.ps1
```

Resultado: dist/MafiFlow_Store_x64_1.5.9.0.msix. El paquete Store se entrega sin firma local.

## Validación realizada al preparar este ZIP

- Sintaxis PowerShell y estructura de archivos revisadas.
- MakePri y MakeAppx ejecutados con un EXE SINTÉTICO de prueba: manifiesto y empaquetado aceptados; 90 logos y diez recursos ICO verificados. Un PNG alterado fue rechazado correctamente. El paquete sintético no se incluye ni es una compilación de MafiFlow.
- Integridad del ZIP, tamaños del ICO y preservación de archivos fuente comprobados; véase VALIDACION-1.5.9.json.
- NO se ejecutaron flutter analyze, flutter test ni flutter build windows: Flutter no está instalado aquí. No se verificó ejecución, instalación, persistencia de datos ni certificación Microsoft Store. El flujo incluido debe completar esas etapas antes de distribuir la aplicación.

Documentación usada: https://learn.microsoft.com/windows/apps/design/style/iconography/app-icon-construction y https://learn.microsoft.com/windows/uwp/app-resources/makepri-exe-command-options
