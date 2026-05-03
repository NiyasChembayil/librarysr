import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CategoryChips extends StatefulWidget {
  final List<String> categories;
  final Function(String) onCategorySelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final List<String> allCategories = ['All', ...widget.categories];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  HapticFeedback.lightImpact();
                  setState(() => selectedCategory = category);
                  widget.onCategorySelected(category);
                }
              },
              backgroundColor: const Color(0xFF1E1E2E),
              selectedColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              showCheckmark: false,
              elevation: isSelected ? 4 : 0,
              shadowColor: const Color(0xFF6C63FF).withValues(alpha: 0.4),
            ),
          );
        },
      ),
    );
  }
}
