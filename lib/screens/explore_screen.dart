import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'Creatives'),
            Tab(text: 'Shorts'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildForYouTab(),
              _buildCreativesTab(),
              _buildShortsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForYouTab() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildContentItem(context, index);
      },
    );
  }

  Widget _buildCreativesTab() {
    return const Center(
      child: Text('Creatives content coming soon'),
    );
  }

  Widget _buildShortsTab() {
    return const Center(
      child: Text('Shorts content coming soon'),
    );
  }

  Widget _buildContentItem(BuildContext context, int index) {
    // This is a simplified version of the content item
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 400,
                width: double.infinity,
                color: Colors.grey[900],
                child: Center(
                  child: Icon(
                    index % 2 == 0 ? Icons.image : Icons.movie,
                    size: 80,
                    color: Colors.white30,
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Effects',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {
                        // Handle like action
                      },
                    ),
                    const Text('29'),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 20, color: Colors.white54),
                ),
                const SizedBox(width: 8),
                const Text(
                  '@Sea Star',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    // Handle recreate action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Recreate'),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // Handle share action
                  },
                ),
              ],
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}