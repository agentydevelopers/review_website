import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Coin {
  DateTime startTime;
  DateTime endTime;
  LatLng point;

  Coin({required this.startTime, required this.endTime, required this.point});

  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
        startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
        endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime']),
        point: LatLng(json['position']['lat'], json['position']['lng']));
  }
}

class Coins {
  final List<Coin> coins;

  Coins({this.coins = const []});

  List<Marker> setState(DateTime gameTime) {
    return [
      for (Coin coin in coins)
        if (gameTime.isBefore(coin.endTime) &&
            !gameTime.isBefore(coin.startTime))
          Marker(
              width: 20.0,
              height: 20.0,
              point: coin.point,
              builder: (_) => Image.asset(
                    'assets/image/agenty_coin.png',
                    width: 24,
                    height: 24,
                  ))
    ];
  }

  factory Coins.fromJson(List<Map<String, dynamic>> jsonCoins) {
    Coins coins = Coins(coins: [
      for (Map<String, dynamic> jsonCoin in jsonCoins) Coin.fromJson(jsonCoin)
    ]);
    return coins;
  }
}

/*
[{"startTime":{dateTimeAsMilliSeconds}, "endTime":{dateTimeAsMilliSeconds}, "position":{"lat":45, "lng":34}]
 */
