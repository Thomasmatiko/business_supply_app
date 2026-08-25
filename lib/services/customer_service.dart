import '../database/database_helper.dart';
import '../models/customer.dart';

class CustomerService {
  static final CustomerService instance = CustomerService._init();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  CustomerService._init();

  Future<List<Customer>> getCustomers() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'customers',
      orderBy: 'name ASC',
    );

    return result.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Customer.fromMap(result.first);
  }

  Future<int> addCustomer(Customer customer) async {
    final db = await _databaseHelper.database;

    return await db.insert(
      'customers',
      customer.toMap(),
    );
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await _databaseHelper.database;

    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(String id) async {
    final db = await _databaseHelper.database;

    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'customers',
      where: '''
        id LIKE ?
        OR name LIKE ?
        OR phone LIKE ?
        OR email LIKE ?
        OR business_name LIKE ?
      ''',
      whereArgs: [
        '%$query%',
        '%$query%',
        '%$query%',
        '%$query%',
        '%$query%',
      ],
      orderBy: 'name ASC',
    );

    return result.map((map) => Customer.fromMap(map)).toList();
  }
}