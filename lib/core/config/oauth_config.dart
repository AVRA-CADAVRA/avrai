/// OAuth Configuration
///
/// Manages OAuth credentials, redirect URIs, and scopes for social media platforms.
/// Credentials are provided via --dart-define flags for security.
///
/// **Usage:**
/// ```bash
/// flutter run --dart-define=GOOGLE_OAUTH_CLIENT_ID=your_client_id \
///            --dart-define=INSTAGRAM_OAUTH_CLIENT_ID=your_instagram_id \
///            --dart-define=FACEBOOK_OAUTH_CLIENT_ID=your_facebook_id
/// ```
///
/// **Feature Flag:**
/// Set `USE_REAL_OAUTH=true` to enable real OAuth flows (defaults to false for placeholder mode).
class OAuthConfig {
  /// Feature flag: Use real OAuth or placeholders
  static const bool useRealOAuth = bool.fromEnvironment(
    'USE_REAL_OAUTH',
    defaultValue: false, // Default to placeholders for development
  );

  // Google OAuth
  // Note: For native sign-in, Android/iOS use platform-specific client IDs from native configs
  // This Dart client ID is used for token refresh and API calls (can use Android client ID)
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_ID',
    defaultValue: '', // Empty = use placeholder
  );

  // Platform-specific client IDs (for reference - actual sign-in uses native configs)
  static const String googleClientIdAndroid = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_ID_ANDROID',
    defaultValue: '',
  );

  static const String googleClientIdIOS = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_ID_IOS',
    defaultValue: '',
  );

  // Instagram OAuth
  static const String instagramClientId = String.fromEnvironment(
    'INSTAGRAM_OAUTH_CLIENT_ID',
    defaultValue: '',
  );
  static const String instagramClientSecret = String.fromEnvironment(
    'INSTAGRAM_OAUTH_CLIENT_SECRET',
    defaultValue: '',
  );

  // Facebook OAuth
  static const String facebookClientId = String.fromEnvironment(
    'FACEBOOK_OAUTH_CLIENT_ID',
    defaultValue: '',
  );
  static const String facebookClientSecret = String.fromEnvironment(
    'FACEBOOK_OAUTH_CLIENT_SECRET',
    defaultValue: '',
  );

  // Twitter/X OAuth
  static const String twitterClientId = String.fromEnvironment(
    'TWITTER_OAUTH_CLIENT_ID',
    defaultValue: '',
  );
  static const String twitterClientSecret = String.fromEnvironment(
    'TWITTER_OAUTH_CLIENT_SECRET',
    defaultValue: '',
  );

  // Reddit OAuth
  static const String redditClientId = String.fromEnvironment(
    'REDDIT_OAUTH_CLIENT_ID',
    defaultValue: '',
  );
  static const String redditClientSecret = String.fromEnvironment(
    'REDDIT_OAUTH_CLIENT_SECRET',
    defaultValue: '',
  );

  // TikTok OAuth
  static const String tiktokClientId = String.fromEnvironment(
    'TIKTOK_OAUTH_CLIENT_ID',
    defaultValue: '',
  );
  static const String tiktokClientSecret = String.fromEnvironment(
    'TIKTOK_OAUTH_CLIENT_SECRET',
    defaultValue: '',
  );

  // Tumblr OAuth
  static const String tumblrClientId = String.fromEnvironment(
    'TUMBLR_OAUTH_CLIENT_ID',
    defaultValue: '',
  );
  static const String tumblrClientSecret = String.fromEnvironment(
    'TUMBLR_OAUTH_CLIENT_SECRET',
    defaultValue: '',
  );

  // YouTube OAuth (uses Google OAuth)
  // Uses googleClientId and googleClientSecret

  // Pinterest OAuth
  static const String pinterestClientId = String.fromEnvironment(
    'PINTEREST_OAUTH_CLIENT_ID',
    defaultValue: '',
  );
  static const String pinterestClientSecret = String.fromEnvironment(
    'PINTEREST_OAUTH_CLIENT_SECRET',
    defaultValue: '',
  );

  // Are.na OAuth
  static const String arenaClientId = String.fromEnvironment(
    'ARENA_OAUTH_CLIENT_ID',
    defaultValue: '',
  );
  static const String arenaClientSecret = String.fromEnvironment(
    'ARENA_OAUTH_CLIENT_SECRET',
    defaultValue: '',
  );

  // LinkedIn OAuth
  static const String linkedinClientId = String.fromEnvironment(
    'LINKEDIN_OAUTH_CLIENT_ID',
    defaultValue: '',
  );
  static const String linkedinClientSecret = String.fromEnvironment(
    'LINKEDIN_OAUTH_CLIENT_SECRET',
    defaultValue: '',
  );

  // Redirect URI Configuration
  static const String redirectUriScheme = 'avrai';
  static String getRedirectUri(String platform) => '$redirectUriScheme://oauth';

  // OAuth Scopes
  static const List<String> googleScopes = [
    'profile',
    'email',
    'https://www.googleapis.com/auth/places',
    'https://www.googleapis.com/auth/photos',
  ];

  static const List<String> instagramScopes = [
    'user_profile',
    'user_media',
  ];

  static const List<String> facebookScopes = [
    'public_profile',
    'email',
    'user_friends',
  ];

  static const List<String> twitterScopes = [
    'tweet.read',
    'users.read',
    'follows.read',
    'offline.access',
  ];

  static const List<String> redditScopes = [
    'identity',
    'read',
    'history',
  ];

  static const List<String> tiktokScopes = [
    'user.info.basic',
    'user.info.profile',
    'user.info.stats',
  ];

  static const List<String> tumblrScopes = [
    'basic',
    'read',
  ];

  static const List<String> pinterestScopes = [
    'boards:read',
    'pins:read',
    'user_accounts:read',
  ];

  static const List<String> arenaScopes = [
    'public',
    'read',
  ];

  static const List<String> linkedinScopes = [
    'openid',
    'profile',
    'email',
    'w_member_social',
  ];

  /// Check if Google OAuth is configured
  static bool get isGoogleConfigured =>
      useRealOAuth && googleClientId.isNotEmpty;

  /// Check if Instagram OAuth is configured
  static bool get isInstagramConfigured =>
      useRealOAuth &&
      instagramClientId.isNotEmpty &&
      instagramClientSecret.isNotEmpty;

  /// Check if Facebook OAuth is configured
  static bool get isFacebookConfigured =>
      useRealOAuth &&
      facebookClientId.isNotEmpty &&
      facebookClientSecret.isNotEmpty;

  /// Check if Twitter OAuth is configured
  static bool get isTwitterConfigured =>
      useRealOAuth &&
      twitterClientId.isNotEmpty &&
      twitterClientSecret.isNotEmpty;

  /// Check if Reddit OAuth is configured
  static bool get isRedditConfigured =>
      useRealOAuth &&
      redditClientId.isNotEmpty &&
      redditClientSecret.isNotEmpty;

  /// Check if TikTok OAuth is configured
  static bool get isTikTokConfigured =>
      useRealOAuth &&
      tiktokClientId.isNotEmpty &&
      tiktokClientSecret.isNotEmpty;

  /// Check if Tumblr OAuth is configured
  static bool get isTumblrConfigured =>
      useRealOAuth &&
      tumblrClientId.isNotEmpty &&
      tumblrClientSecret.isNotEmpty;

  /// Check if Pinterest OAuth is configured
  static bool get isPinterestConfigured =>
      useRealOAuth &&
      pinterestClientId.isNotEmpty &&
      pinterestClientSecret.isNotEmpty;

  /// Check if Are.na OAuth is configured
  static bool get isArenaConfigured =>
      useRealOAuth && arenaClientId.isNotEmpty && arenaClientSecret.isNotEmpty;

  /// Check if LinkedIn OAuth is configured
  static bool get isLinkedInConfigured =>
      useRealOAuth &&
      linkedinClientId.isNotEmpty &&
      linkedinClientSecret.isNotEmpty;

  /// Get OAuth authorization URL for a platform
  static String getAuthorizationUrl(String platform) {
    switch (platform.toLowerCase()) {
      case 'google':
        return 'https://accounts.google.com/o/oauth2/v2/auth';
      case 'instagram':
        return 'https://api.instagram.com/oauth/authorize';
      case 'facebook':
        return 'https://www.facebook.com/v18.0/dialog/oauth';
      case 'twitter':
        return 'https://twitter.com/i/oauth2/authorize';
      case 'reddit':
        return 'https://www.reddit.com/api/v1/authorize';
      case 'tiktok':
        return 'https://www.tiktok.com/v2/auth/authorize';
      case 'tumblr':
        return 'https://www.tumblr.com/oauth2/authorize';
      case 'youtube':
        return 'https://accounts.google.com/o/oauth2/v2/auth'; // Uses Google OAuth
      case 'pinterest':
        return 'https://www.pinterest.com/oauth';
      case 'arena':
      case 'are.na':
        return 'https://www.are.na/oauth/authorize';
      case 'linkedin':
        return 'https://www.linkedin.com/oauth/v2/authorization';
      default:
        // For generic OAuth (Uber Eats, Lyft, Airbnb, etc.)
        // Return null to indicate custom discovery URL needed
        return '';
    }
  }

  /// Get OAuth token exchange URL for a platform
  static String getTokenExchangeUrl(String platform) {
    switch (platform.toLowerCase()) {
      case 'google':
        return 'https://oauth2.googleapis.com/token';
      case 'instagram':
        return 'https://api.instagram.com/oauth/access_token';
      case 'facebook':
        return 'https://graph.facebook.com/v18.0/oauth/access_token';
      case 'twitter':
        return 'https://api.twitter.com/2/oauth2/token';
      case 'reddit':
        return 'https://www.reddit.com/api/v1/access_token';
      case 'tiktok':
        return 'https://open.tiktokapis.com/v2/oauth/token';
      case 'tumblr':
        return 'https://api.tumblr.com/v2/oauth2/token';
      case 'youtube':
        return 'https://oauth2.googleapis.com/token'; // Uses Google OAuth
      case 'pinterest':
        return 'https://api.pinterest.com/v5/oauth/token';
      case 'arena':
      case 'are.na':
        return 'https://www.are.na/oauth/token';
      case 'linkedin':
        return 'https://www.linkedin.com/oauth/v2/accessToken';
      default:
        // For generic OAuth, return empty string
        // Caller should provide custom token URL
        return '';
    }
  }

  /// Get default scopes for a platform
  static List<String> getDefaultScopes(String platform) {
    switch (platform.toLowerCase()) {
      case 'google':
        return googleScopes;
      case 'instagram':
        return instagramScopes;
      case 'facebook':
        return facebookScopes;
      case 'twitter':
        return twitterScopes;
      case 'reddit':
        return redditScopes;
      case 'tiktok':
        return tiktokScopes;
      case 'tumblr':
        return tumblrScopes;
      case 'youtube':
        return googleScopes; // Uses Google scopes
      case 'pinterest':
        return pinterestScopes;
      case 'arena':
      case 'are.na':
        return arenaScopes;
      case 'linkedin':
        return linkedinScopes;
      default:
        // Default scopes for generic OAuth
        return ['openid', 'profile', 'email'];
    }
  }
}
