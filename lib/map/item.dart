import 'package:flutter/material.dart';

class Item {
  final double _size = 50;
  final DateTime startTime;
  final DateTime endTime;
  late final int _durationInMillisecond;
  final String id;

  Item(this.startTime, this.endTime, this.id) {
    _durationInMillisecond = endTime.difference(startTime).inMilliseconds;
  }

  ///Get item icon from string.
  Image _getIcon() {
    switch (id) {
      case 'alu_hat':
        return Image.asset(
          'assets/items/agenty_alu_hat.png',
          width: _size,
          height: _size,
        );
      case 'coin_magnet':
        return Image.asset(
          'assets/items/agenty_coin_magnet.png',
          width: _size,
          height: _size,
        );
      case 'fake_news':
        return Image.asset(
          'assets/items/agenty_fake_news.png',
          width: _size,
          height: _size,
        );
      case 'hack':
        return Image.asset(
          'assets/items/agenty_hack.png',
          width: _size,
          height: _size,
        );
      case 'jammer':
        return Image.asset(
          'assets/items/agenty_jammer.png',
          width: _size,
          height: _size,
        );
      case 'night':
        return Image.asset(
          'assets/items/agenty_night.png',
          width: _size,
          height: _size,
        );
      case 'radar':
        return Image.asset(
          'assets/items/agenty_radar.png',
          width: _size,
          height: _size,
        );
      case 'repair':
        return Image.asset(
          'assets/items/agenty_repair.png',
          width: _size,
          height: _size,
        );
      case 'repeater':
        return Image.asset(
          'assets/items/agenty_repeater.png',
          width: _size,
          height: _size,
        );
      case 'server_outage':
        return Image.asset(
          'assets/items/agenty_server_outage.png',
          width: _size,
          height: _size,
        );
      case 'smoke_grenade':
        return Image.asset(
          'assets/items/agenty_smoke_grenade.png',
          width: _size,
          height: _size,
        );
      case 'trojan_horse':
        return Image.asset(
          'assets/items/agenty_trojan_horse.png',
          width: _size,
          height: _size,
        );
      case 'confusion':
        return Image.asset(
          'assets/items/agenty_confusion.png',
          width: _size,
          height: _size,
        );
      default:
        return Image.asset(
          'assets/image/agenty.png',
          width: _size,
          height: _size,
        );
    }
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(DateTime.fromMillisecondsSinceEpoch(json['startTime']),
        DateTime.fromMillisecondsSinceEpoch(json['endTime']), json['id']);
  }
}

class Items {
  final List<Item> items;

  Items({this.items = const []});

  List<Widget> setState(DateTime gameTime, BuildContext context) {
    return [
      for (Item item in items)
        if (gameTime.isBefore(item.endTime) &&
            !gameTime.isBefore(item.startTime))
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              item._getIcon(),
              SizedBox(
                  height: 5.0,
                  width: 48.0,
                  child: LinearProgressIndicator(
                      value: item.endTime.difference(gameTime).inMilliseconds /
                          item._durationInMillisecond,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).backgroundColor)))
            ],
          )
    ];
  }

  factory Items.fromJson(List<dynamic> jsonItems) {
    return Items(items: [
      for (Map<String, dynamic> jsonItem in jsonItems) Item.fromJson(jsonItem)
    ]);
  }
}

class ItemListDisplay extends StatelessWidget {
  final List<Widget> items;

  const ItemListDisplay({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: const EdgeInsets.only(
            top: 10.0, bottom: 10.0, left: 10.0, right: 10.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            children: [
              Row(
                children: items,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
[{"startTime":{dateTimeAsMilliSeconds}, "endTime":{dateTimeAsMilliSeconds}, "id"={itemId}}]
 */
