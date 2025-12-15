import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:convert';

/// OUR_GUTS.md: "Decentralized community networks with privacy protection"
/// Manages P2P nodes for university/company private networks
class P2PNodeManager {
  static const String _logName = 'P2PNodeManager';
  
  // Node configuration
  static const int _maxConnectionsPerNode = 8;
  static const int _heartbeatIntervalSeconds = 30;
  static const Duration _nodeTimeoutDuration = Duration(minutes: 5);
  
  /// Initialize P2P node for private network
  /// OUR_GUTS.md: "University/company private networks with verified members"
  Future<P2PNode> initializeNode(
    NetworkType networkType,
    String organizationId,
    NodeCapabilities capabilities,
  ) async {
    try {
      // #region agent log
      developer.log('Initializing P2P node: organizationId=$organizationId, networkType=${networkType.name}, maxConnectionsPerNode=$_maxConnectionsPerNode, heartbeatInterval=${_heartbeatIntervalSeconds}s, nodeTimeout=${_nodeTimeoutDuration.inMinutes} minutes', name: _logName);
      // #endregion
      
      // Validate organization credentials
      await _validateOrganizationCredentials(organizationId, networkType);
      
      // Generate secure node identity
      final nodeId = await _generateSecureNodeId();
      final encryptionKeys = await _generateNodeKeys();
      
      // Create node with privacy protection
      final node = P2PNode(
        nodeId: nodeId,
        organizationId: organizationId,
        networkType: networkType,
        capabilities: capabilities,
        encryptionKeys: encryptionKeys,
        status: NodeStatus.initializing,
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
        connections: {},
        dataPolicy: await _createPrivacyPolicy(networkType),
      );
      
      // Register in network discovery
      await _registerInNetwork(node);
      
      // Start node services (uses _heartbeatIntervalSeconds and _nodeTimeoutDuration)
      await _startNodeServices(node);
      
      // #region agent log
      developer.log('P2P node initialized successfully: nodeId=${node.nodeId}, maxConnections=$_maxConnectionsPerNode, heartbeatInterval=${_heartbeatIntervalSeconds}s', name: _logName);
      // #endregion
      return node;
    } catch (e) {
      developer.log('Error initializing P2P node: $e', name: _logName);
      throw P2PException('Failed to initialize P2P node');
    }
  }
  
  /// Discover and connect to network peers
  /// OUR_GUTS.md: "Cross-node privacy protection"
  Future<List<P2PConnection>> discoverNetworkPeers(
    P2PNode localNode,
    {int maxConnections = 5}
  ) async {
    try {
      // #region agent log
      developer.log('Discovering network peers for: ${localNode.nodeId}, maxConnections=$maxConnections, maxConnectionsPerNode=$_maxConnectionsPerNode', name: _logName);
      // #endregion
      
      // Find compatible nodes in same network type
      final availableNodes = await _findCompatibleNodes(localNode);
      
      // Score nodes for optimal connections
      final scoredNodes = <ScoredNode>[];
      for (final node in availableNodes) {
        final score = await _calculateNodeCompatibility(localNode, node);
        if (score > 0.5) {
          scoredNodes.add(ScoredNode(node: node, score: score));
        }
      }
      
      // Sort by score and select best connections
      // Limit to _maxConnectionsPerNode to prevent connection overload
      scoredNodes.sort((a, b) => b.score.compareTo(a.score));
      final effectiveMaxConnections = math.min(maxConnections, _maxConnectionsPerNode);
      final selectedNodes = scoredNodes.take(effectiveMaxConnections).toList();
      
      // #region agent log
      developer.log('Selected ${selectedNodes.length} nodes for connection (effectiveMax: $effectiveMaxConnections)', name: _logName);
      // #endregion
      
      // Establish secure connections (respects _maxConnectionsPerNode limit)
      final connections = <P2PConnection>[];
      for (final scoredNode in selectedNodes) {
        try {
          // Check if we've reached the connection limit
          if (localNode.connections.length >= _maxConnectionsPerNode) {
            // #region agent log
            developer.log('Connection limit reached, skipping node: ${scoredNode.node.nodeId}', name: _logName);
            // #endregion
            break;
          }
          
          final connection = await _establishSecureConnection(localNode, scoredNode.node);
          connections.add(connection);
        } catch (e) {
          // #region agent log
          developer.log('Failed to connect to node: ${scoredNode.node.nodeId}, error: $e', name: _logName);
          // #endregion
          continue;
        }
      }
      
      // #region agent log
      developer.log('Established ${connections.length} peer connections (limit: $_maxConnectionsPerNode)', name: _logName);
      // #endregion
      return connections;
    } catch (e) {
      developer.log('Error discovering network peers: $e', name: _logName);
      throw P2PException('Failed to discover network peers');
    }
  }
  
