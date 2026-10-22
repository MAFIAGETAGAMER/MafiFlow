# MafiFlow para Microsoft Store — Windows 1.5.6

Este ZIP contiene el **código Flutter/Dart corregido**, iconos originales, pruebas de la sección de ayuda y un generador MSIX. **No incluye un `.msix` compilado**: hay que compilar en Windows y utilizar los identificadores oficiales de Partner Center.

## Correcciones incluidas

- Las flechas de **Reportar un error** y **Sugerir una función** cambian según el formulario esté cerrado o abierto.
- Al pulsar una opción abierta, se cierra el formulario. Si lo vuelves a abrir, el texto escrito sigue allí.
- Cuando pasas de un reporte a una sugerencia, el borrador del otro formulario se limpia para evitar enviar un mensaje equivocado.
- El mensaje de correo identifica la plataforma: `MafiFlow (Windows)` en Windows, en lugar del antiguo `MafiFlow Mobile 1.0.6 Beta 17`.
- El icono original de Mafistudio se mantiene en la app y en las imágenes del paquete MSIX.
- Versión Flutter: `1.5.6+22`. Versión del paquete de Microsoft Store: `1.5.6.0`.

## Opción recomendada: generar EXE y MSIX con GitHub Actions

1. Extrae el ZIP y **sube el CONTENIDO de la carpeta `MafiFlow-main/`** al repositorio de GitHub donde construyes MafiFlow. Actualiza `.github/workflows/windows.yml` y todos los archivos nuevos. **No subas solamente el ZIP a Releases**, ya que GitHub Actions necesita acceder al código fuente.
2. Abre [Microsoft Partner Center](https://partner.microsoft.com/dashboard) → **MafiFlow → Identidad del producto / Product identity**. Copia de allí exactamente estos tres valores:
   - **Identity name** (`identity_name`): NO el nombre visible `MafiFlow` a secas; usa el nombre de identidad que Microsoft asignó.
   - **Publisher** (`publisher`): el valor completo, por ejemplo comenzando por `CN=`; **no inventes ni cambies espacios o caracteres**.
   - **Publisher display name** (`publisher_display_name`): el nombre autorizado por Microsoft; puede ser diferente de tu marca pública Mafistudio.
3. En el repositorio, entra a **Actions → Compilar MafiFlow Windows y Microsoft Store MSIX → Run workflow**.
4. Escribe los tres valores anteriores, selecciona la rama `main` y ejecuta el workflow.
5. Al terminar satisfactoriamente, en la ejecución de GitHub Actions aparecen **dos artefactos**:
   - `MafiFlow-Windows-1.5.6-FIX`: ejecutable Windows corregido con todas las DLL y recursos. Extrae **toda la carpeta**, no solo el `.exe`.
   - `MafiFlow-Microsoft-Store-MSIX-1.5.6`: archivo `.msix` **sin firmar**, destinado a **Partner Center → Paquetes**. Microsoft lo firma tras la certificación.
6. Sube el `.msix` resultante a la presentación ya creada en Microsoft Store.

Si se ejecuta el workflow sin los tres campos, se genera el EXE corregido pero **no** el MSIX. Si falla una prueba, no se genera el artefacto posterior; consulta el log y corrige el error antes de publicar.

## Alternativa: crear el MSIX desde tu PC Windows

Instala Flutter, Visual Studio con **Desarrollo para escritorio con C++** y Windows SDK. Abre PowerShell desde la carpeta raíz del proyecto y ejecuta **un solo script**, usando tus valores reales de Microsoft:

```powershell
.\tools\Compilar-y-Empaquetar.ps1 `
  -IdentityName 'IDENTIDAD_EXACTA_DE_PARTNER_CENTER' `
  -Publisher 'CN=EDITOR_EXACTO_DE_PARTNER_CENTER' `
  -PublisherDisplayName 'NOMBRE_PUBLICADOR_AUTORIZADO'
```

Este script genera el proyecto Windows, configura el branding, instala dependencias, analiza el código, ejecuta las pruebas, compila la versión Release y llama al generador MSIX.

Si todo pasa, el archivo generado estará en `dist\MafiFlow_Store_x64_1.5.6.0.msix`. Si fallan pruebas o compilación, **no debes subir un paquete anterior**.

También puedes hacerlo por pasos con `flutter create --platforms=windows --project-name mafiflow --org com.mafistudio .`, `tools/Branding-Windows.ps1`, `flutter pub get`, `flutter test`, `flutter build windows --release` y `tools/Crear-MSIX.ps1`.

## Pruebas antes de enviar a Microsoft

- Abrir la versión corregida y comprobar que el icono y título son MafiFlow.
- Ir a **Centro de ayuda** → **Reportar un error**. Verificar que la flecha cambie; escribir algo, cerrarlo y reabrirlo para comprobar que el texto se conserve.
- Abrir **Sugerir una función** y comprobar que tiene su propio formulario vacío.
- Probar el botón de correo electrónico si Windows tiene configurado un cliente predeterminado.
- Revisar ingresos, gastos, pagos recurrentes, estadísticas, idiomas y modo oscuro.
- Probar exportar/importar una copia de seguridad y confirmar que el guardado de datos financieros persiste después de cerrar/abrir la aplicación.
- **Importante al pasar de EXE a MSIX:** puede cambiar la ubicación de almacenamiento que usa Windows. Exporta una copia de los datos desde la versión anterior antes de instalar la versión de Microsoft Store; verifica que se puedan importar después. No desinstales ni borres datos antes de comprobarlo.
- Ejecutar `flutter analyze` y `flutter test` en Windows. Las pruebas automatizadas incluidas prueban el formulario, **no sustituyen las pruebas manuales de todas las funciones**.

## Limitaciones

Este entorno no compila ejecutables Flutter de Windows ni puede ejecutar MakeAppx de Windows SDK. Por eso el resultado que recibes es **el código fuente corregido y listo para compilar con GitHub Actions**, no un MSIX ya verificado. El flujo debe superar las pruebas en `windows-latest` y la revisión de Microsoft Store.

Recursos: [MSIX for Flutter](https://pub.dev/packages/msix) · [Microsoft MSIX](https://learn.microsoft.com/windows/msix/)
