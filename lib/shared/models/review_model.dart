import 'package:flutter/material.dart';

class ReviewModel {
  final String id;
  final String name;
  final String initials;
  final String date;
  final int rating;
  final Color avatarColor;
  final Color textColor;
  final String reviewText;
  final int cleanliness;
  final int location;
  final int comfort;
  final int valueForMoney;

  ReviewModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.date,
    required this.rating,
    required this.avatarColor,
    required this.textColor,
    required this.reviewText,
    required this.cleanliness,
    required this.location,
    required this.comfort,
    required this.valueForMoney,
  });
}
