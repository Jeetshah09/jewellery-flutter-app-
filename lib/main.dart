import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'admin_dashboard.dart';

void main() {
  runApp(const AureliaApp());
}

class AureliaApp extends StatelessWidget {
  const AureliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aurelia Fine Jewellery',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F4F0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9B4D5C),
          brightness: Brightness.light,
        ),
        fontFamily: 'Georgia',
      ),
      home: const WebsiteShell(),
    );
  }
}

class Product {
  final int id;
  final String name;
  final String category;
  final String image;
  final double price;
  final String description;
  final String material;
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.price,
    required this.description,
    required this.material,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      image: json['image'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      material: json['material'] as String,
      stock: json['stock'] as int,
    );
  }
}

const products = [
  Product(
    id: 1,
    name: 'Lumiere Ring',
    category: 'Rings',
    image:
        'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=900&q=85',
    price: 599,
    description: 'A luminous silhouette for every day.',
    material: '18k recycled gold, lab-grown diamond',
    stock: 8,
  ),
  Product(
    id: 2,
    name: 'Solene Necklace',
    category: 'Necklaces',
    image:
        'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=900&q=85',
    price: 899,
    description: 'Delicate gold, designed to layer.',
    material: '18k recycled gold, freshwater pearl',
    stock: 5,
  ),
  Product(
    id: 3,
    name: 'Pearl Arc Earrings',
    category: 'Earrings',
    image:
        'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=900&q=85',
    price: 299,
    description: 'Soft luster with a modern curve.',
    material: 'Sterling silver, freshwater pearl',
    stock: 12,
  ),
  Product(
    id: 4,
    name: 'Celine Bracelet',
    category: 'Bracelets',
    image:
        'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=900&q=85',
    price: 399,
    description: 'A quiet statement in polished metal.',
    material: 'Gold vermeil, recycled silver',
    stock: 6,
  ),
  Product(
    id: 5,
    name: 'Nocturne Pendant',
    category: 'Necklaces',
    image:
        'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=900&q=85',
    price: 749,
    description: 'A moonlit pendant with an architectural edge.',
    material: '18k gold, black spinel',
    stock: 7,
  ),
  Product(
    id: 6,
    name: 'Iris Hoops',
    category: 'Earrings',
    image:
        'https://images.unsplash.com/photo-1635767798638-3e25273a8236?w=900&q=85',
    price: 249,
    description: 'Sculptural hoops made for everyday movement.',
    material: 'Recycled sterling silver',
    stock: 14,
  ),
  Product(
    id: 7,
    name: 'Celeste Signet',
    category: 'Rings',
    image:
        'https://images.unsplash.com/photo-1603561596112-db8d2a5b4a4b?w=900&q=85',
    price: 679,
    description: 'A modern signet with a polished horizon.',
    material: '18k recycled gold',
    stock: 4,
  ),
  Product(
    id: 8,
    name: 'Mira Cuff',
    category: 'Bracelets',
    image:
        'https://images.unsplash.com/photo-1619119069152-a2b331eb?w=900&q=85',
    price: 459,
    description: 'An open cuff with a soft architectural curve.',
    material: 'Gold vermeil',
    stock: 9,
  ),
  Product(
    id: 9,
    name: 'Aster Charm',
    category: 'Charms',
    image:
        'https://images.unsplash.com/photo-1602173574767-37ac01994b2a?w=900&q=85',
    price: 189,
    description: 'A small constellation to carry close.',
    material: '14k gold, white sapphire',
    stock: 18,
  ),
  Product(
    id: 10,
    name: 'Orion Chain',
    category: 'Necklaces',
    image:
        'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=900&q=85',
    price: 529,
    description: 'A fluid chain with a celestial glint.',
    material: 'Gold vermeil, lab-grown sapphire',
    stock: 11,
  ),
  Product(
    id: 11,
    name: 'Serein Drop',
    category: 'Earrings',
    image:
        'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=900&q=85',
    price: 339,
    description: 'A single drop of light, made to move.',
    material: 'Recycled silver, freshwater pearl',
    stock: 10,
  ),
  Product(
    id: 12,
    name: 'Vela Stack Ring',
    category: 'Rings',
    image:
        'https://images.unsplash.com/photo-1603561596112-db8d2a5b4a4b?w=900&q=85',
    price: 429,
    description: 'A slim stacker with a warm golden line.',
    material: '14k recycled gold',
    stock: 15,
  ),
];

