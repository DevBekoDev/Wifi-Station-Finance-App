import 'package:cloud_firestore/cloud_firestore.dart';

class AiCenterInfo {
  const AiCenterInfo({
    required this.id,
    required this.name,
    required this.location,
    required this.managerName,
    required this.managerEmail,
    required this.isActive,
    required this.totalCards,
    required this.monthlyRevenue,
    required this.monthlyExpenses,
    required this.savedProfit,
  });

  final String id;
  final String name;
  final String location;
  final String managerName;
  final String managerEmail;
  final bool isActive;
  final int totalCards;
  final double monthlyRevenue;
  final double monthlyExpenses;
  final double savedProfit;

  String toAiText() {
    return '- Name: $name | Location: $location | Manager: $managerName | Email: $managerEmail | ID: $id | Active: $isActive | Total cards: $totalCards';
  }
}

class AiUserInfo {
  const AiUserInfo({
    required this.id,
    required this.email,
    required this.role,
    required this.centerId,
  });

  final String id;
  final String email;
  final String role;
  final String centerId;

  bool get hasCenter => centerId.trim().isNotEmpty;

  String toAiText() {
    return '- Email: $email | Role: $role | Center ID: ${hasCenter ? centerId : "none"}';
  }
}

class UserSummary {
  const UserSummary({
    required this.totalUsers,
    required this.totalAdmins,
    required this.totalManagers,
    required this.usersWithCenter,
    required this.usersWithoutCenter,
  });

  final int totalUsers;
  final int totalAdmins;
  final int totalManagers;
  final int usersWithCenter;
  final int usersWithoutCenter;

  String toAiText({
    required String title,
  }) {
    return '''
$title:
- Total users: $totalUsers
- Admin users: $totalAdmins
- Manager users: $totalManagers
- Users linked to a center: $usersWithCenter
- Users without center: $usersWithoutCenter
''';
  }
}

class FinanceSummary {
  const FinanceSummary({
    required this.totalSales,
    required this.totalExpenses,
    required this.cardsSold,
    required this.salesCount,
    required this.expensesCount,
  });

  final double totalSales;
  final double totalExpenses;
  final int cardsSold;
  final int salesCount;
  final int expensesCount;

  double get profit => totalSales - totalExpenses;

  String get profitStatus {
    if (profit > 0) return 'profit';
    if (profit < 0) return 'loss';
    return 'break-even';
  }

  String toAiText({
    required String title,
  }) {
    return '''
$title:
- Total sales: $totalSales
- Total expenses: $totalExpenses
- Profit: $profit
- Profit status: $profitStatus
- Cards sold: $cardsSold
- Sales records count: $salesCount
- Expenses records count: $expensesCount
''';
  }
}

class FinanceAiContextService {
  FinanceAiContextService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String centersCollection = 'centers';
  static const String salesCollection = 'sales';
  static const String expensesCollection = 'expenses';
  static const String usersCollection = 'users';

  static const String centerIdField = 'centerId';
  static const String createdAtField = 'createdAt';

  static const String saleAmountField = 'totalAmount';
  static const String quantityField = 'quantity';

  static const String expenseAmountField = 'amount';

  static const String centerNameField = 'name';
  static const String centerLocationField = 'location';
  static const String managerNameField = 'managerName';
  static const String managerEmailField = 'managerEmail';
  static const String isActiveField = 'isActive';
  static const String totalCardsField = 'totalCards';
  static const String monthlyRevenueField = 'monthlyRevenue';
  static const String monthlyExpensesField = 'monthlyExpenses';
  static const String savedProfitField = 'profit';

  static const String userEmailField = 'email';
  static const String userRoleField = 'role';
  static const String userCenterIdField = 'centerId';

