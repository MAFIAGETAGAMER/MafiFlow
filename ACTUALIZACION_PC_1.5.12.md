# MafiFlow Windows 1.5.12+28 / MSIX 1.5.12.0

Proyecto actualizado desde el ZIP Windows 1.5.11+27 del usuario, trasladando las funciones y disposición final de Android 1.0.14+25. Los dos ZIP Windows 1.5.11 de Descargas contienen los mismos archivos.

## Funciones incluidas

- Ahorro inicial al configurar un perfil nuevo, separado del ingreso y reservado del dinero total indicado. Los perfiles existentes no repiten el asistente.
- Movimientos → Agregar permite agregar al ahorro, retirarlo y gastar desde él. El gasto desde ahorro queda vinculado a su ajuste, sin doble descuento; borrar ese gasto restaura el ahorro.
- Objetivo logrado y Nueva meta en Inicio solamente cuando se cumple el objetivo. Reiniciar una meta conserva el dinero ahorrado.
- Inicio compacto, sin botones para corregir disponible ni agregar/retirar/corregir ahorro.
- Ajustes empieza con Corregir saldo disponible, Corregir ahorro y Nueva meta; después vienen los campos de configuración. La sección final conserva ayuda, perfiles, categorías, JSON y añade el borrado del perfil.
- Borrado de información del perfil activo con confirmación escrita localizada; conserva los demás perfiles.
- Corrección del disponible mediante ajuste del saldo base: no crea ingresos/gastos ni altera el ahorro. Como la corrección del saldo inicial, recalcula también los saldos históricos; no es un ajuste fechado.
- Datos de ahorro y meta incluidos en el contexto del asesor desde la primera petición. Se envían los últimos veinte mensajes para conservar la pregunta reciente.
- Otro al final en selectores, administración de categorías y distribución por categorías en estadísticas. IDs guardados conservados y rótulo traducido.
- Cinco idiomas y temas existentes conservados.

## Particularidades de Windows conservadas

Se partió del proyecto Windows, manteniendo sus recursos y empaquetado. La importación desde archivo y la exportación a archivo JSON conservan literalmente la implementación Windows. El centro de ayuda y sus pruebas de borradores/acordeones también se conservan literalmente.

`name: mafiflow`, claves de almacenamiento `mafiflow_data`/`mafiflow_profiles_v1`, Application Id `mafiflow`, identidad `Mafistudio.MafiFlow`, Publisher `CN=728E4776-BB76-436A-88FF-F627802F7887` y PublisherDisplayName `Mafistudio` se conservan. Los gráficos de assets y store_assets, y el contenido de store_listing, son idénticos a la base.

## Generar el MSIX en GitHub

1. Extraer el ZIP y copiar **el contenido de MafiFlow-main** a la raíz del repositorio de PC. Incluir `lib`, `test`, `tools`, `assets`, `store_assets`, `pubspec.yaml` y `.github/workflows`. No usar el repositorio Android ni subir solamente el ZIP.
2. Abrir Actions → **MafiFlow - Microsoft Store MSIX CORREGIDO** → Run workflow. Es una ejecución manual. El workflow **Build MafiFlow Windows EXE** genera una carpeta de aplicación, no el paquete Store.
3. Esperar a que el trabajo MSIX completo termine verde. Descargar el artefacto **MafiFlow-MicrosoftStore-MSIX-1.5.12.0-LOGO-CORRECTO**.
4. Dentro estará **MafiFlow_Store_x64_1.5.12.0.msix**, más el informe de verificación, previews y evidencia de versión, commit y SHA256. El workflow no publica en Store.
5. Comprobar que 1.5.12.0 supera la mayor versión de ese producto en Partner Center. Revisar el MSIX real y probar la actualización sobre datos existentes antes de distribuirlo. Exportar una copia JSON antes de probar una actualización.

El workflow fija Flutter 3.35.7 y msix 3.18.0, genera el runner Windows aparte sin reemplazar lib/pubspec/tests, ejecuta analyze y las siete suites de pruebas, aplica el icono oficial, compila Windows una vez y verifica sus recursos. Empaqueta con `--build-windows false --logo-path assets/MafiFlow-official.png`. El verificador existente comprueba identidad, versión, Application Id, iconos y coincidencia del EXE empaquetado con Release antes de exportar. Un archivo ausente hace fallar la exportación.

## Comprobaciones realizadas y límites

**Realizado localmente:** conexiones de UI y datos, orden y condiciones de Inicio/Ajustes, presencia de cinco traducciones, versión y configuración Store; comparación de módulos financieros con el móvil; conservación exacta del centro de ayuda, pruebas de ayuda, selectores de archivo JSON y recursos/listing; análisis sintáctico de ambos YAML y de 18 scripts/bloques PowerShell; comprobación sintáctica de Python; CRC y contenido del ZIP final.

**No realizado:** Flutter analyze/test, compilación Windows, generación o inspección de un EXE/MSIX nuevo, instalación/actualización, llamadas reales al proveedor IA o validación/certificación en Microsoft Store. No hay Flutter/Dart disponible en PATH en este entorno. Este ZIP contiene fuentes; no se ha renombrado un paquete antiguo como si fuera nuevo. La sintaxis de un workflow no demuestra que una ejecución real vaya a terminar correctamente.

Las siete suites Dart están incluidas para ejecutarlas en Actions: finanzas, perfiles, ahorro/metas/borrado, saldo disponible, orden de categorías, historial del asesor y centro de ayuda Windows. No se incluye un pubspec.lock inventado: se exporta el que resuelva Flutter durante la compilación real.

## Comprobación local reproducible

Desde la raíz del proyecto:

```text
python tools/check_source.py
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

Para compilar localmente, con Flutter 3.35.7, Visual Studio C++ y Windows SDK, usar `tools/Compilar-y-Empaquetar.ps1 -PublishedVersion <version-real-publicada>`. Mantiene un control de que 1.5.12.0 sea mayor que la versión publicada. El método recomendado en esta entrega es el workflow MSIX de GitHub, que además exporta las verificaciones.

Los documentos de versiones anteriores se conservan como historial; esta guía corresponde a la nueva entrega.