class CatalogApi {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8003',
  );

  Future<List<Product>> fetchProducts() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/products'))
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw Exception('Catalogue request failed: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> createOrder({
    required String customerName,
    required String customerEmail,
    required List<Product> items,
    String? accessToken,
  }) async {
    final quantities = <int, int>{};
    for (final item in items) {
      quantities.update(item.id, (quantity) => quantity + 1, ifAbsent: () => 1);
    }
    final headers = {'Content-Type': 'application/json'};
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    final response = await http.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: headers,
      body: jsonEncode({
        'customer_name': customerName,
        'customer_email': customerEmail,
        'items': quantities.entries
            .map((entry) => {'product_id': entry.key, 'quantity': entry.value})
            .toList(),
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Order request failed: ${response.statusCode}');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as int;
  }

  Future<String> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    if (response.statusCode != 201) throw Exception('Registration failed');
    return (jsonDecode(response.body) as Map<String, dynamic>)['access_token']
        as String;
  }

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/customer-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode != 200) throw Exception('Login failed');
    return (jsonDecode(response.body) as Map<String, dynamic>)['access_token']
        as String;
  }

  Future<String> adminLogin(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode != 200) throw Exception('Admin login failed');
    return (jsonDecode(response.body) as Map<String, dynamic>)['access_token']
        as String;
  }

  Future<Map<String, dynamic>> createPaymentSession(int orderId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/payments/create-session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'order_id': orderId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Payment session failed');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

class WebsiteShell extends StatefulWidget {
  const WebsiteShell({super.key});

  @override
  State<WebsiteShell> createState() => _WebsiteShellState();
}

class _WebsiteShellState extends State<WebsiteShell> {
  static const pageNames = ['Home', 'Collection', 'Our Story', 'Care Guide'];
  int selectedIndex = 0;
  List<Product> catalogue = products;
  String? customerToken;
  String? customerEmail;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadCatalogue();
  }

  Future<void> _loadCatalogue() async {
    try {
      final remoteProducts = await CatalogApi().fetchProducts();
      if (mounted && remoteProducts.isNotEmpty) {
        setState(() => catalogue = remoteProducts);
      }
    } catch (_) {
      // Keep the bundled catalogue available when the API is offline.
    }
  }

  final cart = <Product>[];
  final favourites = <String>{};

  void addToCart(Product product) {
    setState(() => cart.add(product));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to your bag.')),
    );
  }

  void toggleFavourite(Product product) {
    setState(() {
      if (!favourites.add(product.name)) {
        favourites.remove(product.name);
      }
    });
  }

  void showProduct(Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F4F0),
      builder: (context) => _ProductDetails(
        product: product,
        isFavourite: favourites.contains(product.name),
        onFavourite: () => toggleFavourite(product),
        onAdd: () {
          Navigator.pop(context);
          addToCart(product);
        },
      ),
    );
  }

  void showCart() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F4F0),
      builder: (context) => _CartSheet(
        items: cart,
        onRemove: (product) => setState(() => cart.remove(product)),
        onCheckout: () {
          Navigator.pop(context);
          _showOrderDialog();
        },
      ),
    );
  }

  void showAccount() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F4F0),
      builder: (context) => _AccountSheet(
        signedInEmail: customerEmail,
        signedInAdmin: isAdmin,
        onAuthenticated: (token, email) => setState(() {
          customerToken = token;
          customerEmail = email;
          isAdmin = false;
        }),
        onAdminAuthenticated: (token, email) => setState(() {
          customerToken = token;
          customerEmail = email;
          isAdmin = true;
        }),
        onOpenAdmin: () {
          Navigator.pop(context);
          setState(() => selectedIndex = 4);
        },
        onLogout: () => setState(() {
          customerToken = null;
          customerEmail = null;
          isAdmin = false;
        }),
      ),
    );
  }

  void _showOrderDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request your order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Our studio will contact you to confirm availability and payment.'),
            const SizedBox(height: 16),
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Your name')),
            TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email address')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields.')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              try {
                final orderId = await CatalogApi().createOrder(
                  customerName: nameController.text.trim(),
                  customerEmail: emailController.text.trim(),
                  items: cart,
                  accessToken: customerToken,
                );
                final payment =
                    await CatalogApi().createPaymentSession(orderId);
                if (!mounted) return;
                setState(cart.clear);
                _showPaymentResult(orderId, payment);
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'The order service is unavailable. Please try again.')));
              }
            },
            child: const Text('Send request'),
          ),
        ],
      ),
    );
  }

  void _showPaymentResult(int orderId, Map<String, dynamic> payment) {
    final mode = payment['mode'] as String? ?? 'demo';
    final checkoutUrl = payment['checkout_url'] as String?;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          mode == 'stripe' ? Icons.lock_outline : Icons.check_circle_outline,
          color: const Color(0xFF9B4D5C),
          size: 36,
        ),
        title: Text(mode == 'stripe'
            ? 'Secure payment ready'
            : 'Demo payment confirmed'),
        content: Text(
          mode == 'stripe'
              ? 'Order #$orderId is ready. Continue to the secure Stripe checkout page.'
              : 'Order #$orderId is recorded in development payment mode. Configure Stripe for live payments.',
        ),
        actions: [
          if (checkoutUrl != null)
            FilledButton.icon(
              onPressed: () async {
                final launched = await launchUrl(Uri.parse(checkoutUrl),
                    mode: LaunchMode.externalApplication);
                if (launched && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label:
                  Text(mode == 'stripe' ? 'OPEN PAYMENT' : 'OPEN DEMO PAYMENT'),
            ),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 1000;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              selectedIndex: selectedIndex,
              onSelect: (index) => setState(() => selectedIndex = index),
              cartCount: cart.length,
              onCart: showCart,
              onAccount: showAccount,
              signedIn: customerToken != null,
              accountEmail: customerEmail,
              isAdmin: isAdmin,
              onSearch: () => showSearch<void>(
                context: context,
                delegate: _ProductSearchDelegate(
                  items: catalogue,
                  onOpen: showProduct,
                  onAdd: addToCart,
                ),
              ),
            ),
            Expanded(child: _pageForIndex(selectedIndex)),
          ],
        ),
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: selectedIndex > 3 ? 0 : selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => selectedIndex = index),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.diamond_outlined),
                    selectedIcon: Icon(Icons.diamond),
                    label: 'Collection'),
                NavigationDestination(
                    icon: Icon(Icons.auto_awesome_outlined),
                    selectedIcon: Icon(Icons.auto_awesome),
                    label: 'Story'),
                NavigationDestination(
                    icon: Icon(Icons.spa_outlined),
                    selectedIcon: Icon(Icons.spa),
                    label: 'Care'),
              ],
            )
          : null,
    );
  }

  Widget _pageForIndex(int index) {
    switch (index) {
      case 1:
        return _CollectionPage(
          favourites: favourites,
          items: catalogue,
          onFavourite: toggleFavourite,
          onOpen: showProduct,
          onAdd: addToCart,
        );
      case 2:
        return const _StoryPage();
      case 3:
        return const _CarePage();
      case 4:
        return AdminDashboardPage(token: customerToken!);
      default:
        return _HomePage(
          favourites: favourites,
          items: catalogue,
          onFavourite: toggleFavourite,
          onOpen: showProduct,
          onAdd: addToCart,
        );
    }
  }
}

