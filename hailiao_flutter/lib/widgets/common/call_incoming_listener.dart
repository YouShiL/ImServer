import 'package:flutter/material.dart';
import 'package:hailiao_flutter/screens/incoming_call_screen.dart';
import 'package:hailiao_flutter/services/call_signal_bridge.dart';

class CallIncomingListener extends StatefulWidget {
  const CallIncomingListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<CallIncomingListener> createState() => _CallIncomingListenerState();
}

class _CallIncomingListenerState extends State<CallIncomingListener> {
  final CallSignalBridge _bridge = CallSignalBridge.instance;
  bool _isPresenting = false;

  @override
  void initState() {
    super.initState();
    _bridge.addListener(_handleIncomingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _presentIncomingIfNeeded();
    });
  }

  @override
  void dispose() {
    _bridge.removeListener(_handleIncomingChanged);
    super.dispose();
  }

  void _handleIncomingChanged() {
    if (!mounted || _isPresenting) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _presentIncomingIfNeeded();
    });
  }

  Future<void> _presentIncomingIfNeeded() async {
    if (!mounted || _isPresenting) {
      return;
    }
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return;
    }
    final CallSignalPayload? payload = _bridge.takePendingIncoming();
    if (payload == null) {
      return;
    }

    _isPresenting = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IncomingCallScreen(payload: payload),
      ),
    );
    if (mounted) {
      _isPresenting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