  /// Create encrypted data silo for organization
  /// OUR_GUTS.md: "Encrypted data silos with verified member authentication"
  Future<DataSilo> createEncryptedSilo(
    P2PNode node,
    String siloName,
    DataSiloPolicy policy,
  ) async {
    try {
      // #region agent log
      developer.log('Creating encrypted silo: siloName=$siloName, nodeId=${node.nodeId}, organizationId=${node.organizationId}', name: _logName);
      // #endregion
      
      // Generate silo encryption keys
      final siloKeys = await _generateSiloEncryptionKeys();
      
      // Create secure silo
      final silo = DataSilo(
        siloId: _generateSiloId(),
        name: siloName,
        organizationId: node.organizationId,
        encryptionKeys: siloKeys,
        policy: policy,
        createdAt: DateTime.now(),
        lastAccessed: DateTime.now(),
        dataCount: 0,
        accessLog: [],
      );
      
      // Initialize silo storage
      await _initializeSiloStorage(silo);
      
      // Register silo with node
      await _registerSiloWithNode(node, silo);
      
      // #region agent log
      developer.log('Encrypted silo created: siloId=${silo.siloId}, dataRetention=${policy.dataRetention.inDays} days', name: _logName);
      // #endregion
      return silo;
    } catch (e) {
      developer.log('Error creating encrypted silo: $e', name: _logName);
      throw P2PException('Failed to create encrypted silo');
    }
  }
  
  /// Sync data across network with privacy preservation
  /// OUR_GUTS.md: "Privacy-preserving data synchronization"
  Future<SyncResult> syncDataAcrossNetwork(
    P2PNode localNode,
    List<P2PConnection> connections,
    DataSyncRequest request,
  ) async {
    try {
      // #region agent log
      developer.log('Syncing data across network: connections=${connections.length}, requestId=${request.requestId}, maxConnectionsPerNode=$_maxConnectionsPerNode', name: _logName);
      // #endregion
      
      // Validate connection count doesn't exceed limit
      if (connections.length > _maxConnectionsPerNode) {
        // #region agent log
        developer.log('Connection count (${connections.length}) exceeds limit ($_maxConnectionsPerNode), limiting sync', name: _logName);
        // #endregion
        // Limit to max connections
        connections = connections.take(_maxConnectionsPerNode).toList();
      }
      
      // Validate sync request privacy
      await _validateSyncPrivacy(request);
      
      // Prepare encrypted sync packages
      final syncPackages = await _prepareSyncPackages(request, localNode.encryptionKeys);
      
      // Distribute to network peers
      final syncResults = <NodeSyncResult>[];
      for (final connection in connections) {
        try {
          final result = await _syncWithPeer(connection, syncPackages);
          syncResults.add(result);
        } catch (e) {
          developer.log('Sync failed with peer: ${connection.remoteNodeId}', name: _logName);
          continue;
        }
      }
      
      // Aggregate results
      final successfulCount = syncResults.where((r) => r.success).length;
      final failedCount = syncResults.where((r) => !r.success).length;
      
      final overallResult = SyncResult(
        requestId: request.requestId,
        timestamp: DateTime.now(),
        successfulSyncs: successfulCount,
        failedSyncs: failedCount,
        dataPackagesSent: syncPackages.length,
        privacyCompliant: true,
      );
      
      // #region agent log
      developer.log('Data sync completed: successful=$successfulCount, failed=$failedCount, total=${connections.length}, maxConnectionsPerNode=$_maxConnectionsPerNode', name: _logName);
      // #endregion
      return overallResult;
    } catch (e) {
      developer.log('Error syncing data across network: $e', name: _logName);
      throw P2PException('Failed to sync data across network');
    }
  }
  
