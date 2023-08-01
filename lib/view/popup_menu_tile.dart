import 'package:flutter/material.dart';

class PopupMenuTile<T> extends PopupMenuItem<T> {
  const PopupMenuTile({
    super.key,
    super.value,
    super.onTap,
    super.enabled,
    super.padding,
    super.height,
    super.mouseCursor,
    this.icon,
    super.child,
  });

  final Widget? icon;

  @override
  PopupMenuItemState<T, PopupMenuTile<T>> createState() => _PopupMenuTileState<T>();
}

class _PopupMenuTileState<T> extends PopupMenuItemState<T, PopupMenuTile<T>> {
  @override
  Widget buildChild() {
    return IgnorePointer(
      child: ListTile(
        enabled: widget.enabled,
        visualDensity: VisualDensity.compact,
        leading: widget.icon,
        title: widget.child,
      ),
    );
  }
}

class RadioPopupMenuTile<T> extends PopupMenuItem<T> {
  const RadioPopupMenuTile({
    super.key,
    super.value,
    required this.groupValue,
    required this.onChange,
    super.enabled,
    super.padding,
    super.height,
    super.mouseCursor,
    super.child,
  });

  final T groupValue;
  final void Function(T value) onChange;

  @override
  void Function() get onTap => () => onChange(value as T);

  @override
  PopupMenuItemState<T, RadioPopupMenuTile<T>> createState() => _RadioPopupMenuTileState<T>();
}

class _RadioPopupMenuTileState<T> extends PopupMenuItemState<T, RadioPopupMenuTile<T>> {
  @override
  Widget buildChild() {
    return IgnorePointer(
      child: ListTile(
        enabled: widget.enabled,
        visualDensity: VisualDensity.compact,
        leading: switch (widget.value == widget.groupValue) {
          true => const Icon(Icons.radio_button_on),
          false => const Icon(Icons.radio_button_off)
        },
        title: widget.child,
      ),
    );
  }
}
