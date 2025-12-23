import 'package:flutter/material.dart';

class RatingWidget extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final bool readOnly;

  const RatingWidget({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.readOnly = false,
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  void didUpdateWidget(RatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _currentRating = widget.initialRating;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return IconButton(
          iconSize: 32,
          padding: EdgeInsets.zero,
          icon: Icon(
            starIndex <= _currentRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: widget.readOnly
              ? null
              : () {
                  setState(() {
                    _currentRating = starIndex;
                  });
                  widget.onRatingChanged(starIndex);
                },
        );
      }),
    );
  }
}
