/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - network_info.dart
/// ═══════════════════════════════════════════════════════════════
/// 
/// PURPOSE: Network connectivity checker
/// 
/// USAGE:
/// - Check connectivity before API calls
/// - Show offline banner when disconnected
/// - Handle offline-to-online transitions
/// 
/// OFFLINE STRATEGY:
/// - Game cannot start offline (needs fresh cases)
/// - Leaderboard shows cached data with "Çevrimdışı" badge
/// - Profile shows cached data
/// - Score syncs when back online
/// 
/// EXAMPLE:
/// ```dart
/// abstract class NetworkInfo {
///   Future<bool> get isConnected;
///   Stream<bool> get onConnectivityChanged;
/// }
/// 
/// class NetworkInfoImpl implements NetworkInfo {
///   final Connectivity _connectivity;
///   
///   NetworkInfoImpl(this._connectivity);
///   
///   @override
///   Future<bool> get isConnected async {
///     final result = await _connectivity.checkConnectivity();
///     return result != ConnectivityResult.none;
///   }
///   
///   @override
///   Stream<bool> get onConnectivityChanged {
///     return _connectivity.onConnectivityChanged.map(
///       (result) => result != ConnectivityResult.none,
///     );
///   }
/// }
/// ```

// TODO: Implement NetworkInfo
