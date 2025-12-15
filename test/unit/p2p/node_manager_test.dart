import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/p2p/node_manager.dart';

void main() {
  group('P2PNodeManager', () {
    late P2PNodeManager manager;
    
    setUp(() {
      manager = P2PNodeManager();
    });
    
    test('initializeNode creates secure P2P node', () async {
      // OUR_GUTS.md: "Decentralized community networks with privacy protection"
      final capabilities = NodeCapabilities(
        canShareData: true,
        canReceiveData: true,
        canProcessML: true,
        canStoreData: true,
        maxConnections: 8,
        supportedProtocols: ['secure_sync', 'federated_learning'],
      );
      
      final node = await manager.initializeNode(
        NetworkType.university,
        'test-university.edu',
        capabilities,
      );
      
      expect(node.networkType, equals(NetworkType.university));
      expect(node.organizationId, equals('test-university.edu'));
      expect(node.capabilities.canShareData, isTrue);
      expect(node.encryptionKeys.privateKey, isNotEmpty);
    });
    
    test('createEncryptedSilo maintains data privacy', () async {
      // OUR_GUTS.md: "Encrypted data silos with verified member authentication"
      final node = await manager.initializeNode(
        NetworkType.company,
        'test-company.com',
        NodeCapabilities(
          canShareData: true,
          canReceiveData: true,
          canProcessML: false,
          canStoreData: true,
          maxConnections: 5,
          supportedProtocols: ['data_sync'],
        ),
      );
      
      final policy = DataSiloPolicy(
        requireAuthentication: true,
        allowedRoles: ['member', 'admin'],
        logAccess: true,
        dataRetention: Duration(days: 30),
      );
      
      final silo = await manager.createEncryptedSilo(node, 'test-silo', policy);
      
      expect(silo.name, equals('test-silo'));
      expect(silo.organizationId, equals(node.organizationId));
      expect(silo.encryptionKeys.masterKey, isNotEmpty);
      expect(silo.policy.requireAuthentication, isTrue);
    });
    
    test('discoverNetworkPeers finds compatible nodes', () async {
      // OUR_GUTS.md: "Cross-node privacy protection"
      final node = await manager.initializeNode(
        NetworkType.community,
        'test-community',
        NodeCapabilities(
          canShareData: true,
          canReceiveData: true,
          canProcessML: true,
          canStoreData: false,
          maxConnections: 10,
          supportedProtocols: ['peer_discovery'],
        ),
      );
      
      final connections = await manager.discoverNetworkPeers(node, maxConnections: 3);
      
      expect(connections, isA<List<P2PConnection>>());
      expect(connections.length, lessThanOrEqualTo(3));
    });
  });
}
