// import 'package:flutter/material.dart';
// import 'package:resi_africa/core/theme/app_colors.dart';
// import 'package:resi_africa/core/theme/app_text_styles.dart';
// import '../../../data/models/identity_document_model.dart';

// class DocumentThumbnail extends StatelessWidget {
//   final IdentityDocumentModel document;
//   final VoidCallback onRemove;

//   const DocumentThumbnail({
//     super.key,
//     required this.document,
//     required this.onRemove,
//   });

//   bool get _isImage {
//     final ext = document.fileName.split('.').last.toLowerCase();
//     return ['jpg', 'jpeg', 'png', 'heic', 'webp'].contains(ext);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Container(
//           width: 90,
//           height: 90,
//           decoration: BoxDecoration(
//             color: AppColors.background,
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: AppColors.divider),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: _isImage
//                 ? Image.file(document.file, fit: BoxFit.cover)
//                 : _FilePlaceholder(fileName: document.fileName),
//           ),
//         ),
//         Positioned(
//           top: -6,
//           right: -6,
//           child: GestureDetector(
//             onTap: onRemove,
//             child: Container(
//               width: 22,
//               height: 22,
//               decoration: const BoxDecoration(
//                 color: AppColors.red,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.close_rounded,
//                 size: 14,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _FilePlaceholder extends StatelessWidget {
//   final String fileName;
//   const _FilePlaceholder({required this.fileName});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Icon(
//           Icons.insert_drive_file_rounded,
//           size: 28,
//           color: AppColors.textSecondary,
//         ),
//         const SizedBox(height: 4),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 4),
//           child: Text(
//             fileName,
//             style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
//             textAlign: TextAlign.center,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//   }
// }
