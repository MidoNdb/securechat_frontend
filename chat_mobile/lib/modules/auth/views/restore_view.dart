// // lib/app/modules/auth/views/restore_page.dart

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/restore_controller.dart';

// class RestorePage extends GetView<RestoreController> {
//   // Récupérer le password depuis les arguments
//   final String password = Get.arguments?['password'] ?? '';
  
//   RestorePage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Restauration'),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: controller.backToLogin,
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Icône
//               Icon(
//                 Icons.cloud_download_outlined,
//                 size: 100,
//                 color: Theme.of(context).primaryColor,
//               ),
              
//               const SizedBox(height: 32),
              
//               // Titre
//               Text(
//                 'Restauration de votre compte',
//                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
              
//               const SizedBox(height: 16),
              
//               // Description
//               Text(
//                 'Vous vous connectez depuis un nouvel appareil. '
//                 'Vos clés de chiffrement doivent être restaurées '
//                 'pour accéder à vos messages.',
//                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                   color: Colors.grey[600],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
              
//               const SizedBox(height: 48),
              
//               // Option 1 : Restaurer depuis backup
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade50,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: Colors.blue.shade200,
//                     width: 2,
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Icon(
//                       Icons.backup_outlined,
//                       size: 48,
//                       color: Colors.blue.shade700,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Restaurer depuis backup',
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue.shade900,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Vos clés sont sauvegardées de manière chiffrée '
//                       'sur nos serveurs.',
//                       style: TextStyle(
//                         color: Colors.blue.shade700,
//                         fontSize: 14,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),
//                     Obx(() => ElevatedButton(
//                       onPressed: controller.isLoading.value
//                           ? null
//                           : () => controller.restoreFromBackup(password),
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 32,
//                           vertical: 16,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: controller.isLoading.value
//                           ? const SizedBox(
//                               height: 20,
//                               width: 20,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                   Colors.white,
//                                 ),
//                               ),
//                             )
//                           : const Text(
//                               'Restaurer mes clés',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                     )),
//                   ],
//                 ),
//               ),
              
//               const SizedBox(height: 24),
              
//               // Divider
//               Row(
//                 children: [
//                   const Expanded(child: Divider()),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Text(
//                       'OU',
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const Expanded(child: Divider()),
//                 ],
//               ),
              
//               const SizedBox(height: 24),
              
//               // Option 2 : Nouveau compte
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.shade50,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: Colors.orange.shade200,
//                     width: 2,
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Icon(
//                       Icons.new_releases_outlined,
//                       size: 48,
//                       color: Colors.orange.shade700,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Créer de nouvelles clés',
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.orange.shade900,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '⚠️ Vos anciens messages seront perdus',
//                       style: TextStyle(
//                         color: Colors.orange.shade700,
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),
//                     OutlinedButton(
//                       onPressed: controller.createNewKeys,
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 32,
//                           vertical: 16,
//                         ),
//                         side: BorderSide(
//                           color: Colors.orange.shade700,
//                           width: 2,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: Text(
//                         'Nouveau départ',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.orange.shade700,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               const SizedBox(height: 32),
              
//               // Message d'erreur
//               Obx(() {
//                 if (controller.errorMessage.value.isNotEmpty) {
//                   return Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.red.shade50,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.red.shade200),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.error_outline, color: Colors.red.shade700),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             controller.errorMessage.value,
//                             style: TextStyle(color: Colors.red.shade700),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//                 return const SizedBox.shrink();
//               }),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }