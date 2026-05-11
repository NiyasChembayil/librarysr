import 'api_client.dart';

class MediaService {
  /// Ensures a media URL is absolute and points to the correct backend.
  /// If the URL is relative (e.g. /media/...), it prepends the current API base URL.
  /// If it contains '127.0.0.1' or 'localhost', it replaces it with the actual base URL
  /// if we are running in production.
  static String? sanitizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    // 1. If it's already a full external URL (S3, Cloudinary, etc.), leave it
    if (url.startsWith('http') && !url.contains('127.0.0.1') && !url.contains('localhost')) {
      return url;
    }

    // 2. Get the base domain from ApiClient (remove '/api/')
    // For now, let's use the default domain but make it smart.
    
    const String productionDomain = 'https://srishty-backend.onrender.com';

    // 3. Handle relative paths
    if (url.startsWith('/')) {
      // In a real app, you'd use a dynamic config. 
      // For this project, we'll assume Render if it's not local.
      return '$productionDomain$url';
    }

    // 4. Handle hardcoded local URLs from older code
    if (url.contains('127.0.0.1') || url.contains('localhost')) {
      return url.replaceAll(RegExp(r'http://(127\.0\.0\.1|localhost):8000'), productionDomain);
    }

    return url;
  }
}