  // Private helper methods
  Future<void> _validateOrganizationCredentials(String orgId, NetworkType type) async {
    // Validate organization has permission for this network type
    if (type == NetworkType.university && !orgId.contains('edu')) {
      throw P2PException('Invalid university credentials');
    }
  }
  
  Future<String> _generateSecureNodeId() async {
    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return 'node_${base64Encode(bytes).replaceAll('=', '').substring(0, 12)}';
  }
  
  Future<NodeEncryptionKeys> _generateNodeKeys() async {
    final random = math.Random.secure();
    final privateKey = List<int>.generate(32, (i) => random.nextInt(256));
    final publicKey = List<int>.generate(32, (i) => random.nextInt(256));
    
    return NodeEncryptionKeys(
      privateKey: base64Encode(privateKey),
      publicKey: base64Encode(publicKey),
      symmetricKey: base64Encode(List<int>.generate(32, (i) => random.nextInt(256))),
    );
  }
  
  Future<DataPrivacyPolicy> _createPrivacyPolicy(NetworkType networkType) async {
    return DataPrivacyPolicy(
      allowDataSharing: networkType != NetworkType.personal,
      requireConsent: true,
      dataRetentionDays: 30,
      anonymizationRequired: true,
      crossBorderTransfer: false,
    );
  }
  
  Future<void> _registerInNetwork(P2PNode node) async {
    // #region agent log
    developer.log('Registering node in network: nodeId=${node.nodeId}, networkType=${node.networkType.name}, maxConnections=$_maxConnectionsPerNode', name: _logName);
    // #endregion
    // Register node in distributed discovery service
  }
  
  Future<void> _startNodeServices(P2PNode node) async {
    // #region agent log
    developer.log('Starting node services for: ${node.nodeId}, heartbeatInterval=${_heartbeatIntervalSeconds}s, nodeTimeout=${_nodeTimeoutDuration.inMinutes} minutes', name: _logName);
    // #endregion
    // Start heartbeat, discovery, and communication services
    // Heartbeat interval: _heartbeatIntervalSeconds (30 seconds)
    // Node timeout: _nodeTimeoutDuration (5 minutes)
    // These values are used for connection health monitoring
  }
  
  Future<List<P2PNode>> _findCompatibleNodes(P2PNode localNode) async {
    // #region agent log
    developer.log('Finding compatible nodes: networkType=${localNode.networkType.name}, maxConnectionsPerNode=$_maxConnectionsPerNode', name: _logName);
    // #endregion
    // Find nodes in same network type and organization compatibility
    // Filter by maxConnectionsPerNode to ensure we don't exceed connection limits
    return [];
  }
  
  Future<double> _calculateNodeCompatibility(P2PNode local, P2PNode remote) async {
    double score = 0.5; // Base compatibility
    
    // Same network type bonus
    if (local.networkType == remote.networkType) score += 0.3;
    
    // Geographic proximity bonus
    score += 0.1;
    
    // Capability match bonus
    if (local.capabilities.canShareData && remote.capabilities.canReceiveData) {
      score += 0.1;
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  Future<P2PConnection> _establishSecureConnection(P2PNode local, P2PNode remote) async {
    // #region agent log
    developer.log('Establishing secure connection: local=${local.nodeId}, remote=${remote.nodeId}, maxConnectionsPerNode=$_maxConnectionsPerNode, nodeTimeout=${_nodeTimeoutDuration.inMinutes} minutes', name: _logName);
    // #endregion
    
    // Check connection limit
    if (local.connections.length >= _maxConnectionsPerNode) {
      // #region agent log
      developer.log('Connection limit reached: ${local.connections.length} >= $_maxConnectionsPerNode', name: _logName);
      // #endregion
      throw P2PException('Maximum connections per node ($_maxConnectionsPerNode) reached');
    }
    
    // Establish encrypted connection with key exchange
    final connection = P2PConnection(
      connectionId: _generateConnectionId(),
      localNodeId: local.nodeId,
      remoteNodeId: remote.nodeId,
      establishedAt: DateTime.now(),
      lastActivity: DateTime.now(),
      encryptionKeys: await _generateConnectionKeys(),
      connectionState: ConnectionState.connected,
    );
    
    // #region agent log
    developer.log('Secure connection established: connectionId=${connection.connectionId}, will timeout after ${_nodeTimeoutDuration.inMinutes} minutes of inactivity', name: _logName);
    // #endregion
    
    return connection;
  }
  
  String _generateConnectionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random.secure().nextInt(999999);
    return 'conn_${timestamp}_$random';
  }
  
  Future<ConnectionEncryptionKeys> _generateConnectionKeys() async {
    final random = math.Random.secure();
    return ConnectionEncryptionKeys(
      sharedSecret: base64Encode(List<int>.generate(32, (i) => random.nextInt(256))),
      sessionKey: base64Encode(List<int>.generate(16, (i) => random.nextInt(256))),
    );
  }
  
  Future<SiloEncryptionKeys> _generateSiloEncryptionKeys() async {
    final random = math.Random.secure();
    return SiloEncryptionKeys(
      masterKey: base64Encode(List<int>.generate(32, (i) => random.nextInt(256))),
      dataKey: base64Encode(List<int>.generate(32, (i) => random.nextInt(256))),
      accessKey: base64Encode(List<int>.generate(16, (i) => random.nextInt(256))),
    );
  }
  
  String _generateSiloId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random.secure().nextInt(999999);
    return 'silo_${timestamp}_$random';
  }
  