class _Header extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final int cartCount;
  final VoidCallback onCart;
  final VoidCallback onSearch;
  final VoidCallback onAccount;
  final bool signedIn;
  final String? accountEmail;
  final bool isAdmin;

  const _Header({
    required this.selectedIndex,
    required this.onSelect,
    required this.cartCount,
    required this.onCart,
    required this.onSearch,
    required this.onAccount,
    required this.signedIn,
    required this.accountEmail,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 1000;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Row(
        children: [
          const Text(
            'AURELIA',
            style: TextStyle(
              color: Color(0xFF272426),
              fontSize: 21,
              fontWeight: FontWeight.bold,
              letterSpacing: 4.6,
            ),
          ),
          if (!isMobile) ...[
            const Spacer(),
            for (var index = 0;
                index < _WebsiteShellState.pageNames.length;
                index++)
              _NavLink(
                label: _WebsiteShellState.pageNames[index],
                selected: selectedIndex == index,
                onTap: () => onSelect(index),
              ),
            const SizedBox(width: 22),
          ] else
            const Spacer(),
          IconButton(
            onPressed: onSearch,
            tooltip: 'Search collection',
            icon: const Icon(Icons.search),
          ),
          if (signedIn)
            InkWell(
              onTap: onAccount,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D7D6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                        isAdmin
                            ? Icons.admin_panel_settings_outlined
                            : Icons.verified_user_outlined,
                        size: 16,
                        color: const Color(0xFF9B4D5C)),
                    if (!isMobile && accountEmail != null) ...[
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          accountEmail!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFF9B4D5C),
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            IconButton(
              onPressed: onAccount,
              tooltip: 'Account login or registration',
              icon: const Icon(Icons.person_outline),
            ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onCart,
                tooltip: 'Open shopping bag',
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 2,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF9B4D5C),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavLink(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 22),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor:
              selected ? const Color(0xFF9B4D5C) : const Color(0xFF746B6D),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  final List<Product> items;
  final Set<String> favourites;
  final ValueChanged<Product> onFavourite;
  final ValueChanged<Product> onOpen;
  final ValueChanged<Product> onAdd;

  const _HomePage({
    required this.items,
    required this.favourites,
    required this.onFavourite,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _HeroBanner()),
        const SliverToBoxAdapter(child: _CollectionHeading()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 42),
          sliver: _ProductGrid(
            items: items,
            favourites: favourites,
            onFavourite: onFavourite,
            onOpen: onOpen,
            onAdd: onAdd,
          ),
        ),
      ],
    );
  }
}

