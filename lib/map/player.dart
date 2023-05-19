import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum PlayerTyp { seeker, agent, agentAlways }

class Player {
  Map<DateTime, LatLng> points;
  Color color;
  PlayerTyp playerType;
  bool polyline;
  final double _markerSize = 32;
  String name;
  DateTime? gameTime;

  Player(
      {required this.points,
      required this.color,
      required this.name,
      this.playerType = PlayerTyp.seeker,
      this.polyline = true});

  List<LatLng> getPointsAfterDate(DateTime dateTime) {
    return [
      for (MapEntry<DateTime, LatLng> point in points.entries)
        if (!point.key.isAfter(dateTime)) point.value
    ];
  }

  Widget getSeekerWithColor(Color color, double size) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcATop),
          child: Image.asset(
            'assets/image/agenty_seeker_s.png',
            height: size,
            width: size,
          ),
        ),
        Image.asset(
          'assets/image/agenty_seeker_no_s.png',
          height: size,
          width: size,
        ),
      ],
    );
  }

  Marker getPlayerMarker(LatLng point) {
    return createMarker(
        point,
        playerType == PlayerTyp.agent
            ? Image.asset(
                'assets/image/agenty.png',
                height: _markerSize,
                width: _markerSize,
              )
            : getSeekerWithColor(color, _markerSize),
        name);
  }

  ///Return a marker for flutter map.
  Marker createMarker(LatLng point, Widget icon, String name,
      {double rotation = 0.0, Color? textColor}) {
    return Marker(
        width: 80.0,
        height: 80.0,
        point: point,
        builder: (_) => RotationTransition(
              turns: AlwaysStoppedAnimation(rotation / 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  icon,
                  Text(
                    name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: textColor),
                  )
                ],
              ),
            ));
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    Player player = Player(points: {
      for (Map<String, dynamic> jsonPoints in json['points'])
        DateTime.fromMillisecondsSinceEpoch(int.parse(jsonPoints['date_time'])):
            LatLng(jsonPoints['lat'], jsonPoints['lng'])
    }, color: Color(int.parse(json['color'])), name: json['name']);
    if (json.keys.contains('player_type')) {
      player.playerType = json['player_type'] == 'agentAlways'
          ? PlayerTyp.agentAlways
          : (json['player_type'] == 'agent'
              ? PlayerTyp.agent
              : PlayerTyp.seeker);
      player.polyline = player.playerType != PlayerTyp.agent;
      if(player.playerType==PlayerTyp.agent){
        player.name+=' (game)';
      }
    }
    return player;
  }
}

class PolylineMarker {
  Polyline? polyline;
  Marker? marker;

  PolylineMarker(DateTime gameTime, Player player) {
    List<LatLng> points = player.getPointsAfterDate(gameTime);
    if (points.isEmpty) return;
    if (player.polyline) {
      polyline = Polyline(
          points: points,
          borderStrokeWidth: 0,
          strokeWidth: 10,
          color: player.color);
    }
    marker = player.getPlayerMarker(points.last);
  }
}

class Players {
  final List<Player> players;

  Players({this.players = const []});

  List<PolylineMarker> getPolylinesAndMarker(DateTime gameTime) {
    return [for (Player player in players) PolylineMarker(gameTime, player)];
  }

  factory Players.fromJson(List<dynamic> jsonPlayers) {
    Players players = Players(players: [
      for (Map<String, dynamic> jsonPlayer in jsonPlayers)
        Player.fromJson(jsonPlayer)
    ]);
    return players;
  }
}

/*
[{
"points":[{"dateTime":{dateTimeAsMilliSeconds}, "lat":54, "lng":54, "color":{hex}, "name":Test}], ?"polyline":true, ?"player_type":{seeker, agent, agentAlways}
}]
 */
