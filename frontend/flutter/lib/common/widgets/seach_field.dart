import 'package:flutter/material.dart';

class AnimatedSearchField extends StatefulWidget {
  Function performAction;
  AnimatedSearchField({required this.performAction});

  @override
  _AnimatedSearchFieldState createState() => _AnimatedSearchFieldState();
}

class _AnimatedSearchFieldState extends State<AnimatedSearchField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  bool _isExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _widthAnimation = Tween<double>(begin: 0, end: 0).animate(_controller);
    Future.delayed(Duration.zero).then((_) => _toggleSearch());
  }

  void _toggleSearch() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        // Set the end value based on screen width
        final double screenWidth = MediaQuery.of(context).size.width;
        _widthAnimation = Tween<double>(
                begin: 0, end: screenWidth - 40) // 60% of screen width
            .animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));
        _controller.forward();
      } else {
        _controller.reverse();
        _searchController.clear(); // Clear the text field when collapsed
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _widthAnimation,
          builder: (context, child) {
            return Container(
              width: _widthAnimation.value,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onSubmitted: (value) {
                        widget.performAction(value.trim());
                      },
                      controller: _searchController,
                      autofocus: _isExpanded,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(10),
                        hintText: 'Search...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_widthAnimation.isCompleted)
                    // Search Button
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () =>
                          widget.performAction(_searchController.text.trim()),
                    ),
                ],
              ),
            );
          },
        ),
        // IconButton(
        //   icon: Icon(_isExpanded ? Icons.close : Icons.search),
        //   onPressed: _toggleSearch,
        // ),
      ],
    );
  }
}
