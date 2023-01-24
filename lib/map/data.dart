import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:website/map/player.dart';

import 'package:website/map/smoke_grenade.dart';
import 'coin.dart';
import 'item.dart';

class Data {
  final Players players;
  final Coins coins;
  final Items items;
  final SmokeGrenades smokeGrenades;
  final DateTime startTime;
  final DateTime endTime;
  final LatLng gameArenaCenter;
  final double gameArenaRadius;

  Data(
      {required this.players,
      required this.coins,
      required this.items,
      required this.smokeGrenades,
      required this.startTime,
      required this.endTime,
      required this.gameArenaCenter,
      required this.gameArenaRadius});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
        players: Players.fromJson(json['players']),
        coins: Coins.fromJson(json['coins']),
        items: Items.fromJson(json['items']),
        smokeGrenades: SmokeGrenades.fromJson(json['smokeGrenades']),
        startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
        endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime']),
        gameArenaCenter:
            LatLng(json['arena_center']['lat'], json['arena_center']['lng']),
        gameArenaRadius: json['arena_radius']);
  }

  static Data dummyData() {
    DateTime startTime = DateTime(2023, 1, 18, 17, 51, 0, 0);
    return Data(
        players: Players(players: [
          Player(points: {
            startTime: LatLng(50.097555, 8.670634),
            DateTime(2023, 1, 18, 17, 51, 1, 0): LatLng(50.097695, 8.670508),
            DateTime(2023, 1, 18, 17, 51, 2, 0): LatLng(50.097794, 8.670327),
            DateTime(2023, 1, 18, 17, 51, 3, 0): LatLng(50.099912, 8.667876),
          }, color: Colors.green, name: 'Test'),
          Player(points: {
            startTime: LatLng(50.097555, 8.670634),
            DateTime(2023, 1, 18, 17, 51, 2, 0):
                LatLng(50.098057146339755, 8.671528601741443),
          }, color: Colors.blue, name: 'Ba')
        ]),
        coins: Coins(coins: [
          Coin(
              startTime: startTime,
              endTime: DateTime(2023, 1, 18, 17, 51, 2, 0),
              point: LatLng(50.097794, 8.670327))
        ]),
        items: Items(items: [
          Item(DateTime(2023, 1, 18, 17, 51, 1, 0),
              DateTime(2023, 1, 18, 17, 51, 3, 0), 'smoke_grenade')
        ]),
        smokeGrenades: SmokeGrenades(smokes: [
          SmokeGrenade(
              startTime: DateTime(2023, 1, 18, 17, 51, 1, 0),
              endTime: DateTime(2023, 1, 18, 17, 51, 3, 0),
              point: LatLng(50.097555, 8.670634),
              radius: 40)
        ]),
        startTime: startTime,
        endTime: DateTime(2023, 1, 18, 17, 51, 3, 0),
        gameArenaCenter: LatLng(50.097695, 8.670508),
        gameArenaRadius: 100);
  }

  static Future<Data?> fetchData(String gameId) async {
    //TODO set uri
    try {
      final response = await http.get(
          Uri.parse('http://192.168.178.33:3000/$gameId'),
          headers: {"Accept": "application/json"});

      if (response.statusCode != 200) {
        return null;
      }

      return Data.fromJson(jsonDecode(response.body));
    } catch (e, s) {
      print('Error');
      print(e);
      print(s);
      return null;
    }
  }
}

/*
{
"players":[{"points":[{"dateTime":{dateTimeAsMilliSeconds}, "position":{"lat":54, "lng":54}, "color":{hex}, "name":"Test"}], ?"polyline":true, ?"player_type":{seeker, agent, agentAlways}}],
"coins":[{"startTime":{dateTimeAsMilliSeconds}, "endTime":{dateTimeAsMilliSeconds}, "position":{"lat":45, "lng":34}],
"items": [{"startTime":{dateTimeAsMilliSeconds}, "endTime":{dateTimeAsMilliSeconds}, "id"={itemId}}],
"smokeGrenades":[{"startTime":{dateTimeAsMilliSeconds},"endTime":{dateTimeAsMilliSeconds}, "position":{"lat":5, "lng":45}, "radius":45}],
"startTime":{dateTimeAsMilliSeconds},
"endTime":{dateTimeAsMilliSeconds},
"arena_center":{"lat":54, "lng":54},
"arena_radius":{radius}
}
 */
