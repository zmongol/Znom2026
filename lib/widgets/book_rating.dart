import 'package:book_app/consttants.dart';
import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class BookRating extends StatelessWidget {
  final double? score;
  const BookRating({
    super.key,
    this.score,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: Offset(3, 7),
            blurRadius: 20,
            color: isDark
                ? Colors.black.withOpacity(.4)
                : Color(0x0fd3d3d3).withOpacity(.5),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.star,
            color: kIconColor,
            size: 15,
          ),
          SizedBox(height: 2),
          MongolText(
            "$score",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white.withOpacity(0.95) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