class _CollectionPage extends StatefulWidget {
  final List<Product> items;
  final Set<String> favourites;
  final ValueChanged<Product> onFavourite;
  final ValueChanged<Product> onOpen;
  final ValueChanged<Product> onAdd;

  const _CollectionPage({
    required this.items,
    required this.favourites,
    required this.onFavourite,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  State<_CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<_CollectionPage> {
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      ...widget.items.map((item) => item.category).toSet()
    ];
    final visibleItems = selectedCategory == 'All'
        ? widget.items
        : widget.items
            .where((item) => item.category == selectedCategory)
            .toList();
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: _PageIntro(
            eyebrow: 'THE COLLECTION',
            title: 'Everyday icons,\nconsidered closely.',
            body:
                'Explore the Aurelia edit: quiet forms, tactile finishes, and pieces made to become part of your daily rhythm.',
          ),
        ),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => selectedCategory = category),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 42),
          sliver: _ProductGrid(
            items: visibleItems,
            favourites: widget.favourites,
            onFavourite: widget.onFavourite,
            onOpen: widget.onOpen,
            onAdd: widget.onAdd,
          ),
        ),
      ],
    );
  }
}

class _StoryPage extends StatelessWidget {
  const _StoryPage();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 28, 24, 48),
      child: _PageIntro(
        eyebrow: 'OUR STORY',
        title: 'Jewellery with\na quieter voice.',
        body:
            'Aurelia began with a simple idea: the most memorable pieces do not need to announce themselves. They catch the light, settle into your life, and stay with you.',
        extra: _StoryDetails(),
      ),
    );
  }
}

