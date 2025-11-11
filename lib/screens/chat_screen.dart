import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_message.dart';
import '../providers/model_provider.dart';
import '../providers/message_provider.dart';
import '../providers/conversation_provider.dart' hide LoadStatus;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Future<void> _handleSendMessage(String text) async {
    final msgProv = context.read<MessageProvider>();
    final convProv = context.read<ConversationProvider>();
    final modelProv = context.read<ModelProvider>();

    final selectedModel = modelProv.selectedModel;
    if (selectedModel == null) {
      _showErrorSnackBar('请先选择一个模型');
      return;
    }

    final currentConvId = convProv.selectedConversationId;

    try {
      final newConversationId = await msgProv.sendMessageAndGetReply(
        content: text,
        model: selectedModel,
        conversationId: currentConvId,
      );

      if (newConversationId != null &&
          convProv.selectedConversationId == null &&
          context.mounted) {
        convProv.setConversationId(newConversationId);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('发送消息失败：${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('发送失败'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modelProvider = context.watch<ModelProvider>();
    final conversationProvider = context.watch<ConversationProvider>();
    final messageProvider = context.watch<MessageProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              icon: const Icon(CupertinoIcons.text_alignleft),
              onPressed: () => Scaffold.of(context).openDrawer(),
              highlightColor: Colors.transparent,
            ),
          ),
        ),
        title: _buildModelSelector(modelProvider),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_bubble),
            onPressed: () =>
                context.read<ConversationProvider>().startNewConversation(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('设置功能开发中')));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(
              messageProvider,
              modelProvider,
              conversationProvider,
            ),
          ),
          ChatInput(onSend: _handleSendMessage),
        ],
      ),
    );
  }

  Widget _buildModelSelector(ModelProvider modelProvider) {
    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<String>(
        borderRadius: BorderRadius.circular(16),
        offset: const Offset(0, 40),
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  modelProvider.selectedModel?.displayName ?? '选择模型',
                  style: const TextStyle(fontSize: 20),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        onSelected: (modelId) => modelProvider.selectModel(modelId),
        itemBuilder: (context) {
          if (modelProvider.models.isEmpty) {
            return [const PopupMenuItem(enabled: false, child: Text('暂无可用模型'))];
          }
          return modelProvider.models.map((m) {
            return PopupMenuItem<String>(
              value: m.name,
              child: Row(
                children: [
                  if (m.provider.isNotEmpty)
                    SvgPicture.asset(
                      'assets/${m.provider}.svg',
                      width: 20,
                      height: 20,
                    ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(m.displayName)),
                  if (m.name == modelProvider.selectedModelName)
                    const Icon(CupertinoIcons.check_mark, size: 20),
                ],
              ),
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildMessageList(
      MessageProvider messageProvider,
      ModelProvider modelProvider,
      ConversationProvider conversationProvider,
      ) {
    if (messageProvider.messages.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messageProvider.messages.length,
        itemBuilder: (context, index) {
          return ChatMessageItem(message: messageProvider.messages[index]);
        },
      );
    }

    if (messageProvider.status == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildEmptyState(modelProvider);
  }

  Widget _buildEmptyState(ModelProvider modelProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (modelProvider.selectedModel != null) ...[
            if (modelProvider.selectedModel!.provider.isNotEmpty)
              SvgPicture.asset(
                'assets/${modelProvider.selectedModel!.provider}.svg',
                width: 64,
                height: 64,
              ),
            const SizedBox(height: 16),
            Text(
              modelProvider.selectedModel!.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '开始新的对话',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ] else
            const Text('请选择模型开始对话'),
        ],
      ),
    );
  }
}
