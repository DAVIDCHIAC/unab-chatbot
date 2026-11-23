/// Configuración global de la app.
///
/// La URL de n8n se puede cambiar sin tocar el código:
///
/// ```bash
/// flutter run --dart-define=N8N_BASE_URL=https://mi-instancia.app.n8n.cloud
/// ```
class AppConfig {
  AppConfig._();

  static const String n8nBaseUrl = String.fromEnvironment(
    'N8N_BASE_URL',
    defaultValue: 'https://TU-INSTANCIA.app.n8n.cloud',
  );

  // Endpoints de los workflows
  static const String ragPath = '/webhook/unab/rag';
  static const String calendarPath = '/webhook/unab/calendario';
  static const String calendarListPath = '/webhook/unab/calendario/lista';
  static const String academicPath = '/webhook/unab/academico';
  static const String academicSummaryPath = '/webhook/unab/academico/resumen';
  static const String newsPath = '/webhook/unab/noticias';

  // Tiempos de espera
  static const Duration chatTimeout = Duration(seconds: 90);
  static const Duration listTimeout = Duration(seconds: 30);

  // Datos de demostración
  static const String demoStudentId = '10045234';
  static const String demoStudentName = 'Jhon García';

  static Uri uri(String path) => Uri.parse('$n8nBaseUrl$path');

  static bool get isConfigured => !n8nBaseUrl.contains('TU-INSTANCIA');
}
