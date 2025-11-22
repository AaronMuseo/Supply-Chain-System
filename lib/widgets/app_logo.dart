import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/logo.png', height: 80);
  }
}
class Dealer {
  final String id;
  final String name;
  final String street;
  final String city;
  final String state;
  final String zip;
  final String contactName;
  final String contactPhone;
  final double longitude;
  final double latitude;
  final List<double> demandHistory;
  final double maintenanceCost;

  Dealer({
    required this.id,
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.contactName,
    required this.contactPhone,
    required this.longitude,
    required this.latitude,
    required this.demandHistory,
    required this.maintenanceCost,
  });

  factory Dealer.fromMap(Map<String, dynamic> map, String id) => Dealer(
    id: id,
    name: map['name'],
    street: map['street'],
    city: map['city'],
    state: map['state'],
    zip: map['zip'],
    contactName: map['contactName'],
    contactPhone: map['contactPhone'],
    longitude: map['longitude'],
    latitude: map['latitude'],
    demandHistory: List<double>.from(map['demandHistory'] ?? []),
    maintenanceCost: map['maintenanceCost'],
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'street': street,
    'city': city,
    'state': state,
    'zip': zip,
    'contactName': contactName,
    'contactPhone': contactPhone,
    'longitude': longitude,
    'latitude': latitude,
    'demandHistory': demandHistory,
    'maintenanceCost': maintenanceCost,
  };
}