class _CarePage extends StatelessWidget {
  const _CarePage();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 28, 24, 48),
      child: _PageIntro(
        eyebrow: 'CARE GUIDE',
        title: 'Keep the light\nfor longer.',
        body:
            'A little care keeps your favourite pieces beautiful. Store each piece separately, keep it away from moisture, and polish gently with a soft cloth.',
        extra: _CareDetails(),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<Product> items;
  final Set<String> favourites;
  final ValueChanged<Product> onFavourite;
  final ValueChanged<Product> onOpen;
  final ValueChanged<Product> onAdd;

  const _ProductGrid({
    required this.items,
    required this.favourites,
    required this.onFavourite,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final columns = width >= 1000
            ? 4
            : width >= 620
                ? 3
                : 2;
        return SliverGrid.builder(
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 22,
            crossAxisSpacing: 16,
            childAspectRatio: width < 420 ? 0.66 : 0.72,
          ),
          itemBuilder: (context, index) => ProductCard(
            product: items[index],
            isFavourite: favourites.contains(items[index].name),
            onFavourite: () => onFavourite(items[index]),
            onOpen: () => onOpen(items[index]),
            onAdd: () => onAdd(items[index]),
          ),
        );
      },
    );
  }
}

class _CollectionHeading extends StatelessWidget {
  const _CollectionHeading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 34, 24, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THE COLLECTION',
                  style: TextStyle(
                      color: Color(0xFF9B4D5C),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.2)),
              SizedBox(height: 8),
              Text('Pieces to keep',
                  style: TextStyle(
                      color: Color(0xFF272426),
                      fontSize: 27,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          Text('04 EDITIONS',
              style: TextStyle(
                  color: Color(0xFF746B6D), fontSize: 11, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: const Color(0xFFE9D9D3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=1400&q=85',
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.2),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'THE ART OF\nSUBTLE RADIANCE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      height: 1.08,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1),
                ),
                SizedBox(height: 12),
                Text('Considered forms. Lasting light.',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final Widget? extra;

  const _PageIntro(
      {required this.eyebrow,
      required this.title,
      required this.body,
      this.extra});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow,
                  style: const TextStyle(
                      color: Color(0xFF9B4D5C),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.2)),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      color: Color(0xFF272426),
                      fontSize: 34,
                      height: 1.08,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Text(body,
                    style: const TextStyle(
                        color: Color(0xFF746B6D), fontSize: 15, height: 1.6)),
              ),
              if (extra != null) ...[const SizedBox(height: 34), extra!],
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryDetails extends StatelessWidget {
  const _StoryDetails();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _InfoTile(
            number: '01',
            title: 'Thoughtful forms',
            body: 'Designed slowly, with a focus on proportion and touch.'),
        _InfoTile(
            number: '02',
            title: 'Lasting materials',
            body: 'Pieces made to be worn, lived in, and remembered.'),
        _InfoTile(
            number: '03',
            title: 'Quiet confidence',
            body: 'A point of view that leaves room for yours.'),
      ],
    );
  }
}

