import 'package:flutter/material.dart';
import 'package:spots/presentation/widgets/map/map_view.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MapView(
      showAppBar: true,
      appBarTitle: 'Map',
    );
  }
}