  Future<String?> tryAnswerDirectly({
    required String question,
    required bool isAdmin,
    String? managerCenterId,
  }) async {
    final text = _normalizeText(question);

    final isSimpleFinanceQuestion =
        text.contains('total sales') ||
        text.contains('sales total') ||
        text.contains('total expenses') ||
        text.contains('expenses total') ||
        text.contains('profit') ||
        text.contains('cards sold') ||
        text.contains('total cards');

    final asksWhyOrExplain =
        text.contains('why') ||
        text.contains('explain') ||
        text.contains('analyze') ||
        text.contains('analyse') ||
        text.contains('compare') ||
        text.contains('report') ||
        text.contains('improve') ||
        text.contains('advice');

    if (!isSimpleFinanceQuestion || asksWhyOrExplain) {
      return null;
    }

    if (isAdmin) {
      final selectedCenter = await findCenterFromQuestion(question);

      if (selectedCenter != null) {
        final summary = await getSummary(centerId: selectedCenter.id);

        return _formatDirectFinanceAnswer(
          title: 'Finance summary for ${selectedCenter.name}',
          summary: summary,
          question: text,
        );
      }

      final summary = await getAdminSummary();

      return _formatDirectFinanceAnswer(
        title: 'All centers finance summary',
        summary: summary,
        question: text,
      );
    }

    if (managerCenterId == null || managerCenterId.trim().isEmpty) {
      return 'No center ID found for this manager user.';
    }

    final managerCenter = await getCenterById(managerCenterId);

    final mentionsAnotherCenter = _managerQuestionMentionsAnotherCenter(
      question: question,
      managerCenter: managerCenter,
      managerCenterId: managerCenterId,
    );

    if (mentionsAnotherCenter) {
      return 'You do not have access to that center data. As a manager, I can only answer questions about your assigned center.';
    }

    final summary = await getSummary(centerId: managerCenterId);

    return _formatDirectFinanceAnswer(
      title: 'Finance summary for ${managerCenter?.name ?? "your center"}',
      summary: summary,
      question: text,
    );
  }

  Future<String> buildAiFinanceContext({
    required String centerId,
    bool includeUserContext = false,
  }) async {
    if (centerId.trim().isEmpty) {
      return '''
Finance data status:
- No centerId was provided.
- The assistant cannot read center finance data.
''';
    }

    final centerInfo = await getCenterById(centerId);

    final now = DateTime.now();

    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);

    final last90DaysStart = now.subtract(const Duration(days: 90));

    final summaries = await Future.wait([
      getSummary(centerId: centerId),
      getSummary(
        centerId: centerId,
        startDate: last90DaysStart,
        endDate: now.add(const Duration(days: 1)),
      ),
      getSummary(
        centerId: centerId,
        startDate: monthStart,
        endDate: nextMonthStart,
      ),
      getSummary(
        centerId: centerId,
        startDate: todayStart,
        endDate: tomorrowStart,
      ),
    ]);

    final allTimeSummary = summaries[0];
    final last90DaysSummary = summaries[1];
    final monthSummary = summaries[2];
    final todaySummary = summaries[3];

    final centerText = centerInfo == null
        ? '''
Center details:
- Center ID: $centerId
- Center document was not found in centers collection.
'''
        : '''
Center details:
- Name: ${centerInfo.name}
- Location: ${centerInfo.location}
- Manager: ${centerInfo.managerName}
- Manager email: ${centerInfo.managerEmail}
- Center ID: ${centerInfo.id}
- Active: ${centerInfo.isActive}
- Total cards in center record: ${centerInfo.totalCards}
- Saved monthly revenue in center record: ${centerInfo.monthlyRevenue}
- Saved monthly expenses in center record: ${centerInfo.monthlyExpenses}
- Saved profit in center record: ${centerInfo.savedProfit}
''';

    String userContext = '''
User context:
- User details are not included in this context.
''';

    if (includeUserContext) {
      final centerUserSummary = await getUserSummary(centerId: centerId);
      final centerUsersText = await buildUsersText(
        centerId: centerId,
        limit: 20,
      );

      userContext = '''
User context for this center:

${centerUserSummary.toAiText(title: 'Center users summary')}

Users linked to this center:
$centerUsersText
''';
    }