class _CareDetails extends StatelessWidget {
  const _CareDetails();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _InfoTile(
            number: '01',
            title: 'Store separately',
            body:
                'Keep pieces in their pouch or a lined box to avoid scratches.'),
        SizedBox(height: 12),
        _InfoTile(
            number: '02',
            title: 'Avoid moisture',
            body:
                'Remove jewellery before swimming, showering, or applying perfume.'),
        SizedBox(height: 12),
        _InfoTile(
            number: '03',
            title: 'Polish gently',
            body:
                'Use a soft, dry cloth and light strokes to restore the shine.'),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _InfoTile(
      {required this.number, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFFEDE4DF),
          borderRadius: BorderRadius.circular(3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number,
              style: const TextStyle(
                  color: Color(0xFF9B4D5C),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF272426),
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(
                  color: Color(0xFF746B6D), fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavourite;
  final VoidCallback onFavourite;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  const ProductCard({
    required this.product,
    required this.isFavourite,
    required this.onFavourite,
    required this.onOpen,
    required this.onAdd,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Image.network(
                      product.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : Container(
                                  color: const Color(0xFFE8E0DA),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Color(0xFF9B4D5C)),
                                  ),
                                ),
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFE8E0DA),
                        child: const Center(
                            child: Icon(Icons.photo_outlined,
                                color: Color(0xFF9B4D5C), size: 28)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filledTonal(
                    onPressed: onFavourite,
                    tooltip: isFavourite
                        ? 'Remove from favourites'
                        : 'Save to favourites',
                    icon: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border),
                    color: const Color(0xFF9B4D5C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Text(product.category.toUpperCase(),
              style: const TextStyle(
                  color: Color(0xFF9B4D5C),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Text(product.name,
                      style: const TextStyle(
                          color: Color(0xFF272426),
                          fontSize: 17,
                          fontWeight: FontWeight.w600))),
              Text('\$${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Color(0xFF272426),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(product.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF746B6D), fontSize: 12)),
              ),
              IconButton(
                onPressed: onAdd,
                tooltip: 'Add to bag',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_shopping_cart_outlined, size: 19),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductDetails extends StatelessWidget {
  final Product product;
  final bool isFavourite;
  final VoidCallback onFavourite;
  final VoidCallback onAdd;

  const _ProductDetails({
    required this.product,
    required this.isFavourite,
    required this.onFavourite,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(product.category.toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFF9B4D5C),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.7)),
                IconButton(
                    onPressed: onFavourite,
                    icon: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border),
                    color: const Color(0xFF9B4D5C)),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AspectRatio(
                aspectRatio: 1.25,
                child: Image.network(product.image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Text(product.name,
                        style: const TextStyle(
                            color: Color(0xFF272426),
                            fontSize: 28,
                            fontWeight: FontWeight.w600))),
                Text('\$${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Color(0xFF272426),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Text(product.description,
                style: const TextStyle(color: Color(0xFF746B6D), fontSize: 15)),
            const SizedBox(height: 18),
            Text('MATERIAL',
                style: const TextStyle(
                    color: Color(0xFF9B4D5C),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Text(product.material,
                style: const TextStyle(color: Color(0xFF272426), fontSize: 14)),
            const SizedBox(height: 8),
            Text('${product.stock} available in studio',
                style: const TextStyle(color: Color(0xFF746B6D), fontSize: 12)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('ADD TO BAG'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSheet extends StatelessWidget {
  final List<Product> items;
  final ValueChanged<Product> onRemove;
  final VoidCallback onCheckout;

  const _CartSheet(
      {required this.items, required this.onRemove, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) => sum + item.price);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your bag',
                    style: TextStyle(
                        color: Color(0xFF272426),
                        fontSize: 26,
                        fontWeight: FontWeight.w600)),
                Text('${items.length} item${items.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: Color(0xFF746B6D), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 18),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                    child:
                        Text('Your bag is waiting for something beautiful.')),
              )
            else ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 20),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Row(
                      children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Image.network(item.image,
                                width: 58, height: 58, fit: BoxFit.cover)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))),
                        Text('\$${item.price.toStringAsFixed(0)}'),
                        IconButton(
                            onPressed: () => onRemove(item),
                            icon: const Icon(Icons.close, size: 18)),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 28),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total'),
                Text('\$${total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold))
              ]),
              const SizedBox(height: 14),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: onCheckout,
                      child: const Text('REQUEST ORDER'))),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductSearchDelegate extends SearchDelegate<void> {
  final List<Product> items;
  final ValueChanged<Product> onOpen;
  final ValueChanged<Product> onAdd;

  _ProductSearchDelegate(
      {required this.items, required this.onOpen, required this.onAdd});

  @override
  List<Widget>? buildActions(BuildContext context) =>
      [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back));

  @override
  Widget buildResults(BuildContext context) => _buildResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults();

  Widget _buildResults() {
    final matches = items.where((product) {
      final text = '${product.name} ${product.category}'.toLowerCase();
      return text.contains(query.toLowerCase());
    }).toList();
    if (matches.isEmpty) return const Center(child: Text('No pieces found.'));
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final product = matches[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          leading: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.network(product.image,
                  width: 56, height: 56, fit: BoxFit.cover)),
          title: Text(product.name),
          subtitle: Text(product.category),
          trailing: IconButton(
              onPressed: () => onAdd(product),
              icon: const Icon(Icons.add_shopping_cart_outlined)),
          onTap: () {
            close(context, null);
            onOpen(product);
          },
        );
      },
    );
  }
}

