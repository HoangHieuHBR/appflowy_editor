import 'dart:io';

import 'package:flutter/material.dart';

import 'widgets.dart';

class FlowyButton extends StatelessWidget {
  final Widget text;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final void Function(bool)? onHover;
  final EdgeInsets? margin;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final Color? hoverColor;
  final bool isSelected;
  final BorderRadius? radius;
  final BoxDecoration? decoration;
  final bool useIntrinsicWidth;
  final bool disable;
  final double disableOpacity;
  final Size? leftIconSize;
  final bool expandText;
  final MainAxisAlignment mainAxisAlignment;
  final bool showDefaultBoxDecorationOnMobile;
  final double iconPadding;
  final bool expand;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool resetHoverOnRebuild;

  const FlowyButton({
    super.key,
    required this.text,
    this.onTap,
    this.onSecondaryTap,
    this.onHover,
    this.margin,
    this.leftIcon,
    this.rightIcon,
    this.hoverColor,
    this.isSelected = false,
    this.radius,
    this.decoration,
    this.useIntrinsicWidth = false,
    this.disable = false,
    this.disableOpacity = 0.5,
    this.leftIconSize = const Size.square(16),
    this.expandText = true,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.showDefaultBoxDecorationOnMobile = false,
    this.iconPadding = 6,
    this.expand = false,
    this.borderColor,
    this.backgroundColor,
    this.resetHoverOnRebuild = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = hoverColor ?? Theme.of(context).colorScheme.secondary;
    final alpha = (255 * disableOpacity).toInt();
    color.withAlpha(alpha);

    if (Platform.isIOS || Platform.isAndroid) {
      return InkWell(
        onTap: disable ? null : onTap,
        onSecondaryTap: disable ? null : onSecondaryTap,
        borderRadius: radius ?? Corners.s6Border,
        child: _render(context),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disable ? null : onTap,
      onSecondaryTap: disable ? null : onSecondaryTap,
      child: FlowyHover(
        resetHoverOnRebuild: resetHoverOnRebuild,
        cursor:
            disable ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        style: HoverStyle(
          borderRadius: radius ?? Corners.s6Border,
          hoverColor: color,
          borderColor: borderColor ?? Colors.transparent,
          backgroundColor: backgroundColor ?? Colors.transparent,
        ),
        onHover: disable ? null : onHover,
        isSelected: () => isSelected,
        builder: (context, onHover) => _render(context),
      ),
    );
  }

  Widget _render(BuildContext context) {
    final List<Widget> children = [];

    if (leftIcon != null) {
      children.add(
        SizedBox.fromSize(
          size: leftIconSize,
          child: leftIcon!,
        ),
      );
      children.add(HSpace(iconPadding));
    }

    if (expandText) {
      children.add(Expanded(child: text));
    } else {
      children.add(text);
    }

    if (rightIcon != null) {
      children.add(HSpace(iconPadding));
      // No need to define the size of rightIcon. Just use its intrinsic width
      children.add(rightIcon!);
    }

    Widget child = Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: children,
    );

    if (useIntrinsicWidth) {
      child = IntrinsicWidth(child: child);
    }

    var decoration = this.decoration;

    if (decoration == null &&
        (showDefaultBoxDecorationOnMobile &&
            (Platform.isIOS || Platform.isAndroid))) {
      decoration = BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
      );
    }

    if (decoration == null && (Platform.isIOS || Platform.isAndroid)) {
      if (showDefaultBoxDecorationOnMobile) {
        decoration = BoxDecoration(
          border: Border.all(
            color: borderColor ?? Theme.of(context).colorScheme.outline,
            width: 1.0,
          ),
          borderRadius: radius,
        );
      } else if (backgroundColor != null) {
        decoration = BoxDecoration(
          color: backgroundColor,
          borderRadius: radius,
        );
      }
    }

    return DecoratedBox(
      decoration: decoration as Decoration,
      child: Padding(
        padding: margin ??
            const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
        child: child,
      ),
    );
  }
}