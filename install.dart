import 'dart:io';

String name = 'pubspec_updater';

Future main() async {
  // await getPub();
  await removeBuild();
  await makeBuildDir();
  await buildNative();
  await install();
  await removeBuild();
}

Future getPub() async {
  return Process.run('flutter', ['pub', 'get']).then((ProcessResult results) {
    stdout.write(results.stdout);
    stdout.write(results.stderr);
  });
}

Future removeBuild() async {
  final Directory buildDir = Directory('./build');

  final bool exists = buildDir.existsSync();
  if (exists) {
    buildDir.deleteSync(recursive: true);
  }
}

Future makeBuildDir() async {
  final Directory buildDir = Directory('./build');

  final bool exists = buildDir.existsSync();
  if (!exists) {
    buildDir.createSync(recursive: false);
  }
}

Future buildNative() async {
    return Process.run('dart', [
    'compile',
    'exe',
    './lib/pubspec_updater.dart',
    '-o',
    './build/$name'
  ]).then((ProcessResult results) {
    stdout.write(results.stdout);
    stdout.write(results.stderr);
  });
}

Future install() async {
  final String home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';

  return File('./build/$name').copy('$home/bin/$name');
}
