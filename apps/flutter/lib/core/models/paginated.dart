class Paginated<T> {
  final int? nextPage;
  final int count;
  final List<T> results;

  const Paginated({
    required this.nextPage,
    required this.count,
    required this.results,
  });
}
