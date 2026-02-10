// lib/modules/auth/views/register_view.dart

import 'package:chat_mobile/modules/auth/views/phone_input_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(  // ✅ AJOUTÉ pour éviter overflow
          padding: const EdgeInsets.all(24.0),
          child: Obx(() {
            // ═══════════════════════════════════════════════════
            // ÉTAT 1 : Vérification du téléphone (AVANT OTP)
            // ═══════════════════════════════════════════════════
            if (!controller.isPhoneVerified.value) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Icône
                  Icon(
                    Icons.phone_android,
                    size: 70,
                    color: Theme.of(context).primaryColor,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Titre
                  Text(
                    'Vérifiez votre numéro',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Nous vous enverrons un code de vérification par SMS',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Champ téléphone
                  PhoneInputField(
                    controller: controller.phoneController,
                    onChanged: controller.onPhoneChanged,
                    hintText: '44 01 04 47',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Bouton Envoyer Code
                  Obx(() => ElevatedButton(
                    onPressed: controller.phoneIsValid.value
                        ? controller.sendOtpAndVerify
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Envoyer le code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                  
                  const SizedBox(height: 16),
                  
                  // Lien vers connexion
                  TextButton(
                    onPressed: controller.goToLogin,
                    child: RichText(
                      text: TextSpan(
                        text: 'Déjà un compte ? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Se connecter',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              );
            }
            
            // ═══════════════════════════════════════════════════
            // ÉTAT 2 : Formulaire complet (APRÈS OTP VALIDÉ)
            // ═══════════════════════════════════════════════════
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Icône
                Icon(
                  Icons.person_add_outlined,
                  size: 70,
                  color: Theme.of(context).primaryColor,
                ),
                
                const SizedBox(height: 20),
                
                // Titre
                Text(
                  'Créer un compte',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 6),
                
                Text(
                  'Complétez votre profil',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Indicateur téléphone vérifié
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '✓ ${controller.phoneE164.value} vérifié',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Champ nom d'utilisateur
                TextField(
                  controller: controller.usernameController,
                  decoration: InputDecoration(
                    labelText: 'Nom d\'utilisateur *',
                    hintText: 'Mohamed Imijine',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                
                const SizedBox(height: 16),
                
                // Champ mot de passe
                Obx(() => TextField(
                  controller: controller.passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe *',
                    hintText: 'Minimum 8 caractères',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscurePassword.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: controller.obscurePassword.value,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => controller.register(),
                )),
                
                const SizedBox(height: 20),
                
                // Message d'erreur
                Obx(() {
                  if (controller.errorMessage.value.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              controller.errorMessage.value,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                
                // Info chiffrement
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Vos clés de chiffrement seront générées automatiquement',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bouton d'inscription
                Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'S\'inscrire',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                )),
                
                const SizedBox(height: 20),
              ],
            );
          }),
        ),
      ),
    );
  }
}




// // lib/app/modules/auth/views/register_page.dart

// import 'package:chat_mobile/modules/auth/views/phone_input_field.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/register_controller.dart';

// class RegisterView extends GetView<RegisterController> {
//   const RegisterView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Inscription'),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Icône
//                 Icon(
//                   Icons.person_add_outlined,
//                   size: 80,
//                   color: Theme.of(context).primaryColor,
//                 ),
                
//                 const SizedBox(height: 24),
                
//                 // Titre
//                 Text(
//                   'Créer un compte',
//                   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
                
//                 const SizedBox(height: 8),
                
//                 Text(
//                   'Rejoignez SecureChat en quelques secondes',
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: Colors.grey[600],
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
                
//                 const SizedBox(height: 32),
                
//                 // ← REMPLACÉ : Ancien TextField par PhoneInputField
//                 PhoneInputField(
//                   controller: controller.phoneController,
//                   onChanged: controller.onPhoneChanged,
//                   hintText: '44 01 04 47',
//                 ),
                
//                 const SizedBox(height: 16),
                
//                 // Champ nom d'utilisateur
//                 TextField(
//                   controller: controller.usernameController,
//                   decoration: InputDecoration(
//                     labelText: 'Nom d\'utilisateur *',
//                     hintText: 'Mohamed Imijine',
//                     prefixIcon: const Icon(Icons.person),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   textInputAction: TextInputAction.next,
//                 ),
                
//                 const SizedBox(height: 16),
                
//                 // Champ email (optionnel)
//                 TextField(
//                   controller: controller.emailController,
//                   decoration: InputDecoration(
//                     labelText: 'Email (optionnel)',
//                     hintText: 'mohamed@example.com',
//                     prefixIcon: const Icon(Icons.email),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   keyboardType: TextInputType.emailAddress,
//                   textInputAction: TextInputAction.next,
//                 ),
                
//                 const SizedBox(height: 16),
                
//                 // Champ mot de passe
//                 Obx(() => TextField(
//                   controller: controller.passwordController,
//                   decoration: InputDecoration(
//                     labelText: 'Mot de passe *',
//                     hintText: 'Minimum 8 caractères',
//                     prefixIcon: const Icon(Icons.lock),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         controller.obscurePassword.value
//                             ? Icons.visibility_off
//                             : Icons.visibility,
//                       ),
//                       onPressed: controller.togglePasswordVisibility,
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   obscureText: controller.obscurePassword.value,
//                   textInputAction: TextInputAction.done,
//                   onSubmitted: (_) => controller.register(),
//                 )),
                
//                 const SizedBox(height: 24),
                
//                 // Message d'erreur
//                 Obx(() {
//                   if (controller.errorMessage.value.isNotEmpty) {
//                     return Container(
//                       padding: const EdgeInsets.all(12),
//                       margin: const EdgeInsets.only(bottom: 16),
//                       decoration: BoxDecoration(
//                         color: Colors.red.shade50,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.red.shade200),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.error_outline, color: Colors.red.shade700),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               controller.errorMessage.value,
//                               style: TextStyle(color: Colors.red.shade700),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }
//                   return const SizedBox.shrink();
//                 }),
                
//                 // Info chiffrement
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   margin: const EdgeInsets.only(bottom: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.blue.shade200),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.security, color: Colors.blue.shade700),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           'Vos clés de chiffrement seront générées automatiquement',
//                           style: TextStyle(
//                             color: Colors.blue.shade700,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 // Bouton d'inscription
//                 Obx(() => ElevatedButton(
//                   onPressed: controller.isLoading.value ? null : controller.register,
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: controller.isLoading.value
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                           ),
//                         )
//                       : const Text(
//                           'S\'inscrire',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 )),
                
//                 const SizedBox(height: 16),
                
//                 // Lien vers connexion
//                 TextButton(
//                   onPressed: controller.goToLogin,
//                   child: RichText(
//                     text: TextSpan(
//                       text: 'Déjà un compte ? ',
//                       style: Theme.of(context).textTheme.bodyMedium,
//                       children: [
//                         TextSpan(
//                           text: 'Se connecter',
//                           style: TextStyle(
//                             color: Theme.of(context).primaryColor,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }