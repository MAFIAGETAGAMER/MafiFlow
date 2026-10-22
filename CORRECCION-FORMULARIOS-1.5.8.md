# MafiFlow 1.5.8 — Corrección del rectángulo gris al expandir formularios

## Incidencia confirmada por las capturas del usuario

Después de la actualización 1.5.7, las flechas funcionaban, pero desplegar «Reportar un error» o «Sugerir una función» mostraba una superficie gris sólida enorme en lugar de los campos. Ese aspecto **coincide** con el widget de error que Flutter dibuja en modo release ante un fallo de construcción/renderizado. La excepción exacta solo puede establecerse mediante logs de una ejecución real en Windows: no se ha supuesto conocer su mensaje.

## Cambio aplicado

- «Preguntas frecuentes» permanece sin tocar y sigue usando el `ExpansionTile` nativo.
- Los dos encabezados de feedback mantienen el patrón visual de las FAQ (chevron hacia abajo cerrado, arriba abierto y rotación animada de 200 ms), pero el contenido utiliza un `AnimatedSize` independiente, sin incrustar campos de texto en el constructor animado de `ExpansionTile`.
- Cada sección tiene estado booleano propio y su contenido justo debajo del encabezado, dentro de la misma tarjeta.
- El formulario usa `Column(mainAxisSize: MainAxisSize.min)` y límites máximos de altura (410 px para error y 310 px para sugerencia) con scroll interior si el contenido necesita más espacio; los campos son de hasta 5 líneas, y el ancho sigue el contenedor.
- Tres `TextEditingController` preservan los borradores al cerrar y reabrir.
- Los textos siguen tomando los cinco idiomas del proyecto y el color de iconos sigue el `colorScheme` activo; no se alteran los datos financieros, IA, transacciones ni la lógica de envío.

## Pruebas

`test/help_center_test.dart` incluye verificaciones de orientación, independencia, textos, posición y dimensiones finitas, ausencia de `ErrorWidget`, funcionamiento de FAQ, tamaños estrechos, temas y traducciones. El workflow GitHub Actions ejecuta `flutter analyze`, `flutter test` y luego compila Windows, y puede generar MSIX `1.5.8.0` al proporcionar la identidad real de Partner Center.

**Importante:** no se pudo ejecutar el SDK Flutter ni la app Windows en este contenedor. Se ha revisado estáticamente el proyecto y comprobado la integridad del ZIP, pero la corrección sigue pendiente de validación con los tests de Flutter y prueba visual del Windows release compilado. Si el error persiste en el nuevo ejecutable, ejecutar `flutter run -d windows` en debug y revisar la primera excepción de la consola para identificar la causa exacta. No publicar en Microsoft Store hasta verificar que los formularios funcionen.
