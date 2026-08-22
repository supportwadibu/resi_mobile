import 'package:flutter/material.dart';

class BookingInfoCard extends StatelessWidget {
  final String residence;
  final String checkIn;
  final String checkOut;

  const BookingInfoCard({
    super.key,
    required this.residence,
    required this.checkIn,
    required this.checkOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF4F4F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            residence,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 14),

          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              children: [
                const TextSpan(text: 'Date d\'arrivée : '),
                TextSpan(
                  text: checkIn,
                  style: const TextStyle(
                    color: Color(0xff252B5C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              children: [
                const TextSpan(text: 'Fin prévue : '),
                TextSpan(
                  text: checkOut,
                  style: const TextStyle(
                    color: Color(0xff252B5C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}