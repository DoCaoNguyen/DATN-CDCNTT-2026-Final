class Product {
  final int id;
  final String name;
  final double price;
  final int sold;
  final String imageUrl;
  final String discount;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.sold,
    required this.imageUrl,
    this.discount = '',
  });
}
