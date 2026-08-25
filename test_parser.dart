import 'package:flutter/material.dart';

void main() {
  final slivers = [
    if (true) ...[
      const SliverToBoxAdapter(),
      if (false)
        const SliverToBoxAdapter()
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Container(),
              childCount: 5,
            ),
          ),
        ),
    ]
  ];
}
