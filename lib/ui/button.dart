import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ButtonVariant { primary, destructive, outline, secondary, ghost, link }
enum ButtonSize { defaultSize, sm, lg, icon }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isDisabled;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.defaultSize,
    this.icon,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyles = _getButtonStyles(context);

    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: buttonStyles,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 16, color: _getIconColor(context)),
          if (icon != null) const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _getButtonStyles(BuildContext context) {
    final theme = Theme.of(context);
    final isOutlined = variant == ButtonVariant.outline;

    Color backgroundColor, foregroundColor, borderColor;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = Color(0xFF00ad9c);
        foregroundColor = Colors.white;
        borderColor = Colors.transparent;
        break;
      case ButtonVariant.destructive:
        backgroundColor = Colors.red;
        foregroundColor = Colors.white;
        borderColor = Colors.transparent;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = theme.primaryColor;
        borderColor = theme.primaryColor;
        break;
      case ButtonVariant.secondary:
        backgroundColor = Colors.grey[300]!;
        foregroundColor = Colors.black;
        borderColor = Colors.transparent;
        break;
      case ButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = Colors.black54;
        borderColor = Colors.transparent;
        break;
      case ButtonVariant.link:
        backgroundColor = Colors.transparent;
        foregroundColor = theme.primaryColor;
        borderColor = Colors.transparent;
        break;
    }

    return ElevatedButton.styleFrom(
      backgroundColor: isDisabled ? Colors.grey[400] : backgroundColor,
      foregroundColor: isDisabled ? Colors.white : foregroundColor,
      padding: _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isOutlined ? borderColor : Colors.transparent),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case ButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 4);
      case ButtonSize.icon:
        return const EdgeInsets.all(10);
      case ButtonSize.defaultSize:
      default:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  Color _getIconColor(BuildContext context) {
    if (isDisabled) return Colors.white;
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.destructive:
        return Colors.white;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  Color _getTextColor(BuildContext context) {
    if (isDisabled) return Colors.white;
    return variant == ButtonVariant.primary || variant == ButtonVariant.destructive
        ? Colors.white
        : Theme.of(context).primaryColor;
  }
}