    return '''
Real WSFM finance context:

Scope:
Specific center

$centerText

$userContext

${allTimeSummary.toAiText(title: 'All time center summary')}

${last90DaysSummary.toAiText(title: 'Last 90 days center summary')}

${monthSummary.toAiText(title: 'This month center summary')}

${todaySummary.toAiText(title: 'Today center summary')}

AI rules:
- Use only the finance numbers above.
- Do not invent missing sales, expenses, profit, cards, managers, users, or center data.
- Profit formula: profit = total sales - total expenses.
- If the user asks about this center generally, use All time center summary unless they specify today, this month, or another period.
- If the user asks about recent activity, use Last 90 days center summary.
- If the user asks about today, use Today center summary.
- If the user asks about this month, use This month center summary.
''';
  }

  Future<String> buildAdminFinanceContext() async {
    final now = DateTime.now();

    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);

    final last90DaysStart = now.subtract(const Duration(days: 90));

    final summaries = await Future.wait([
      getAdminSummary(),
      getAdminSummary(
        startDate: last90DaysStart,
        endDate: now.add(const Duration(days: 1)),
      ),
      getAdminSummary(
        startDate: monthStart,
        endDate: nextMonthStart,
      ),
      getAdminSummary(
        startDate: todayStart,
        endDate: tomorrowStart,
      ),
    ]);

    final allTimeSummary = summaries[0];
    final last90DaysSummary = summaries[1];
    final monthSummary = summaries[2];
    final todaySummary = summaries[3];

    final adminUserSummary = await getUserSummary();
    final adminUsersText = await buildUsersText(limit: 40);

    return '''
Real WSFM admin finance context:

Scope:
All centers

User context:

${adminUserSummary.toAiText(title: 'All users summary')}

Users list:
$adminUsersText

${allTimeSummary.toAiText(title: 'All time all centers summary')}

${last90DaysSummary.toAiText(title: 'Last 90 days all centers summary')}

${monthSummary.toAiText(title: 'This month all centers summary')}

${todaySummary.toAiText(title: 'Today all centers summary')}

Note:
- Today and this month may be 0 if there are no records in the current date/month.
- Older records are included in All time and Last 90 days summaries.

AI rules:
- Use only the finance and user numbers above.
- Do not invent missing sales, expenses, profit, cards, users, emails, roles, or center data.
- Profit formula: profit = total sales - total expenses.
- If the user asks for all centers summary and does not mention today, this month, or a specific date, use All time all centers summary.
- If the user asks about recent activity, use Last 90 days all centers summary.
- If the user asks about today, use Today all centers summary.
- If the user asks about this month, use This month all centers summary.
- If the user asks about users, managers, or admins, use User context.
''';
  }

  Future<String> buildEachCenterFinanceContext({
    int limit = 20,
  }) async {
    final centers = await getCenters();

    if (centers.isEmpty) {
      return '''
Real WSFM finance context:

Scope:
Each center individual summary

No centers found.

AI rules:
- Tell the user there are no centers available.
''';
    }

    final shownCenters = centers.take(limit).toList();
    final buffer = StringBuffer();

    buffer.writeln('Real WSFM finance context:');
    buffer.writeln('');
    buffer.writeln('Scope:');
    buffer.writeln('Each center individual summary');
    buffer.writeln('');

    for (final center in shownCenters) {
      final summary = await getSummary(centerId: center.id);
      final userSummary = await getUserSummary(centerId: center.id);

      buffer.writeln('Center: ${center.name}');
      buffer.writeln('- Center ID: ${center.id}');
      buffer.writeln('- Location: ${center.location}');
      buffer.writeln('- Manager: ${center.managerName}');
      buffer.writeln('- Manager email: ${center.managerEmail}');
      buffer.writeln('- Active: ${center.isActive}');
      buffer.writeln('- Total cards in center record: ${center.totalCards}');
      buffer.writeln('- Total sales: ${summary.totalSales}');
      buffer.writeln('- Total expenses: ${summary.totalExpenses}');
      buffer.writeln('- Profit: ${summary.profit}');
      buffer.writeln('- Profit status: ${summary.profitStatus}');
      buffer.writeln('- Cards sold: ${summary.cardsSold}');
      buffer.writeln('- Sales records count: ${summary.salesCount}');
      buffer.writeln('- Expenses records count: ${summary.expensesCount}');
      buffer.writeln('- Users linked to this center: ${userSummary.usersWithCenter}');
      buffer.writeln('');
    }

    final hiddenCount = centers.length - limit;

    if (hiddenCount > 0) {
      buffer.writeln(
        '$hiddenCount more centers were not included to reduce AI cost.',
      );
      buffer.writeln('');
    }

    buffer.writeln('AI rules:');
    buffer.writeln('- The user asked for data for each center.');
    buffer.writeln('- Answer with one clear section per center.');
    buffer.writeln('- Include every center provided in the context.');
    buffer.writeln('- For each center, include manager, sales, expenses, profit, cards sold, and records count.');
    buffer.writeln('- Do not stop after the first center.');
    buffer.writeln('- Do not invent missing values.');
    buffer.writeln('- Use plain text only.');
    buffer.writeln('- A short answer is okay, but it must be complete.');

    return buffer.toString();
  }

  Future<String> buildSmartAdminFinanceContext({
    required String question,
  }) async {
    final centers = await getCenters();
    final selectedCenter = await findCenterFromQuestion(question);

    if (_isEachCenterQuestion(question)) {
      return buildEachCenterFinanceContext();
    }

    final centersText = centers.isEmpty
        ? 'No centers found.'
        : centers.map((center) => center.toAiText()).join('\n');

    if (selectedCenter != null) {
      final centerContext = await buildAiFinanceContext(
        centerId: selectedCenter.id,
        includeUserContext: true,
      );

      return '''
Real WSFM finance context:

Admin selected a specific center.

Selected center:
- Name: ${selectedCenter.name}
- Location: ${selectedCenter.location}
- Manager: ${selectedCenter.managerName}
- Manager email: ${selectedCenter.managerEmail}
- Center ID: ${selectedCenter.id}
- Active: ${selectedCenter.isActive}
- Total cards in center record: ${selectedCenter.totalCards}

$centerContext

Available centers:
$centersText

AI rules:
- The user asked about a specific center.
- Answer only about the selected center.
- Do not answer using all centers unless the user asks for all centers.
- Use only the numbers in the selected center context.
- Do not invent missing values.
''';
    }

    final allCentersContext = await buildAdminFinanceContext();

    return '''
$allCentersContext

Available centers:
$centersText

AI rules for center questions:
- If the user asks about a specific center but the center name is not clear, ask which center they mean.
- If needed, show the available centers by name, location, manager, email, and ID.
- If the user asks for all centers, use the all centers summary.
''';
  }

  Future<String> buildSmartManagerFinanceContext({
    required String question,
    required String managerCenterId,
  }) async {
    final managerCenter = await getCenterById(managerCenterId);
    final cleanedQuestion = _normalizeText(question);

    final isAskingAllCenters =
        cleanedQuestion.contains('all centers') ||
        cleanedQuestion.contains('all center') ||
        cleanedQuestion.contains('every center') ||
        cleanedQuestion.contains('each center') ||
        cleanedQuestion.contains('per center');

    if (isAskingAllCenters) {
      return '''
Access control context:

The logged-in user is a manager.

Access denied:
- Managers cannot access all centers data.
- Managers can only access their assigned center.

Manager assigned center:
- Center ID: $managerCenterId
- Center name: ${managerCenter?.name ?? 'unknown'}

AI rules:
- Tell the user they do not have access to all centers data.
- Tell them you can only answer questions about their assigned center.
- Do not show admin data.
- Do not invent data.
''';
    }

    final mentionsAnotherCenter = _managerQuestionMentionsAnotherCenter(
      question: question,
      managerCenter: managerCenter,
      managerCenterId: managerCenterId,
    );

    if (mentionsAnotherCenter) {
      return '''
Access control context:

The logged-in user is a manager.

Access denied:
- The user asked about a center that is not clearly their assigned center.
- Managers cannot access other centers data.
- Managers can only access their assigned center.

Manager assigned center:
- Center ID: $managerCenterId
- Center name: ${managerCenter?.name ?? 'unknown'}

AI rules:
- Tell the user they do not have access to that center data.
- Tell them you can only answer questions about their assigned center.
- Do not say the center does not exist.
- Do not reveal whether the requested center exists or not.
- Do not show admin data.
- Do not invent data.
''';
    }

    return buildAiFinanceContext(
      centerId: managerCenterId,
      includeUserContext: false,
    );
  }

  Future<List<AiCenterInfo>> getCenters() async {
    final snapshot = await _firestore.collection(centersCollection).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return AiCenterInfo(
        id: doc.id,
        name: _readString(data[centerNameField], fallback: doc.id),
        location: _readString(data[centerLocationField]),
        managerName: _readString(data[managerNameField]),
        managerEmail: _readString(data[managerEmailField]),
        isActive: data[isActiveField] == true,
        totalCards: _toInt(data[totalCardsField]),
        monthlyRevenue: _toDouble(data[monthlyRevenueField]),
        monthlyExpenses: _toDouble(data[monthlyExpensesField]),
        savedProfit: _toDouble(data[savedProfitField]),
      );
    }).toList();
  }

  Future<AiCenterInfo?> getCenterById(String centerId) async {
    if (centerId.trim().isEmpty) return null;

    final doc =
        await _firestore.collection(centersCollection).doc(centerId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    final data = doc.data()!;

    return AiCenterInfo(
      id: doc.id,
      name: _readString(data[centerNameField], fallback: doc.id),
      location: _readString(data[centerLocationField]),
      managerName: _readString(data[managerNameField]),
      managerEmail: _readString(data[managerEmailField]),
      isActive: data[isActiveField] == true,
      totalCards: _toInt(data[totalCardsField]),
      monthlyRevenue: _toDouble(data[monthlyRevenueField]),
      monthlyExpenses: _toDouble(data[monthlyExpensesField]),
      savedProfit: _toDouble(data[savedProfitField]),
    );
  }

  Future<AiCenterInfo?> findCenterFromQuestion(String question) async {
    final centers = await getCenters();
    final cleanedQuestion = _normalizeText(question);

    for (final center in centers) {
      final searchableValues = [
        center.id,
        center.name,
        center.location,
        center.managerName,
        center.managerEmail,
      ];

      for (final value in searchableValues) {
        final cleanedValue = _normalizeText(value);

        if (cleanedValue.length >= 2 &&
            cleanedQuestion.contains(cleanedValue)) {
          return center;
        }
      }
    }

    return null;
  }

  Future<FinanceSummary> getSummary({
    required String centerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final salesSnapshot = await _salesQuery(
      centerId: centerId,
      startDate: startDate,
      endDate: endDate,
    ).get();

    final expensesSnapshot = await _expensesQuery(
      centerId: centerId,
      startDate: startDate,
      endDate: endDate,
    ).get();

    double totalSales = 0;
    double totalExpenses = 0;
    int cardsSold = 0;

    for (final doc in salesSnapshot.docs) {
      final data = doc.data();

      totalSales += _toDouble(data[saleAmountField]);
      cardsSold += _toInt(data[quantityField]);
    }

    for (final doc in expensesSnapshot.docs) {
      final data = doc.data();

      totalExpenses += _toDouble(data[expenseAmountField]);
    }

    return FinanceSummary(
      totalSales: totalSales,
      totalExpenses: totalExpenses,
      cardsSold: cardsSold,
      salesCount: salesSnapshot.docs.length,
      expensesCount: expensesSnapshot.docs.length,
    );
  }

  Future<FinanceSummary> getAdminSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query<Map<String, dynamic>> salesQuery =
        _firestore.collection(salesCollection);

    Query<Map<String, dynamic>> expensesQuery =
        _firestore.collection(expensesCollection);

    if (startDate != null) {
      salesQuery = salesQuery.where(
        createdAtField,
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );

      expensesQuery = expensesQuery.where(
        createdAtField,
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      salesQuery = salesQuery.where(
        createdAtField,
        isLessThan: Timestamp.fromDate(endDate),
      );

      expensesQuery = expensesQuery.where(
        createdAtField,
        isLessThan: Timestamp.fromDate(endDate),
      );
    }

    final salesSnapshot = await salesQuery.get();
    final expensesSnapshot = await expensesQuery.get();

    double totalSales = 0;
    double totalExpenses = 0;
    int cardsSold = 0;

    for (final doc in salesSnapshot.docs) {
      final data = doc.data();

      totalSales += _toDouble(data[saleAmountField]);
      cardsSold += _toInt(data[quantityField]);
    }

    for (final doc in expensesSnapshot.docs) {
      final data = doc.data();

      totalExpenses += _toDouble(data[expenseAmountField]);
    }

    return FinanceSummary(
      totalSales: totalSales,
      totalExpenses: totalExpenses,
      cardsSold: cardsSold,
      salesCount: salesSnapshot.docs.length,
      expensesCount: expensesSnapshot.docs.length,
    );
  }

  Future<UserSummary> getUserSummary({
    String? centerId,
  }) async {
    final snapshot = await _usersQuery(centerId: centerId).get();

    int totalAdmins = 0;
    int totalManagers = 0;
    int usersWithCenter = 0;
    int usersWithoutCenter = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final role = _readString(data[userRoleField]).toLowerCase();
      final userCenterId = _readString(data[userCenterIdField]);

      if (role == 'admin') {
        totalAdmins++;
      }

      if (role == 'manager') {
        totalManagers++;
      }

      if (userCenterId.isEmpty) {
        usersWithoutCenter++;
      } else {
        usersWithCenter++;
      }
    }

    return UserSummary(
      totalUsers: snapshot.docs.length,
      totalAdmins: totalAdmins,
      totalManagers: totalManagers,
      usersWithCenter: usersWithCenter,
      usersWithoutCenter: usersWithoutCenter,
    );
  }

  Future<List<AiUserInfo>> getUsers({
    String? centerId,
  }) async {
    final snapshot = await _usersQuery(centerId: centerId).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return AiUserInfo(
        id: doc.id,
        email: _readString(data[userEmailField]),
        role: _readString(data[userRoleField]),
        centerId: _readString(data[userCenterIdField]),
      );
    }).toList();
  }

  Future<String> buildUsersText({
    String? centerId,
    int limit = 30,
  }) async {
    final users = await getUsers(centerId: centerId);

    if (users.isEmpty) {
      return 'No users found for this scope.';
    }

    final shownUsers = users.take(limit).map((user) {
      return user.toAiText();
    }).join('\n');

    final hiddenCount = users.length - limit;

    if (hiddenCount > 0) {
      return '''
$shownUsers
- $hiddenCount more users not shown to reduce AI cost.
''';
    }

    return shownUsers;
  }

  Query<Map<String, dynamic>> _salesQuery({
    required String centerId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(salesCollection)
        .where(centerIdField, isEqualTo: centerId);

    if (startDate != null) {
      query = query.where(
        createdAtField,
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        createdAtField,
        isLessThan: Timestamp.fromDate(endDate),
      );
    }

    return query;
  }

  Query<Map<String, dynamic>> _expensesQuery({
    required String centerId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(expensesCollection)
        .where(centerIdField, isEqualTo: centerId);

    if (startDate != null) {
      query = query.where(
        createdAtField,
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        createdAtField,
        isLessThan: Timestamp.fromDate(endDate),
      );
    }

    return query;
  }

  Query<Map<String, dynamic>> _usersQuery({
    String? centerId,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(usersCollection);

    if (centerId != null && centerId.trim().isNotEmpty) {
      query = query.where(
        userCenterIdField,
        isEqualTo: centerId,
      );
    }

    return query;
  }

  bool _isEachCenterQuestion(String question) {
    final cleaned = _normalizeText(question);

    return cleaned.contains('each center') ||
        cleaned.contains('each centre') ||
        cleaned.contains('every center') ||
        cleaned.contains('every centre') ||
        cleaned.contains('per center') ||
        cleaned.contains('per centre') ||
        cleaned.contains('all centers individually') ||
        cleaned.contains('all centres individually') ||
        cleaned.contains('center by center') ||
        cleaned.contains('centre by centre');
  }

  bool _managerQuestionMentionsAnotherCenter({
    required String question,
    required AiCenterInfo? managerCenter,
    required String managerCenterId,
  }) {
    final cleanedQuestion = _normalizeText(question);

    final ownCenterValues = [
      managerCenterId,
      managerCenter?.name ?? '',
      managerCenter?.location ?? '',
      managerCenter?.managerName ?? '',
      managerCenter?.managerEmail ?? '',
    ].map(_normalizeText).where((value) => value.isNotEmpty).toList();

    final mentionsOwnCenter = ownCenterValues.any(
      (value) => cleanedQuestion.contains(value),
    );

    if (mentionsOwnCenter) {
      return false;
    }

    final genericOwnCenterPhrases = [
      'my center',
      'my centre',
      'this center',
      'this centre',
      'our center',
      'our centre',
      'assigned center',
      'assigned centre',
    ];

    final asksOwnCenterGenerically = genericOwnCenterPhrases.any(
      (phrase) => cleanedQuestion.contains(phrase),
    );

    if (asksOwnCenterGenerically) {
      return false;
    }

    final asksForNamedCenter = RegExp(
      r'\b(center|centre)\s+[a-z0-9@._-]{2,}',
    ).hasMatch(cleanedQuestion);

    final asksForCenterAfterForOrOf = RegExp(
      r'\b(for|of|about)\s+(center|centre)\s+[a-z0-9@._-]{2,}',
    ).hasMatch(cleanedQuestion);

    return asksForNamedCenter || asksForCenterAfterForOrOf;
  }

  String _formatDirectFinanceAnswer({
    required String title,
    required FinanceSummary summary,
    required String question,
  }) {
    if (question.contains('total sales') || question.contains('sales total')) {
      return '$title:\n- Total sales: ${summary.totalSales}';
    }

    if (question.contains('total expenses') ||
        question.contains('expenses total')) {
      return '$title:\n- Total expenses: ${summary.totalExpenses}';
    }

    if (question.contains('profit')) {
      return '$title:\n- Profit: ${summary.profit}\n- Status: ${summary.profitStatus}';
    }

    if (question.contains('cards sold') || question.contains('total cards')) {
      return '$title:\n- Cards sold: ${summary.cardsSold}';
    }

    return '''
$title:
- Total sales: ${summary.totalSales}
- Total expenses: ${summary.totalExpenses}
- Profit: ${summary.profit}
- Status: ${summary.profitStatus}
- Cards sold: ${summary.cardsSold}
''';
  }

  String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return fallback;
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9@._-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}