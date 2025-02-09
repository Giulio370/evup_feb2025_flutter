import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:evup_feb2025_flutter/core/api/auth_repository.dart';

class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  _PlanPageState createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  List<Map<String, dynamic>> plans = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final plansData = await authRepo.getPlans();

      setState(() {
        plans = plansData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scegli un Piano')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return _buildPlanCard(plan);
        },
      ),
    );
  }

  Future<void> _simulatePurchase(Map<String, dynamic> plan) async {

    bool confirmed = await _showConfirmationDialog(plan);
    if (!confirmed) return;


    _showLoadingDialog();

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (context.mounted) {
        Navigator.pop(context);
        _showSuccessDialog(plan['name']);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante l\'acquisto: $e')),
        );
      }
    }
  }


  Future<bool> _showConfirmationDialog(Map<String, dynamic> plan) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Conferma Acquisto'),
          content: Text('Vuoi acquistare il piano "${plan['name']}" per €${plan['price']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Conferma'),
            ),
          ],
        );
      },
    ) ??
        false;
  }


  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Elaborazione pagamento...'),
            ],
          ),
        );
      },
    );
  }


  void _showSuccessDialog(String planName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Acquisto completato'),
          content: Text('Hai acquistato con successo il piano "$planName"!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }



  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            //Text(plan['description'], style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text("€${plan['price']} / ${plan['billingRenew']} mesi", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (plan['includedItems'] as List)
                  .map((item) => Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 5),
                  Expanded(child: Text(item)),
                ],
              ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _simulatePurchase(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Acquista"),
            ),

          ],
        ),
      ),
    );
  }
}
