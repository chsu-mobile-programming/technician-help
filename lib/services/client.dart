import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:nearby_connections/nearby_connections.dart';

class NearbyPayload {
  static const String typeTicket = 'ticket';
  static const String typeAnswer = 'answer';

  static Uint8List encode(Map<String, dynamic> json) =>
      Uint8List.fromList(utf8.encode(jsonEncode(json)));

  static Map<String, dynamic>? decode(Uint8List bytes) {
    try {
      return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

class Teacher {
  new({required this.name});

  final String name;
  final Nearby _nearby = Nearby();
  final String _serviceId = 'com.example.nearby_test';

  final Map<String,String> _connectedTechnicians = {};

  bool _isDiscovering = false;

  void Function(String endpointId, String name)? onTechnicianFound;
  void Function(String endpointId)? onTechnicianLost;
  void Function(Map<String, dynamic> answer, String fromEndpointId)? onAnswerRecieved;

  Map<String,String> get connectedTechnicians => Map.unmodifiable(_connectedTechnicians);

  Future<int> sendTicket(Map<String,dynamic> ticket) async {
    //TODO: find all technicians

    final bytes = NearbyPayload.encode({
      ...ticket,
      'type': NearbyPayload.typeTicket,
      'from': name,
    });

    var sent = 0;
    for (final endpointId in _connectedTechnicians.keys.toList()) {
      try {
        await _nearby.sendBytesPayload(endpointId, bytes);
        sent++;
      } catch (e) {
        _connectedTechnicians.remove(endpointId);
      }
    }
    return sent;
    //TODO: store all sent tickets
  }

  Future<void> _requestConnection(String endpointId, String endpointName) async {
    await _nearby.requestConnection(
      name,
      endpointId,
      onConnectionInitiated: (endpointId, conectionInfo) {
        _nearby.acceptConnection(
          endpointId, 
          onPayLoadRecieved: (endpointId, payload) {
            final data = NearbyPayload.decode(payload.bytes!);
            if (data == null) return;
            if (data['type'] == NearbyPayload.typeAnswer) {
              onAnswerRecieved?.call(data, endpointId);
              //TODO: store all recieved answers?
            }
          }
        );
      },
      onConnectionResult: (endpointId, status) {
        if (status == Status.CONNECTED){
          _connectedTechnicians[endpointId] = endpointId;
        } else if (status == Status.REJECTED) {
          _connectedTechnicians.remove(endpointId);
        }
      },
      onDisconnected: (endpointId) {
        _connectedTechnicians.remove(endpointId);
        onTechnicianLost?.call(endpointId);
      });
  }

  Future<bool> start() async {
    if (_isDiscovering) return true;

    //TODO: ensure permissions?

    final ok = await _nearby.startDiscovery(
      name,
      Strategy.P2P_STAR,
      serviceId: _serviceId,
      onEndpointFound: (endpointId, endpointName, serviceId) {
        if (serviceId != _serviceId) return;
        onTechnicianFound?.call(endpointId, endpointName);
        _requestConnection(endpointId, endpointName);
      },
      onEndpointLost: (endpointId) {
        if (endpointId == null) return;
        _connectedTechnicians.remove(endpointId);
        onTechnicianLost?.call(endpointId);
      },
    );

    _isDiscovering = ok;
    return ok;
  }

  Future<void> stop() async {
    _isDiscovering = false;
    await _nearby.stopDiscovery();
    await _nearby.stopAllEndpoints();
    _connectedTechnicians.clear();
  }
}

class Technician {
  new({required this.name});

  final String name;
  final Nearby _nearby = Nearby();
  final String _serviceId = 'com.example.nearby_test';

  bool _isAdvertising = false;

  final Map<String,String> _connectedTeachers = {};
  final List<(Map<String, dynamic> ticket, String endpointId)> _recievedTickets = [];

  void Function(Map<String,dynamic> ticket, String fromEndpointId)? onTicketRecieved;
  void Function(String endPointId)? onTeacherDisconnected;

  Map<String,String> get connectedTeachers => Map.unmodifiable(_connectedTeachers);

  Future<bool> start() async {
    if (_isAdvertising) return true;

    final ok = await _nearby.startAdvertising(
      name, 
      Strategy.P2P_STAR,
      onConnectionInitiated: ((endpointId, connectionInfo) {
        _nearby.acceptConnection(
          endpointId, 
          onPayLoadRecieved: (endpointId, payload) {
            final data = NearbyPayload.decode(payload.bytes!);
            if (data == null) return;
            if (data['type'] == NearbyPayload.typeTicket) {
              _recievedTickets.add((data, endpointId));
              onTicketRecieved?.call(data, endpointId);
            }
          }
        );
      }), 
      onConnectionResult: (endpointId, status) {
        if (status == Status.CONNECTED) {
          _connectedTeachers[endpointId] = connectionName(endpointId);
        }
      }, 
      onDisconnected:(endpointId) {
        _connectedTeachers.remove(endpointId);
        onTeacherDisconnected?.call(endpointId);
      },
      serviceId: _serviceId);

    _isAdvertising = true;
    return ok;
  }

Future<bool> sendAnswer(
    Map<String, dynamic> answer, {
    String? toEndpointId,
  }) async {
    final target = toEndpointId;
    if (target == null || !_connectedTeachers.containsKey(target)) {
      return false;
    }

    final bytes = NearbyPayload.encode({
      ...answer,
      'type': NearbyPayload.typeAnswer,
      'from': name,
    });

    try {
      await _nearby.sendBytesPayload(target, bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  String connectionName(String endpointId) =>
    _connectedTeachers[endpointId] ?? 'teacher';

  Future<void> stop() async {
    _isAdvertising = false;
    await _nearby.stopAdvertising();
    await _nearby.stopAllEndpoints();
    _connectedTeachers.clear();
  }
}