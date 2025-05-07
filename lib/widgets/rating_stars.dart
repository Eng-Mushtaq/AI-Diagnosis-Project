import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final Color emptyColor;
  final bool allowHalfStar;
  final bool editable;
  final Function(double)? onRatingChanged;

  const RatingStars({
    Key? key,
    required this.rating,
    this.size = 24.0,
    this.color = Colors.amber,
    this.emptyColor = Colors.grey,
    this.allowHalfStar = true,
    this.editable = false,
    this.onRatingChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (editable) {
          return GestureDetector(
            onTap: () {
              if (onRatingChanged != null) {
                onRatingChanged!(index + 1.0);
              }
            },
            child: _buildStar(index),
          );
        } else {
          return _buildStar(index);
        }
      }),
    );
  }

  Widget _buildStar(int index) {
    IconData iconData;
    Color starColor;

    if (index < rating.floor()) {
      // Full star
      iconData = Icons.star;
      starColor = color;
    } else if (index == rating.floor() && allowHalfStar && rating % 1 > 0) {
      // Half star
      iconData = Icons.star_half;
      starColor = color;
    } else {
      // Empty star
      iconData = Icons.star_border;
      starColor = emptyColor;
    }

    return Icon(
      iconData,
      color: starColor,
      size: size,
    );
  }
}