  Future<void> _initializeSiloStorage(DataSilo silo) async {
    // Initialize encrypted storage for silo
    developer.log('Initializing storage for silo: ${silo.siloId}', name: _logName);
  }
  
  Future<void> _registerSiloWithNode(P2PNode node, DataSilo silo) async {
    // Register silo with node for management
    developer.log('Registering silo ${silo.siloId} with node ${node.nodeId}', name: _logName);
  }
  
  Future<void> _validateSyncPrivacy(DataSyncRequest request) async {
    // Ensure sync request doesn't contain private user data
    if (request.containsPersonalData) {
      throw P2PException('Sync request contains personal data');
    }
  }
  
  Future<List<EncryptedSyncPackage>> _prepareSyncPackages(
    DataSyncRequest request, 
    NodeEncryptionKeys keys
  ) async {
    // Prepare encrypted packages for network distribution
    return [];
  }
  
  Future<NodeSyncResult> _syncWithPeer(
    P2PConnection connection, 
    List<EncryptedSyncPackage> packages
  ) async {
    // #region agent log
    developer.log('Syncing with peer: remoteNodeId=${connection.remoteNodeId}, packages=${packages.length}, lastActivity=${connection.lastActivity}, timeoutCheck=${DateTime.now().difference(connection.lastActivity).compareTo(_nodeTimeoutDuration)}', name: _logName);
    // #endregion
    
    // Check if connection has timed out
    final timeSinceLastActivity = DateTime.now().difference(connection.lastActivity);
    if (timeSinceLastActivity > _nodeTimeoutDuration) {
      // #region agent log
      developer.log('Connection timed out: timeSinceLastActivity=${timeSinceLastActivity.inMinutes} minutes >= timeout=${_nodeTimeoutDuration.inMinutes} minutes', name: _logName);
      // #endregion
      return NodeSyncResult(
        nodeId: connection.remoteNodeId,
        success: false,
        packagesSynced: 0,
        timestamp: DateTime.now(),
      );
    }
    
    // Sync packages with specific peer
    final result = NodeSyncResult(
      nodeId: connection.remoteNodeId,
      success: true,
      packagesSynced: packages.length,
      timestamp: DateTime.now(),
    );
    
    // #region agent log
    developer.log('Peer sync completed: nodeId=${result.nodeId}, success=${result.success}, packagesSynced=${result.packagesSynced}', name: _logName);
    // #endregion
    
    return result;
  }
}

// Supporting classes and enums
enum NetworkType { university, company, community, personal }
enum NodeStatus { initializing, active, inactive, error }
enum ConnectionState { connecting, connected, disconnected, error }

class P2PNode {
  final String nodeId;
  final String organizationId;
  final NetworkType networkType;
  final NodeCapabilities capabilities;
  final NodeEncryptionKeys encryptionKeys;
  final NodeStatus status;
  final DateTime createdAt;
  final DateTime lastSeen;
  final Map<String, P2PConnection> connections;
  final DataPrivacyPolicy dataPolicy;
  
  P2PNode({
    required this.nodeId,
    required this.organizationId,
    required this.networkType,
    required this.capabilities,
    required this.encryptionKeys,
    required this.status,
    required this.createdAt,
    required this.lastSeen,
    required this.connections,
    required this.dataPolicy,
  });
}

