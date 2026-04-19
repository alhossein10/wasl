import 'package:flutter/material.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/date_time_extension.dart';

class SearchFooter extends StatelessWidget {
  final DateTime? searchedUntil;
  final bool endReached, isLoading;
  final void Function() onStartSearch;

  const SearchFooter({
    super.key,
    required this.searchedUntil,
    required this.endReached,
    required this.isLoading,
    required this.onStartSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (endReached) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              L10n.of(context).noMoreResultsFound,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    final searchedUntil = this.searchedUntil;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: Column(
          mainAxisSize: .min,
          children: [
            if (searchedUntil != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  L10n.of(
                    context,
                  ).chatSearchedUntil(searchedUntil.localizedTime(context)),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: isLoading ? null : onStartSearch,
              icon: isLoading
                  ? SizedBox.square(
                      dimension: 18,
                      child: const CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.arrow_downward_outlined),
              label: Text(L10n.of(context).searchMore),
            ),
          ],
        ),
      ),
    );
  }
}
