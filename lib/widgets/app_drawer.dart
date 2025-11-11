import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conversation_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final conversationProvider = context.watch<ConversationProvider>();
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '近期对话',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.grey[600]),
                  tooltip: '刷新',
                  onPressed: () {
                    final provider = context.read<ConversationProvider>();
                    provider.refreshConversations();
                  },
                ),
              ],
            ),
            Expanded(
              child: _buildConversationList(context, conversationProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            context.read<ConversationProvider>().startNewConversation();
            Navigator.pop(context);
          },
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(CupertinoIcons.pencil_outline),
                const SizedBox(width: 10),
                Text(
                  '发起新对话',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList(
      BuildContext context,
      ConversationProvider conversationProvider,
      ) {
    if (conversationProvider.status == LoadStatus.loading && !conversationProvider.hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (conversationProvider.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text('暂无对话', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: conversationProvider.conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversationProvider.conversations[index];
        final isSelected = conversation.id == conversationProvider.selectedConversationId;

        return Material(
          color: isSelected ? Colors.blue.withAlpha(64) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              context.read<ConversationProvider>().selectConversation(conversation.id);
              Navigator.pop(context);
            },
            onLongPress: () {
              _showDeleteConfirmation(context, conversation.id);
            },
            child: ListTile(
              visualDensity: const VisualDensity(vertical: -4),
              title: Text(
                conversation.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: isSelected
                    ? Theme.of(context).textTheme.titleSmall
                    : Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除对话'),
        content: const Text('确定要删除这个对话吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<ConversationProvider>().deleteConversation(conversationId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}