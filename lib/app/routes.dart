/// Route paths. Screens use these helpers instead of string literals so
/// navigation stays consistent with lib/app/router.dart.
abstract final class Routes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const home = '/home';
  static const createTour = '/create-tour';
  static const join = '/join';
  static const inbox = '/inbox';
  static const settings = '/settings';
  static const diagnostics = '/settings/diagnostics';

  static String joinWithCode(String code) => '$join?code=$code';

  static String tour(String id, {int tab = 0}) =>
      tab == 0 ? '/tour/$id' : '/tour/$id?tab=$tab';
  static String editTour(String id) => '/tour/$id/edit';
  static String tourSettings(String id) => '/tour/$id/settings';
  static String members(String id) => '/tour/$id/members';
  static String newExpense(String id) => '/tour/$id/expenses/new';
  static String expense(String id, String expenseId) =>
      '/tour/$id/expenses/$expenseId';
  static String editExpense(String id, String expenseId) =>
      '/tour/$id/expenses/$expenseId/edit';
  static String balances(String id) => '/tour/$id/balances';
  static String newSettlement(
    String id, {
    String? to,
    String? from,
    int? amount,
    String? currency,
  }) {
    final query = {
      'to': ?to,
      'from': ?from,
      if (amount != null) 'amount': '$amount',
      'currency': ?currency,
    };
    return Uri(path: '/tour/$id/settle', queryParameters: query).toString();
  }

  static String newPlan(String id, {String? day}) =>
      day == null ? '/tour/$id/plan/new' : '/tour/$id/plan/new?day=$day';
  static String editPlan(String id, String planId) =>
      '/tour/$id/plan/$planId/edit';
  static String notes(String id) => '/tour/$id/notes';
  static String newNote(String id) => '/tour/$id/notes/new';
  static String note(String id, String noteId) => '/tour/$id/notes/$noteId';
  static String packing(String id) => '/tour/$id/packing';
  static String activity(String id) => '/tour/$id/activity';
}
