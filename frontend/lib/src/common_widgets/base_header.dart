import 'package:flutter/material.dart';

class BaseHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingTap;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final Widget? flexibleSpace;

  const BaseHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.leadingIcon,
    this.onLeadingTap,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.flexibleSpace,
  });

  @override
  Widget build(BuildContext context) {
    // Determine effective colors
    final bgColor = backgroundColor ?? Colors.white;
    // Auto-calculate foreground color if not provided
    final fgColor = foregroundColor ?? (
      bgColor == Colors.transparent 
        ? Colors.black // Default for transparent
        : (bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white)
    );
    
    return AppBar(
      backgroundColor: bgColor,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      
      // Leading Handling
      leading: leadingIcon != null 
          ? IconButton(
              icon: Icon(leadingIcon, color: fgColor),
              onPressed: onLeadingTap ?? () => Navigator.maybePop(context),
            )
          : (onLeadingTap != null 
              ? IconButton(
                  icon: Icon(Icons.arrow_back, color: fgColor),
                  onPressed: onLeadingTap,
                ) 
              : null), // Let Scaffold handle default back button if null
              
      // Title Handling
      title: titleWidget ?? (title != null 
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text(
                  title!, 
                  style: TextStyle(
                    color: fgColor, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 18
                  )
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: fgColor.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.normal
                    ),
                  )
              ],
            ) 
          : null),
          
      // Actions Handling    
      actions: actions?.map((a) {
        return Theme(
          data: Theme.of(context).copyWith(
            iconTheme: IconThemeData(color: fgColor),
            textTheme: TextTheme(bodyMedium: TextStyle(color: fgColor)),
          ), 
          child: a
        );
      }).toList(),
      
      iconTheme: IconThemeData(color: fgColor),
      surfaceTintColor: Colors.transparent, // Disable Material 3 tint
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0)
  );
}
