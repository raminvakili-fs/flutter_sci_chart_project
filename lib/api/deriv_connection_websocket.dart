library wsapi;

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'subscription_stream.dart';

class BinaryAPI {
  /// A key to check the `onDone` function is called from the same instance.
  final UniqueKey uniqueKey;

  /// Indicates current connection status - only set `true` once
  /// we have established SSL *and* websocket handshake steps
  bool connected = false;

  /// Represents the active websocket connection
  WebSocket chan;

  StreamSubscription wsListener;

  /// Tracks our internal counter for requests, always increments until the connection is closed
  int lastRequestId = 0;

  /// Any requests that are currently in-flight
  Map<int, PendingRequest<Map<String, dynamic>>> pendingRequests = {};

  /// The brand name
  String brand = 'deriv';

  BinaryAPI({this.uniqueKey});

  /// Calls the websocket API with the given method name and parameters.
  Future<dynamic> call(final String method, {Map<String, dynamic> req}) {
    if (req == null) {
      req = <String, dynamic>{};
    }

    // Trims the req since the api serialization doesn't work properly.
    req.removeWhere((key, value) => value == null);

    // Allow caller to specify their own request ID
    req.putIfAbsent('req_id', nextRequestId);
    // Some methods pass a specific value for the method name, e.g. ticks => 'frxUSDJPY'
    req.putIfAbsent(method, () => 1);

    final f = Completer<Map<String, dynamic>>();
    pendingRequests[req['req_id']] =
        PendingRequest(method: method, request: req, response: f);

    dev.log('Queuing outgoing request', error: jsonEncode(req));

    final List<int> data = utf8.encode(jsonEncode(req));
    chan.add(data);
    return f.future;
  }

  Future<void> close() async {
    // The onDone function of the listener is set to null intentionally to prevent it from being invoke after destroying the websocket object.
    wsListener.onDone(null);
    wsListener.onError(null);

    await wsListener.cancel();

    if (connected) {
      await chan.close();
    }
    wsListener = null;
    chan = null;
  }

  void dispose() {
    // connWatcher.cancel();
  }

  void handleResponse(
      Completer<bool> connectionCompleter, Map<String, dynamic> msg) {
    try {
      final Map<String, dynamic> m = Map<String, dynamic>.from(msg);
      if (!connected) {
        dev.log('WS is connected');
        connected = true;
        connectionCompleter.complete(true);
      }

      dev.log('Check for req_id in received message');
      if (m.containsKey('req_id')) {
        final int reqId = m['req_id'];
        if (pendingRequests.containsKey(reqId)) {
          final Completer c = pendingRequests[reqId].response;

          if (!c.isCompleted) {
            c.complete(m);
          }

          // Checks if the request was a subscription or not.
          if (pendingRequests[reqId].streamController != null) {
            // Adds the subscription id to the pendingRequest object for further references.
            if (m.containsKey('subscription')) {
              pendingRequests[reqId].subscriptionId = m['subscription']['id'];
            }

            // Broadcasts the new message into the stream.
            pendingRequests[reqId].streamController.add(m);
          } else {
            // Removes the pendingRequest when it's not a subscription, the subscription requests will be remove after unsubscribing.
            pendingRequests.remove(reqId);
          }

          dev.log('Completed request');
        } else {
          dev.log(
              'This has a request ID, but does not match anything in our pending queue');
        }
      } else {
        dev.log('No req_id, ignoring');
      }
    } catch (e) {
      dev.log('Failed to process $msg - $e');
    }
  }

  Future<Map<String, dynamic>> logout() {
    return call('logout');
  }

  int nextRequestId() {
    dev.log('Assigning ID, last was $lastRequestId');
    return ++lastRequestId;
  }

  Future<WebSocket> run({
    String endpoint = 'ws.binaryws.com',
    String appID = '1089',
    String language = 'en',
    String brand = 'binary',
    void onDone(UniqueKey uniqueKey),
    void onOpen(UniqueKey uniqueKey),
  }) async {
    connected = false;

    Uri u = Uri(
      scheme: "wss",
      host: endpoint,
      path: "/websockets/v3",
      queryParameters: {
        // The Uri.queryParameters only accept Map<String, dynamic/*String|Iterable<String>*/>
        'app_id': appID,
        'l': language,
        'brand': brand,
      },
    );

    dev.log('Connecting to $u');
    dev.log('Connecting to $u');

    Completer<bool> c = Completer<bool>();

    // initialize ws server
    chan = await  WebSocket.connect(u.toString());

    wsListener = chan // .cast<String>().transform(utf8.decode)
        .map((str) => jsonDecode(str))
        .listen((msg) {
      handleResponse(c, msg);
    }, onError: (error) {
      dev.log('The WS connection is closed: $error');
    }, onDone: () async {
      dev.log('WS is Closed!');
      connected = false;
      if (onDone != null) {
        onDone(this.uniqueKey);
      }
    });

    dev.log('Send initial message');
    call('ping');
    c.future.then((_) {
      dev.log('WS is connected!');
      if (onOpen != null) {
        onOpen(this.uniqueKey);
      }
    });
    return chan;
  }

  Stream<dynamic> subscribe(final String method, {Map<String, dynamic> req}) {
    if (req == null) {
      req = <String, dynamic>{};
    }

    req.putIfAbsent('req_id', nextRequestId);
    req.putIfAbsent('subscribe', () => 1);

    SubscriptionStream<Map<String, dynamic>> subscriptionStream =
        SubscriptionStream();

    call(method, req: req);

    pendingRequests[req['req_id']].streamController = subscriptionStream;

    return subscriptionStream.stream;
  }

  Future<Map<String, dynamic>> time() {
    return call('time');
  }

  Future<Map<String, dynamic>> unsubscribe(String subscriptionId,
      {shouldForced = false}) async {
    if (pendingRequests.keys.length == 0) {
      return null;
    }

    final int reqId = pendingRequests.keys.singleWhere(
      (int id) => pendingRequests[id].subscriptionId == subscriptionId,
      orElse: () => null,
    );

    if (reqId == null) {
      return null;
    }

    final PendingRequest pendingRequest = pendingRequests[reqId];

    if (pendingRequest.streamController.hasListener && !shouldForced) {
      throw Exception('The stream has listener');
    }
    // Send forget request
    final Map<String, dynamic> response =
        await call('forget', req: {'forget': pendingRequest.subscriptionId});

    if (!response.containsKey('error')) {
      // Remove the the request from pending requests
      pendingRequests.remove(reqId);
      pendingRequest.streamController.closeStream();
    }

    return response;
  }

  Future<dynamic> unsubscribeAll(String method, {shouldForced = false}) async {
    final reqIds = pendingRequests.keys.where((int id) =>
        pendingRequests[id].method == method &&
        pendingRequests[id].isSubscribed);

    final Map<String, dynamic> response =
        await call('forget_all', req: {'forget_all': method});

    if (!response.containsKey('error')) {
      reqIds.forEach((id) async {
        await pendingRequests[id].streamController.closeStream();
      });
      pendingRequests.removeWhere((id, pendingRequest) => reqIds.contains(id));
    }

    return response;
  }
}
/// Represent a pendinag request.
class PendingRequest<T> {
  final String method;
  final Map<String, dynamic> request;
  final Completer<T> response;
  SubscriptionStream<T> _streamController;
  String _subscriptionId;

  PendingRequest({this.method, this.request, this.response});

  bool get isSubscribed => _streamController != null;

  SubscriptionStream get streamController => _streamController;

  set streamController(value) => _streamController = value;

  String get subscriptionId => _subscriptionId;

  set subscriptionId(value) => _subscriptionId = value;
}
