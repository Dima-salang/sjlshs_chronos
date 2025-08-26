import 'package:flutter/material.dart';
import 'package:sjlshs_chronos/features/auth/account_management.dart';
import 'package:go_router/go_router.dart';

class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({super.key});

  @override
  State<AccountVerificationScreen> createState() => _AccountVerificationScreenState();
}

class _AccountVerificationScreenState extends State<AccountVerificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AccountManagement _accountManagement = AccountManagement();
  bool _isLoading = true;
  List<Map<String, dynamic>> _verifiedAccounts = [];
  List<Map<String, dynamic>> _unverifiedAccounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final verified = await _accountManagement.getVerifiedAccounts();
      final unverified = await _accountManagement.getUnverifiedAccounts();
      
      if (mounted) {
        setState(() {
          _verifiedAccounts = verified;
          _unverifiedAccounts = unverified;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading accounts: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Verification'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Unverified'),
            Tab(text: 'Verified'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAccountList(_unverifiedAccounts, isVerified: false),
                _buildAccountList(_verifiedAccounts, isVerified: true),
              ],
            ),
    );
  }

  Widget _buildAccountList(List<Map<String, dynamic>> accounts, {required bool isVerified}) {
    if (accounts.isEmpty) {
      return Center(
        child: Text(
          isVerified 
              ? 'No verified accounts found' 
              : 'No unverified accounts',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAccounts,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: ListTile(
              title: Text(
                account['email'] ?? 'No email',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Role: ${account['role'] ?? 'N/A'}${account['role'] == 'teacher' && account['section'] != null ? ' • Section: ${account['section']}' : ''}'),
              trailing: isVerified
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (account['role'] == 'teacher')
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showSectionDialog(account['uid'], currentSection: account['section'], isAlreadyVerified: true),
                            tooltip: 'Assign Section',
                          ),
                        IconButton(
                          icon: const Icon(Icons.block, color: Colors.red),
                          onPressed: () => _updateVerification(account['uid'], false),
                          tooltip: 'Unverify Account',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAccount(account['uid']),
                          tooltip: 'Delete Account',
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: () => _updateVerification(account['uid'], true, role: account['role']),
                      child: const Text('Verify'),
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateVerification(String uid, bool isVerified, {String? role}) async {
    try {
      if (isVerified) {
        if (role == 'teacher') {
          await _showSectionDialog(uid);
        } else {
          await _accountManagement.verifyAccount(uid);
          _showSuccessSnackBar('Account verified successfully');
        }
      } else {
        await _accountManagement.unverifyAccount(uid);
        _showSuccessSnackBar('Account unverified successfully');
      }
      _loadAccounts();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  Future<void> _showSectionDialog(String uid, {String? currentSection, bool isAlreadyVerified = false}) async {
    final sectionController = TextEditingController(text: currentSection);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAlreadyVerified ? 'Update Section' : 'Assign Section'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: sectionController,
            decoration: const InputDecoration(
              labelText: 'Enter Section (e.g., Microsoft)',
              border: OutlineInputBorder(),
              hintText: 'Example: Microsoft',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a section';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text(isAlreadyVerified ? 'Update' : 'Assign'),
          ),
        ],
      ),
    );

    if (result == true && sectionController.text.trim().isNotEmpty) {
      final section = sectionController.text.trim();
      try {
        if (!isAlreadyVerified) {
          await _accountManagement.verifyAccount(uid);
        }
        await _accountManagement.setSection(uid, section);
        if (mounted) {
          final message = isAlreadyVerified
              ? 'Section updated successfully'
              : 'Teacher verified and assigned to $section';
          _showSuccessSnackBar(message);
        }
        _loadAccounts();
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error assigning section: $e');
        }
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _deleteAccount(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete this account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _accountManagement.deleteAccount(uid);
        _loadAccounts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
