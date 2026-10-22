# MafiFlow 1.5.7 — Corrección de acordeones del Centro de ayuda

## Causa de la regresión anterior

La versión 1.5.6 usaba dos `ListTile` controlados por una única variable (`category`) y dibujaba el formulario seleccionado en una **tarjeta común fuera de ambos títulos**. Por eso el contenido aparecía debajo de la otra fila, solo podía haber un formulario abierto y los borradores se mezclaban o se borraban al alternar. Además, el icono de cerrado era `chevron_right` en vez del mismo chevrón de las FAQ.

## Reparación

- Se reemplazaron **ambos** `ListTile` por **dos `ExpansionTile` nativos**, igual que las cuatro preguntas frecuentes que ya funcionaban correctamente.
- Cada `ExpansionTile` envuelve su formulario *dentro de* su propia tarjeta. La animación, la flecha abajo/arriba, el estilo, el comportamiento responsive y los colores los proporciona Flutter de manera idéntica a las FAQ. Los dos componentes tienen `PageStorageKey` para conservar el estado de expansión al desplazarse por la lista.
- Las dos secciones funcionan de forma **independiente**. Abrir o cerrar una no cambia la otra.
- Los controladores `bugDescription`, `bugLocation` e `ideaDescription` son distintos y sobreviven al plegado.
- El botón Enviar de cada sección toma únicamente los datos de esa sección. Se mantiene el aviso de privacidad y la localización previa en español, inglés, francés, alemán y bengalí.
- Se conserva el reconocimiento correcto de plataforma para el asunto y cuerpo del correo.

## Comprobaciones

Incluye cuatro pruebas de widgets en `test/help_center_test.dart` para abrir/cerrar por separado, verificar la posición visual del contenido, mantener dos borradores, comprobar que las FAQ siguen funcionando y recorrer cinco idiomas, temas claro/oscuro y un tamaño reducido de pantalla.

**Limitación real:** este entorno no dispone de Flutter ni del SDK de Windows. Los tests y la compilación MSIX se ejecutarán mediante el workflow de GitHub Actions de este repositorio. No consideres verificada la ejecución ni el empaquetado hasta que GitHub marque las pruebas y la compilación en verde y se haga una prueba manual del instalador.

## Archivos modificados

- `lib/main.dart` (solo Centro de ayuda)
- `test/help_center_test.dart`
- `pubspec.yaml` (`1.5.7+23`)
- `.github/workflows/windows.yml`, scripts y guía de Microsoft Store (MSIX `1.5.7.0`)

El resto del núcleo financiero no se modifica. El archivo `HISTORIAL-1.5.6.md` recoge la implementación anterior; esta corrección la sustituye.
