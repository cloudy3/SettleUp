import "package:flutter/material.dart";
import "package:settle_up/services/group_service.dart";
import "package:settle_up/services/error_handling_service.dart";
import "package:settle_up/services/offline_manager.dart";
import "package:settle_up/models/app_error.dart";
import "package:settle_up/utils/form_validators.dart";
import "package:settle_up/utils/loading_state.dart";
import "package:settle_up/widgets/error_handling_widgets.dart";

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final GroupService _groupService = GroupService();
  final OfflineManager _offlineManager = OfflineManager();
  late final ErrorHandlingService _errorHandlingService;

  final LoadingStateNotifier<void> _createGroupNotifier =
      LoadingStateNotifier<void>();
  final FormValidator _formValidator = FormValidator();

  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _createGroupNotifier.dispose();
    _formValidator.clear();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _offlineManager.initialize();
    _errorHandlingService = ErrorHandlingService(
      offlineManager: _offlineManager,
    );
    _groupService.initializeErrorHandling(_errorHandlingService);

    // Listen to connectivity changes
    _offlineManager.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOffline = !isOnline;
        });
      }
    });

    setState(() {
      _isOffline = !_offlineManager.isOnline;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Group"),
        actions: [
          ValueListenableBuilder<LoadingState<void>>(
            valueListenable: _createGroupNotifier,
            builder: (context, state, child) {
              return TextButton(
                onPressed: state.isLoading ? null : _createGroup,
                child: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        "Create",
                        style: TextStyle(color: Colors.white),
                      ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineIndicator(isOffline: _isOffline),
          Expanded(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    _buildGroupIcon(),
                    const SizedBox(height: 32),
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 32),
                    _buildCreateButton(),
                    const SizedBox(height: 16),
                    _buildHelpText(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupIcon() {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Icon(
          Icons.group,
          size: 50,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return ValidatedFormField(
      label: "Group Name",
      hint: "Enter a name for your group",
      controller: _nameController,
      keyboardType: TextInputType.text,
      validator: (value) {
        final error = FormValidators.combine([
          () => FormValidators.required(value, 'Group name'),
          () => FormValidators.minLength(value, 2, 'Group name'),
          () => FormValidators.maxLength(value, 50, 'Group name'),
        ]);
        return error?.displayMessage;
      },
    );
  }

  Widget _buildDescriptionField() {
    return ValidatedFormField(
      label: "Description (Optional)",
      hint: "What's this group for?",
      controller: _descriptionController,
      maxLines: 3,
      validator: (value) {
        final error = FormValidators.maxLength(value, 200, 'Description');
        return error?.displayMessage;
      },
    );
  }

  Widget _buildCreateButton() {
    return ValueListenableBuilder<LoadingState<void>>(
      valueListenable: _createGroupNotifier,
      builder: (context, state, child) {
        return Column(
          children: [
            if (state.isError) ...[
              ErrorDisplay(
                error: state.error!,
                onRetry: _createGroup,
                onDismiss: () => _createGroupNotifier.setIdle(),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: state.isLoading ? null : _createGroup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: state.isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text("Creating Group..."),
                      ],
                    )
                  : Text(
                      _isOffline ? "Queue Group Creation" : "Create Group",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpText() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  "Getting Started",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "• You'll be added as the first member\n"
              "• Invite friends via email after creating\n"
              "• Start adding expenses to track who owes what",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await _createGroupNotifier.execute(
      () async {
        final group = await _groupService.createGroup(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isOffline
                    ? "Group creation queued for when you're back online"
                    : "Group '${group.name}' created successfully!",
              ),
              backgroundColor: _isOffline ? Colors.orange : Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate back to group list
          Navigator.of(context).pop(group);
        }
      },
      loadingMessage: _isOffline
          ? "Queuing group creation..."
          : "Creating group...",
      successMessage: _isOffline
          ? "Group creation queued"
          : "Group created successfully",
    );
  }
}
