import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../models/tool.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/status_chip.dart';
import '../utils/responsive_helper.dart';
import 'technicians_screen.dart';
import 'dart:io';

class AssignToolScreen extends StatefulWidget {
  const AssignToolScreen({super.key});

  @override
  State<AssignToolScreen> createState() => _AssignToolScreenState();
}

class _AssignToolScreenState extends State<AssignToolScreen> {
  Set<String> _selectedTools = <String>{};

  Future<void> _refresh() async {
    await context.read<SupabaseToolProvider>().loadTools();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Assign Tools',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: context.appBarBackground,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
            child: IconButton(
            icon: Icon(
                Icons.chevron_left,
                size: 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: Consumer<SupabaseToolProvider>(
          builder: (context, toolProvider, child) {
            final tools = toolProvider.tools;
            
            if (tools.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.build,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    Text(
                      'No tools available',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                    Text(
                      'Add some tools first to assign them',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Instructions
                Container(
                  width: double.infinity,
                  margin: ResponsiveHelper.getResponsivePadding(context, all: 16),
                  padding: ResponsiveHelper.getResponsivePadding(context, all: 20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradientFor(context),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: ResponsiveHelper.getResponsivePadding(context, all: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: AppTheme.secondaryColor,
                          size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select tools to assign to technicians',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                            Text(
                              'Tap tools to select them, then tap "Assign" to continue',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
                // Tools Grid
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
                      final spacing = ResponsiveHelper.getResponsiveGridSpacing(context, 12);
                      final mainSpacing = ResponsiveHelper.getResponsiveGridSpacing(context, 16);
                      final aspectRatio = ResponsiveHelper.getResponsiveAspectRatio(context, 0.65);
                      
                      return GridView.builder(
                        padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: mainSpacing,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: tools.length,
                        itemBuilder: (context, index) {
                          final tool = tools[index];
                          return _buildToolCard(context, tool);
                        },
                      );
                    },
                  ),
                  ),
                ),

                // Assignment Button
                Container(
                  padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradientFor(context),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _selectedTools.isNotEmpty
                          ? LinearGradient(
                              colors: [AppTheme.secondaryColor, AppTheme.secondaryColor.withOpacity(0.85)],
                            )
                          : null,
                      color: _selectedTools.isEmpty ? Colors.grey[300] : null,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 28)),
                      boxShadow: _selectedTools.isNotEmpty
                          ? [
                              BoxShadow(
                                color: AppTheme.secondaryColor.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _selectedTools.isNotEmpty
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TechniciansScreen(),
                                    settings: RouteSettings(
                                      arguments: {'selectedTools': _selectedTools.toList()},
                                    ),
                                  ),
                                );
                              }
                            : null,
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 28)),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveHelper.getResponsiveSpacing(context, 18),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people,
                                color: _selectedTools.isNotEmpty ? Colors.white : Colors.grey[600],
                                size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                              ),
                              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                              Flexible(
                                child: Text(
                                  _selectedTools.isNotEmpty
                                      ? 'Assign ${_selectedTools.length} Tool${_selectedTools.length > 1 ? 's' : ''} to Technicians'
                                      : 'Select Tools First',
                                  style: TextStyle(
                                    color: _selectedTools.isNotEmpty ? Colors.white : Colors.grey[600],
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, Tool tool) {
    final isSelected = tool.id != null && _selectedTools.contains(tool.id!);
    
    return InkWell(
      onTap: () {
        setState(() {
          if (tool.id != null) {
            if (isSelected) {
              _selectedTools.remove(tool.id!);
            } else {
              _selectedTools.add(tool.id!);
            }
          }
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Full Image Card - Square
          AspectRatio(
            aspectRatio: 1.0, // Perfect square
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradientFor(context),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isSelected
                        ? Border.all(
                            color: AppTheme.secondaryColor,
                            width: 3,
                          )
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: tool.imagePath != null
                      ? (tool.imagePath!.startsWith('http')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 28)),
                              child: Image.network(
                                tool.imagePath!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(context),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 28)),
                              child: Image.file(
                                File(tool.imagePath!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(context),
                              ),
                            ))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 28)),
                          child: _buildPlaceholderImage(context),
                        ),
                ),
                // Selection Checkbox
                Positioned(
                  top: ResponsiveHelper.getResponsiveSpacing(context, 8),
                  right: ResponsiveHelper.getResponsiveSpacing(context, 8),
                  child: Container(
                    width: ResponsiveHelper.getResponsiveIconSize(context, 28),
                    height: ResponsiveHelper.getResponsiveIconSize(context, 28),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.secondaryColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.secondaryColor : Colors.grey[300]!,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 18),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          
          // Details Below Card
          Padding(
            padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveSpacing(context, 8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tool Name and Type in one line
                Text(
                  '${tool.name} • ${tool.category}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                // Status and Condition Pills
                Wrap(
                  spacing: ResponsiveHelper.getResponsiveSpacing(context, 6),
                  children: [
                    StatusChip(
                      status: tool.status,
                      showIcon: false,
                    ),
                    ConditionChip(condition: tool.condition),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build,
            size: ResponsiveHelper.getResponsiveIconSize(context, 40),
            color: Colors.grey[400],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}