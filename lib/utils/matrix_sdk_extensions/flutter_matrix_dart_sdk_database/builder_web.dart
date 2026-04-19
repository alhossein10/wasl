import 'package:matrix/matrix.dart';

Future<DatabaseApi> flutterMatrixSdkDatabaseBuilder(String clientName) {
  return MatrixSdkDatabase.init(clientName);
}
