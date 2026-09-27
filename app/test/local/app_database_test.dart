import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/app_database.dart';

void main() {
  test('cada perfil ganha o nome do próprio arquivo de banco', () {
    expect(localDatabaseName('user-1'), isNot(localDatabaseName('user-2')));
  });

  test('o mesmo perfil sempre abre o mesmo arquivo', () {
    expect(localDatabaseName('user-1'), localDatabaseName('user-1'));
  });
}
