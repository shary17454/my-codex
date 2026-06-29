enum AppCategory {
  cars('cars', 'سيارات'),
  phones('phones', 'جوالات'),
  restaurants('restaurants', 'مطاعم'),
  travel('travel', 'سفر'),
  shopping('shopping', 'تسوق'),
  technology('technology', 'تقنية'),
  devices('devices', 'أجهزة'),
  fashion('fashion', 'أزياء'),
  health('health', 'صحة'),
  education('education', 'تعليم'),
  realEstate('real_estate', 'عقار'),
  other('other', 'أخرى');

  const AppCategory(this.id, this.label);

  final String id;
  final String label;
}
