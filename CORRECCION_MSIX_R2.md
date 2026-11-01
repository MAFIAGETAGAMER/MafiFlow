# Corrección del empaquetado MSIX — 1.5.12+28, revisión R2

## Qué demuestra el log

El empaquetador terminó de crear `MafiFlow_Store_x64_1.5.11.0.msix`; el fallo aparece después, en Verificar-MSIX-Generado.ps1. El mensaje anterior agrupaba cuatro campos y no mostraba cuál fallaba: Identity.Name, Identity.Publisher, Identity.Version o PublisherDisplayName.

El archivo del log tiene versión 1.5.11.0, mientras que el proyecto actualizado de esta entrega es 1.5.12+28 / MSIX 1.5.12.0. Esto apunta a un workflow antiguo o a archivos de entregas mezcladas. Sin el manifiesto del paquete que falló no se puede afirmar cuál de los cuatro campos causó esa excepción concreta.

## Corrección

- `tools/Leer-Version.ps1` obtiene la versión desde pubspec.yaml. Nombre del archivo, argumento --version y versión esperada proceden de ese mismo resultado.
- `tools/Empaquetar-MSIX.ps1` agrupa empaquetado y verificación. El workflow ya no conserva su propio número de MSIX escrito a mano.
- `Verificar-MSIX-Generado.ps1` resuelve la versión desde pubspec por defecto, o recibe la misma versión explícita del empaquetador.
- `Verificar-Identidad-MSIX.ps1` imprime los cuatro valores esperados y reales. Si alguno falla, el error indica su nombre y ambos valores. Las comprobaciones de identidad, Publisher, ejecutable e iconos siguen siendo obligatorias.
- El manifiesto y el informe de identidad se guardan antes de detenerse por diferencias. GitHub exporta esos dos documentos en el artefacto MafiFlow-MSIX-diagnostico si falla el job después de extraerlos.
- El log muestra el commit y la versión al principio para identificar el código ejecutado.

No se han cambiado los módulos Dart, tests, logos ni la versión de la aplicación respecto de 1.5.12+28. R2 es una revisión del proceso de empaquetado, no una versión funcional nueva.

## Subir y ejecutar

1. Extraer el ZIP y sustituir **todo el contenido de MafiFlow-main** en el repositorio de PC, incluyendo pubspec.yaml, tools y .github/workflows. No colocar MafiFlow-main dentro de otra carpeta del repositorio. Mantener un único workflow activo para MSIX; si existía con otro nombre, sustituir también ese archivo para no ejecutar el antiguo por error.
2. Confirmar que pubspec.yaml dice `version: 1.5.12+28` y que el workflow Generar y verificar MSIX desde pubspec llama a `tools/Empaquetar-MSIX.ps1`.
3. Abrir Actions → MafiFlow - Microsoft Store MSIX CORREGIDO → Run workflow en la rama recién actualizada. Crear una ejecución nueva; volver a ejecutar el trabajo fallido puede seguir usando el código del commit anterior.
4. El log debe mostrar app 1.5.12+28 y MSIX 1.5.12.0. El artefacto exitoso contendrá `MafiFlow_Store_x64_1.5.12.0.msix`.
5. Si vuelve a fallar, el log mostrará el campo exacto. Descargar MafiFlow-MSIX-diagnostico para revisar el manifiesto y los cuatro valores. No modificar la identidad o el Publisher de la app para ocultar un error.

## Verificación de esta revisión

Ejecutados seis casos sintéticos en PowerShell: lectura y derivación de versión/ruta, identidad correcta y rechazo independiente de cada uno de los cuatro campos incorrectos, con informe y error detallados. YAML interpretado correctamente; sintaxis de 19 scripts/bloques PowerShell comprobada; comprobaciones estáticas de fuentes correctas; módulos Dart, pruebas y recursos comparados byte por byte con la entrega anterior; ZIP final comprobado por CRC y contenido.

No se ha compilado un MSIX real aquí ni inspeccionado el que falló en GitHub. No se presenta esta prueba sintética como compilación, instalación o certificación de Store. GitHub debe ejecutar el workflow completo para validar la reparación con el paquete real.