class _AccountSheet extends StatefulWidget {
  final String? signedInEmail;
  final bool signedInAdmin;
  final void Function(String token, String email) onAuthenticated;
  final void Function(String token, String email) onAdminAuthenticated;
  final VoidCallback onOpenAdmin;
  final VoidCallback onLogout;

  const _AccountSheet({
    required this.signedInEmail,
    required this.signedInAdmin,
    required this.onAuthenticated,
    required this.onAdminAuthenticated,
    required this.onOpenAdmin,
    required this.onLogout,
  });

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isRegistering = false;
  bool isAdminLogin = false;
  bool submitting = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      final token = isAdminLogin
          ? await CatalogApi()
              .adminLogin(emailController.text.trim(), passwordController.text)
          : isRegistering
              ? await CatalogApi().register(nameController.text.trim(),
                  emailController.text.trim(), passwordController.text)
              : await CatalogApi()
                  .login(emailController.text.trim(), passwordController.text);
      if (!mounted) {
        return;
      }
      if (isAdminLogin) {
        widget.onAdminAuthenticated(token, emailController.text.trim());
      } else {
        widget.onAuthenticated(token, emailController.text.trim());
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Account connected.')));
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Please check your details and try again.');
      }
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.signedInEmail != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You are signed in',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(widget.signedInEmail!,
                  style: const TextStyle(color: Color(0xFF746B6D))),
              const SizedBox(height: 20),
              if (widget.signedInAdmin)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onOpenAdmin,
                    icon: const Icon(Icons.dashboard_outlined),
                    label: const Text('OPEN ADMIN DASHBOARD'),
                  ),
                ),
              if (widget.signedInAdmin) const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    widget.onLogout();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('SIGN OUT'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                isAdminLogin
                    ? 'Admin sign in'
                    : isRegistering
                        ? 'Create your account'
                        : 'Welcome back',
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
                isAdminLogin
                    ? 'Manage the Aurelia catalogue and studio operations.'
                    : isRegistering
                        ? 'Save your details for a smoother Aurelia order.'
                        : 'Sign in to keep your orders connected.',
                style: const TextStyle(color: Color(0xFF746B6D))),
            const SizedBox(height: 18),
            if (isRegistering && !isAdminLogin)
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password (8+ characters)')),
            if (error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(error!,
                      style: const TextStyle(color: Color(0xFF9B4D5C)))),
            const SizedBox(height: 18),
            SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: submitting ? null : submit,
                    child: Text(submitting
                        ? 'PLEASE WAIT'
                        : isAdminLogin
                            ? 'ADMIN SIGN IN'
                            : isRegistering
                                ? 'CREATE ACCOUNT'
                                : 'SIGN IN'))),
            if (!isAdminLogin)
              Center(
                  child: TextButton(
                      onPressed: () =>
                          setState(() => isRegistering = !isRegistering),
                      child: Text(isRegistering
                          ? 'Already have an account? Sign in'
                          : 'New here? Create an account'))),
            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  isAdminLogin = !isAdminLogin;
                  isRegistering = false;
                }),
                child: Text(isAdminLogin
                    ? 'Customer sign in'
                    : 'Administrator sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