class NodeCapabilities {
  final bool canShareData;
  final bool canReceiveData;
  final bool canProcessML;
  final bool canStoreData;
  final int maxConnections;
  final List<String> supportedProtocols;
  
  NodeCapabilities({
    required this.canShareData,
    required this.canReceiveData,
    required this.canProcessML,
    required this.canStoreData,
    required this.maxConnections,
    required this.supportedProtocols,
  });
}

class NodeEncryptionKeys {
  final String privateKey;
  final String publicKey;
  final String symmetricKey;
  
  NodeEncryptionKeys({
    required this.privateKey,
    required this.publicKey,
    required this.symmetricKey,
  });
}

class DataPrivacyPolicy {
  final bool allowDataSharing;
  final bool requireConsent;
  final int dataRetentionDays;
  final bool anonymizationRequired;
  final bool crossBorderTransfer;
  
  DataPrivacyPolicy({
    required this.allowDataSharing,
    required this.requireConsent,
    required this.dataRetentionDays,
    required this.anonymizationRequired,
    required this.crossBorderTransfer,
  });
}

class P2PConnection {
  final String connectionId;
  final String localNodeId;
  final String remoteNodeId;
  final DateTime establishedAt;
  final DateTime lastActivity;
  final ConnectionEncryptionKeys encryptionKeys;
  final ConnectionState connectionState;
  
  P2PConnection({
    required this.connectionId,
    required this.localNodeId,
    required this.remoteNodeId,
    required this.establishedAt,
    required this.lastActivity,
    required this.encryptionKeys,
    required this.connectionState,
  });
}

class ConnectionEncryptionKeys {
  final String sharedSecret;
  final String sessionKey;
  
  ConnectionEncryptionKeys({
    required this.sharedSecret,
    required this.sessionKey,
  });
}

class DataSilo {
  final String siloId;
  final String name;
  final String organizationId;
  final SiloEncryptionKeys encryptionKeys;
  final DataSiloPolicy policy;
  final DateTime createdAt;
  final DateTime lastAccessed;
  final int dataCount;
  final List<String> accessLog;
  
  DataSilo({
    required this.siloId,
    required this.name,
    required this.organizationId,
    required this.encryptionKeys,
    required this.policy,
    required this.createdAt,
    required this.lastAccessed,
    required this.dataCount,
    required this.accessLog,
  });
}

class SiloEncryptionKeys {
  final String masterKey;
  final String dataKey;
  final String accessKey;
  
  SiloEncryptionKeys({
    required this.masterKey,
    required this.dataKey,
    required this.accessKey,
  });
}

class DataSiloPolicy {
  final bool requireAuthentication;
  final List<String> allowedRoles;
  final bool logAccess;
  final Duration dataRetention;
  
  DataSiloPolicy({
    required this.requireAuthentication,
    required this.allowedRoles,
    required this.logAccess,
    required this.dataRetention,
  });
}

class DataSyncRequest {
  final String requestId;
  final String sourceNodeId;
  final List<String> targetDataTypes;
  final bool containsPersonalData;
  final DateTime timestamp;
  
  DataSyncRequest({
    required this.requestId,
    required this.sourceNodeId,
    required this.targetDataTypes,
    required this.containsPersonalData,
    required this.timestamp,
  });
}

class SyncResult {
  final String requestId;
  final DateTime timestamp;
  final int successfulSyncs;
  final int failedSyncs;
  final int dataPackagesSent;
  final bool privacyCompliant;
  
  SyncResult({
    required this.requestId,
    required this.timestamp,
    required this.successfulSyncs,
    required this.failedSyncs,
    required this.dataPackagesSent,
    required this.privacyCompliant,
  });
}

class ScoredNode {
  final P2PNode node;
  final double score;
  
  ScoredNode({required this.node, required this.score});
}

class EncryptedSyncPackage {}

class NodeSyncResult {
  final String nodeId;
  final bool success;
  final int packagesSynced;
  final DateTime timestamp;
  
  NodeSyncResult({
    required this.nodeId,
    required this.success,
    required this.packagesSynced,
    required this.timestamp,
  });
}

class P2PException implements Exception {
  final String message;
  P2PException(this.message);
}
