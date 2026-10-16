# MafiFlow PC 1.5.2

Flutter comparte interfaz con Android. El ejecutable de Windows se genera como `MafiFlow.exe` y utiliza el icono oficial proporcionado.

## Compilación
Sube todos los archivos, incluida `.github/workflows/windows.yml`, y ejecuta GitHub Actions. Descarga la carpeta completa del artefacto. No ejecutes el EXE sin las DLL y la carpeta `data`.

## Cambios
- Moneda CUP (peso cubano), mostrada como `CUP` sin conversión de divisas.
- Calculadora adaptable a ventanas pequeñas.
- Logo oficial en interfaz y EXE.
- Nombre del ejecutable `MafiFlow.exe`.

## Datos
No borres los archivos de datos existentes. Realiza una exportación JSON antes de actualizar.

## Validación
El código fuente no se ha compilado aquí en Windows; GitHub Actions comprobará el resultado.


Fix 1.5.3: Windows icon embedded in Runner.rc; window title MafiFlow; responsive calculator display; custom URL shown only for Custom provider.
