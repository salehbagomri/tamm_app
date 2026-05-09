import 'package:flutter/material.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class TammLoading extends StatelessWidget {
  final String? message;
  const TammLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: context.colors.bluePrimary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: TextStyle(color: context.colors.textSecond)),
          ],
        ],
      ),
    );
  }
}
