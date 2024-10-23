import 'package:flutter/material.dart';
import 'package:soundify/view/style/style.dart';

class HoverIconsWidget extends StatefulWidget {
  final bool isClicked;
  final Function(int) onItemTapped;
  final int index;
  final bool isHoveringParent; // New parameter to receive parent's hover state
  final Function(bool) onHoverChange; // Callback to notify parent of hover changes

  const HoverIconsWidget({
    Key? key,
    required this.isClicked,
    required this.onItemTapped,
    required this.index,
    required this.isHoveringParent,
    required this.onHoverChange,
  }) : super(key: key);

  @override
  State<HoverIconsWidget> createState() => _HoverIconsWidgetState();
}

class _HoverIconsWidgetState extends State<HoverIconsWidget> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onHoverChange(true), // Notify parent when hovered
      onExit: (_) => widget.onHoverChange(false), // Notify parent when hover exits
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isHoveringParent || widget.isClicked) // Check parent's hover state
            SizedBox(
              width: 45,
              child: GestureDetector(
                onTap: () {
                  widget.onItemTapped(widget.index); // Notify parent about the tap
                  
                },
                child: const Icon(
                  Icons.more_horiz,
                  color: primaryTextColor,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
