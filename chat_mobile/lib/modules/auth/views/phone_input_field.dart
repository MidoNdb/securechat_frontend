// lib/modules/auth/views/phone_input_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/phone_formatter.dart';

/// ✅ StatefulWidget pour gérer l'état local correctement
class PhoneInputField extends StatefulWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final String? hintText;
  final String? labelText;
  final bool enabled;

  const PhoneInputField({
    Key? key,
    this.controller,
    this.onChanged,
    this.hintText,
    this.labelText,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  // ✅ État local géré proprement dans State
  String _selectedCountryCode = '+222';
  String _selectedCountryName = 'Mauritanie';
  
  @override
  void dispose() {
    // Pas de controllers à dispose ici, c'est géré par le parent
    super.dispose();
  }
  
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        final countries = PhoneFormatter.getCountries();
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sélectionner un pays',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Liste des pays
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: countries.entries.map((entry) {
                    final countryData = entry.value;
                    final isSelected = countryData['code'] == _selectedCountryCode;
                    
                    return ListTile(
                      leading: Container(
                        width: 60,
                        alignment: Alignment.center,
                        child: Text(
                          countryData['code']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.green : Colors.grey[700],
                          ),
                        ),
                      ),
                      title: Text(countryData['name']!),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      selected: isSelected,
                      selectedTileColor: Colors.green.withOpacity(0.1),
                      onTap: () {
                        setState(() {
                          _selectedCountryCode = countryData['code']!;
                          _selectedCountryName = countryData['name']!;
                        });
                        
                        // Recalculer le numéro E.164 avec le nouveau code
                        final currentText = widget.controller?.text ?? '';
                        if (currentText.isNotEmpty) {
                          _onTextChanged(currentText);
                        }
                        
                        Navigator.pop(modalContext);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _onTextChanged(String value) {
    if (value.isEmpty) {
      widget.onChanged?.call('');
      return;
    }
    
    final e164Number = PhoneFormatter.normalizePhoneNumber(
      value,
      _selectedCountryCode,
    );
    
    widget.onChanged?.call(e164Number);
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Numéro de téléphone',
        hintText: widget.hintText,
        
        // Prefix avec code pays cliquable
        prefixIcon: InkWell(
          onTap: widget.enabled ? _showCountryPicker : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedCountryCode,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.enabled ? Colors.grey[800] : Colors.grey[400],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: widget.enabled ? Colors.grey[600] : Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        
        prefixIconConstraints: const BoxConstraints(
          minWidth: 0,
          minHeight: 0,
        ),
        
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        
        suffixIcon: widget.enabled
            ? Tooltip(
                message: _selectedCountryName,
                child: const Icon(Icons.info_outline, size: 20),
              )
            : null,
      ),
      
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(15),
      ],
      
      onChanged: _onTextChanged,
    );
  }
}


// // lib/modules/auth/views/phone_input_field.dart

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import '../../../core/utils/phone_formatter.dart';

// class PhoneInputField extends StatelessWidget {
//   final TextEditingController controller;
//   final Function(String)? onChanged;
//   final String? hintText;
//   final String? labelText;
//   final bool enabled;

//   const PhoneInputField({
//     Key? key,
//     required this.controller,
//     this.onChanged,
//     this.hintText,
//     this.labelText,
//     this.enabled = true,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // ✅ Controller LOCAL pour ce widget uniquement
//     final selectedCountryCode = '+222'.obs;
//     final selectedCountryName = 'Mauritanie'.obs;
    
//     void showCountryPicker() {
//       showModalBottomSheet(
//         context: context,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         builder: (modalContext) {
//           final countries = PhoneFormatter.getCountries();
          
//           return Container(
//             padding: EdgeInsets.symmetric(vertical: 20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Header
//                 Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 20),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Sélectionner un pays',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.close),
//                         onPressed: () => Navigator.pop(modalContext),
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 Divider(),
                
//                 // Liste des pays
//                 Flexible(
//                   child: Obx(() => ListView(
//                     shrinkWrap: true,
//                     children: countries.entries.map((entry) {
//                       final countryData = entry.value;
//                       final isSelected = countryData['code'] == 
//                           selectedCountryCode.value;
                      
//                       return ListTile(
//                         leading: Container(
//                           width: 60,
//                           alignment: Alignment.center,
//                           child: Text(
//                             countryData['code']!,
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: isSelected ? Colors.green : Colors.grey[700],
//                             ),
//                           ),
//                         ),
//                         title: Text(countryData['name']!),
//                         trailing: isSelected
//                             ? Icon(Icons.check_circle, color: Colors.green)
//                             : null,
//                         selected: isSelected,
//                         selectedTileColor: Colors.green.withOpacity(0.1),
//                         onTap: () {
//                           selectedCountryCode.value = countryData['code']!;
//                           selectedCountryName.value = countryData['name']!;
                          
//                           // Recalculer le numéro E.164
//                           final e164 = PhoneFormatter.normalizePhoneNumber(
//                             controller.text,
//                             countryData['code']!,
//                           );
                          
//                           if (onChanged != null) {
//                             onChanged!(e164);
//                           }
                          
//                           Navigator.pop(modalContext);
//                         },
//                       );
//                     }).toList(),
//                   )),
//                 ),
//               ],
//             ),
//           );
//         },
//       );
//     }
    
//     void onTextChanged(String value) {
//       final e164Number = PhoneFormatter.normalizePhoneNumber(
//         value,
//         selectedCountryCode.value,
//       );
      
//       if (onChanged != null) {
//         onChanged!(e164Number);
//       }
//     }
    
//     return Obx(() => TextField(
//       controller: controller,
//       enabled: enabled,
//       decoration: InputDecoration(
//         labelText: labelText ?? 'Numéro de téléphone',
//         hintText: hintText,
        
//         // Prefix avec code pays
//         prefixIcon: InkWell(
//           onTap: enabled ? showCountryPicker : null,
//           borderRadius: BorderRadius.circular(8),
//           child: Padding(
//             padding: EdgeInsets.only(left: 12, right: 8),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   selectedCountryCode.value,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//                 SizedBox(width: 4),
//                 Icon(
//                   Icons.arrow_drop_down,
//                   color: Colors.grey[600],
//                   size: 20,
//                 ),
//               ],
//             ),
//           ),
//         ),
        
//         prefixIconConstraints: BoxConstraints(
//           minWidth: 0,
//           minHeight: 0,
//         ),
        
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
        
//         suffixIcon: enabled
//             ? Tooltip(
//                 message: selectedCountryName.value,
//                 child: Icon(Icons.info_outline, size: 20),
//               )
//             : null,
//       ),
      
//       keyboardType: TextInputType.phone,
//       textInputAction: TextInputAction.next,
      
//       inputFormatters: [
//         FilteringTextInputFormatter.digitsOnly,
//         LengthLimitingTextInputFormatter(15),
//       ],
      
//       onChanged: onTextChanged,
//     ));
//   }
// }