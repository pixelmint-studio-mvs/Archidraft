import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../auth/providers/auth_providers.dart';
import '../../projects/domain/assignment.dart';
import '../../projects/providers/assignment_providers.dart';
import '../domain/app_notification.dart';
import '../providers/notification_providers.dart';
import 'widgets/notification_ui_components.dart';

/// Panel 9 ? Notifications Screen for the Engineer Portal.
///
/// Follows the visual design of the Draughtsman Notifications:
/// - Warm white `#FBF9FB` drafting canvas with 40px grid lines.
/// - Pure white surface cards with subtle borders and dual soft shadows.
/// - Bell icon header with subtitle, "ALL CAUGHT UP" / unread badge, and actions.
/// - Filter chips: All, Unread, Reviews, Remarks.
/// - Categorized notification cards with live server persistence and routing.
/// - Engineer top navigation bar and authorized routing.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationFilter _activeFilter = NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final user = userProfileAsync.value;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FB),
      // appBar provided by EngineerShell
      body: CustomPaint(
        painter: const BlueprintGridBackgroundPainter(),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(notificationsProvider);
          },
          child: notificationsAsync.when(
            loading: () => const AppLoadingIndicator(
              message: 'Loading notifications stream...',
            ),
            error: (err, _) => AppErrorWidget(
              message: 'Failed to load notifications.',
              onRetry: () => ref.invalidate(notificationsProvider),
            ),
            data: (notifications) {
              return _buildContent(context, notifications, user?.role);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<AppNotification> allNotifications,
    String? role,
  ) {
    final filtered = allNotifications.where((n) {
      switch (_activeFilter) {
        case NotificationFilter.all:
          return true;
        case NotificationFilter.unread:
          return !n.isRead;
        case NotificationFilter.reviews:
          return n.type == 'DRAWING_SUBMITTED' ||
              n.type == 'PROJECT_APPROVED' ||
              n.type == 'CORRECTION_REQUESTED' ||
              n.type == 'REVISION_SUBMITTED';
        case NotificationFilter.remarks:
          return n.type == 'CHAT_MESSAGE';
      }
    }).toList();

    final unreadCount = allNotifications.where((n) => !n.isRead).length;
    final reviewsCount = allNotifications
        .where((n) =>
            n.type == 'DRAWING_SUBMITTED' ||
            n.type == 'PROJECT_APPROVED' ||
            n.type == 'CORRECTION_REQUESTED' ||
            n.type == 'REVISION_SUBMITTED')
        .length;
    final remarksCount =
        allNotifications.where((n) => n.type == 'CHAT_MESSAGE').length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Card
              NotificationHeaderCard(
                subtitle:
                    'Direct notifications on project milestones, draughtsman submissions, and review actions.',
                totalCount: allNotifications.length,
                unreadCount: unreadCount,
                onMarkAllRead: unreadCount > 0
                    ? () async {
                        try {
                          await ref
                              .read(markAllNotificationsReadProvider.future);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('All notifications marked as read.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                onRefresh: () {
                  ref.invalidate(notificationsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications refreshed.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                onClearAll: allNotifications.isNotEmpty
                    ? () => _confirmClearNotifications(context)
                    : null,
              ),

              const SizedBox(height: AppSpacing.lg),

              // 2. Filter Bar
              NotificationFilterBar(
                activeFilter: _activeFilter,
                totalCount: allNotifications.length,
                unreadCount: unreadCount,
                reviewsCount: reviewsCount,
                remarksCount: remarksCount,
                onFilterChanged: (filter) =>
                    setState(() => _activeFilter = filter),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 3. Notification List or Empty State
              if (filtered.isEmpty)
                NotificationEmptyStateCard(
                  message:
                      'You have no notifications under this filter. Updates on project milestones, draughtsman submissions, and reviews will appear here.',
                  actionLabel: 'Back to Dashboard',
                  onAction: () => context.go('/engineer/dashboard'),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final n = filtered[index];
                    return NotificationItemCard(
                      notification: n,
                      onTap: () async {
                        if (!n.isRead) {
                          try {
                            await ref
                                .read(markNotificationReadProvider(n.id).future);
                          } catch (_) {}
                        }
                        if (context.mounted) {
                          _navigateToNotificationTarget(context, n, role);
                        }
                      },
                      onMarkAsRead: !n.isRead
                          ? () async {
                              try {
                                await ref.read(
                                    markNotificationReadProvider(n.id).future);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Marked as read.'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                                }
                              }
                            }
                          : null,
                    );
                  },
                ),

              const SizedBox(height: AppSpacing.xxl),

              // 4. System Footer
              const NotificationSystemFooter(),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToNotificationTarget(
    BuildContext context,
    AppNotification n,
    String? role,
  ) {
    final normalizedRole = role?.toUpperCase();
    if (n.projectId != null && n.projectId!.isNotEmpty) {
      if (n.type == 'CHAT_MESSAGE') {
        if (normalizedRole == 'DRAUGHTSMAN') {
          context.push('/draughtsman/collaboration/${n.projectId}');
        } else if (normalizedRole == 'STUDENT') {
          context.push('/student/workspace/${n.projectId}');
        } else {
          context.push('/engineer/projects/${n.projectId}/collaboration-hub');
        }
      } else {
        if (normalizedRole == 'STUDENT') {
          context.push('/student/workspace/${n.projectId}');
        } else if (normalizedRole == 'DRAUGHTSMAN') {
          context.push('/draughtsman/workspace/${n.projectId}');
        } else {
          context.push('/engineer/projects/${n.projectId}');
        }
      }
    } else {
      if (normalizedRole == 'STUDENT') {
        context.go('/student/dashboard');
      } else if (normalizedRole == 'DRAUGHTSMAN') {
        context.go('/draughtsman/studio');
      } else {
        context.go('/engineer/dashboard');
      }
    }
  }

  Future<void> _confirmClearNotifications(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Notifications?'),
        content: const Text(
          'Are you sure you want to clear your notifications? This will remove all notifications from your list. Your projects and drawings will remain safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm_clear_notifications_button_engineer'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(clearNotificationsProvider.future);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications cleared.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear notifications: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// DRAUGHTSMAN NOTIFICATIONS SCREEN
// ---------------------------------------------------------------------------

/// Draughtsman Notifications Screen
class DraughtsmanNotificationsScreen extends ConsumerStatefulWidget {
  const DraughtsmanNotificationsScreen({super.key});

  @override
  ConsumerState<DraughtsmanNotificationsScreen> createState() =>
      _DraughtsmanNotificationsScreenState();
}

class _DraughtsmanNotificationsScreenState
    extends ConsumerState<DraughtsmanNotificationsScreen> {
  NotificationFilter _activeFilter = NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final assignmentsAsync = ref.watch(draughtsmanAssignmentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FB),
      body: CustomPaint(
        painter: const BlueprintGridBackgroundPainter(),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(notificationsProvider);
            ref.invalidate(draughtsmanAssignmentsProvider);
          },
          child: notificationsAsync.when(
            loading: () => const AppLoadingIndicator(
              message: 'Loading notifications stream...',
            ),
            error: (err, _) => AppErrorWidget(
              message: 'Failed to load notifications.',
              onRetry: () => ref.invalidate(notificationsProvider),
            ),
            data: (notifications) {
              final assignments = assignmentsAsync.maybeWhen(
                data: (list) => list,
                orElse: () => <Assignment>[],
              );

              return _buildContent(context, notifications, assignments);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<AppNotification> allNotifications,
    List<Assignment> assignments,
  ) {
    final filtered = allNotifications.where((n) {
      switch (_activeFilter) {
        case NotificationFilter.all:
          return true;
        case NotificationFilter.unread:
          return !n.isRead;
        case NotificationFilter.reviews:
          return n.type == 'CORRECTION_REQUESTED' ||
              n.type == 'PROJECT_APPROVED' ||
              n.type == 'DRAWING_SUBMITTED';
        case NotificationFilter.remarks:
          return n.type == 'CHAT_MESSAGE';
      }
    }).toList();

    final unreadCount = allNotifications.where((n) => !n.isRead).length;
    final reviewsCount = allNotifications
        .where((n) =>
            n.type == 'CORRECTION_REQUESTED' ||
            n.type == 'PROJECT_APPROVED' ||
            n.type == 'DRAWING_SUBMITTED')
        .length;
    final remarksCount =
        allNotifications.where((n) => n.type == 'CHAT_MESSAGE').length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NotificationHeaderCard(
                subtitle:
                    'Direct notifications on assignments, engineering remarks, and review cycles.',
                totalCount: allNotifications.length,
                unreadCount: unreadCount,
                onMarkAllRead: unreadCount > 0
                    ? () async {
                        try {
                          await ref
                              .read(markAllNotificationsReadProvider.future);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('All notifications marked as read.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                onRefresh: () {
                  ref.invalidate(notificationsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications refreshed.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                onClearAll: allNotifications.isNotEmpty
                    ? () => _confirmClearNotifications(context)
                    : null,
              ),

              const SizedBox(height: AppSpacing.lg),

              NotificationFilterBar(
                activeFilter: _activeFilter,
                totalCount: allNotifications.length,
                unreadCount: unreadCount,
                reviewsCount: reviewsCount,
                remarksCount: remarksCount,
                onFilterChanged: (filter) =>
                    setState(() => _activeFilter = filter),
              ),

              const SizedBox(height: AppSpacing.lg),

              if (filtered.isEmpty)
                NotificationEmptyStateCard(
                  message:
                      'You have no notifications under this filter. Updates on assigned drawings, revisions, and remarks will appear here.',
                  actionLabel: 'Back to Studio',
                  onAction: () => context.go('/draughtsman/studio'),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final n = filtered[index];
                    return NotificationItemCard(
                      notification: n,
                      onTap: () async {
                        if (!n.isRead) {
                          try {
                            await ref
                                .read(markNotificationReadProvider(n.id).future);
                          } catch (_) {}
                        }
                        if (context.mounted) {
                          _navigateToNotificationTarget(context, n, assignments);
                        }
                      },
                      onMarkAsRead: !n.isRead
                          ? () async {
                              try {
                                await ref.read(
                                    markNotificationReadProvider(n.id).future);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Marked as read.'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                                }
                              }
                            }
                          : null,
                    );
                  },
                ),

              const SizedBox(height: AppSpacing.xxl),

              const NotificationSystemFooter(),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToNotificationTarget(
    BuildContext context,
    AppNotification n,
    List<Assignment> assignments,
  ) {
    Assignment? matched;
    for (final a in assignments) {
      if (a.projectName != null &&
          (n.title.contains(a.projectName!) ||
              n.message.contains(a.projectName!))) {
        matched = a;
        break;
      }
      if (n.title.contains(a.projectId) || n.message.contains(a.projectId)) {
        matched = a;
        break;
      }
    }

    switch (n.type) {
      case 'CHAT_MESSAGE':
        if (matched != null) {
          context.push('/draughtsman/collaboration/${matched.id}');
        } else if (assignments.isNotEmpty) {
          context.push('/draughtsman/collaboration/${assignments.first.id}');
        } else {
          context.go('/draughtsman/studio');
        }
        break;

      case 'CORRECTION_REQUESTED':
        if (matched != null) {
          context.push('/draughtsman/workspace/${matched.id}');
        } else if (assignments.isNotEmpty) {
          context.push('/draughtsman/workspace/${assignments.first.id}');
        } else {
          context.go('/draughtsman/studio');
        }
        break;

      case 'PROJECT_APPROVED':
      case 'DRAWING_SUBMITTED':
        if (matched != null) {
          context.push('/draughtsman/drawings/${matched.id}');
        } else {
          context.push('/draughtsman/drawings');
        }
        break;

      default:
        if (matched != null) {
          context.push('/draughtsman/assignments/${matched.id}');
        } else {
          context.go('/draughtsman/studio');
        }
        break;
    }
  }

  Future<void> _confirmClearNotifications(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Notifications?'),
        content: const Text(
          'Are you sure you want to clear your notifications? This will remove all notifications from your list. Your projects, drawings, and corrections will remain safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm_clear_notifications_button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(clearNotificationsProvider.future);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications cleared.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear notifications: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

