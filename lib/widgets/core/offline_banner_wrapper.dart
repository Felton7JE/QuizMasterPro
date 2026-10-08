import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/core/network_provider.dart';

class OfflineBannerWrapper extends StatefulWidget {
  final Widget child;

  const OfflineBannerWrapper({super.key, required this.child});

  @override
  State<OfflineBannerWrapper> createState() => _OfflineBannerWrapperState();
}

class _OfflineBannerWrapperState extends State<OfflineBannerWrapper> {
  bool _wasOffline = false;
  bool _showReconnectedBanner = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, network, child) {
        if (network.isOffline) {
          _wasOffline = true;
          _showReconnectedBanner = false;
        } else if (_wasOffline && !network.isOffline) {
          // Triggers the green "reconnected" banner temporarily
          _wasOffline = false;
          _showReconnectedBanner = true;
          
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showReconnectedBanner = false;
              });
            }
          });
        }

        return Stack(
          children: [
            widget.child,
            
            // Offline Banner
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: network.isOffline ? 0 : -50,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: 40,
                  color: Colors.redAccent,
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Sem ligação à internet (Modo Offline)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Reconnected Banner
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showReconnectedBanner ? 0 : -50,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: 40,
                  color: Colors.green,
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Ligação restabelecida',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
