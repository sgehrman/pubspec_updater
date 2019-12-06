import 'dart:io';

String name = 'pubspec_updater';

main() async {
  // await getPub();
  await removeBuild();
  await makeBuildDir();
  await buildNative();
  await install();
  await removeBuild();
}

getPub() async {
  return Process.run('flutter', ['pub', 'get']).then((ProcessResult results) {
    stdout.write(results.stdout);
    stdout.write(results.stderr);
  });
}

removeBuild() async {
  Directory buildDir = Directory('./build');

  return buildDir.exists().then((exists) {
    if (exists) {
      buildDir.deleteSync(recursive: true);
    }
  });
}

makeBuildDir() async {
  Directory buildDir = Directory('./build');

  return buildDir.exists().then((exists) {
    if (!exists) {
      buildDir.createSync(recursive: false);
    }
  });
}

buildNative() async {
  return Process.run('dart2native', [
    './lib/pubspec_updater.dart',
    '-p',
    './.packages',
    '-o',
    './build/$name'
  ]).then((ProcessResult results) {
    stdout.write(results.stdout);
    stdout.write(results.stderr);
  });
}

install() async {
  String home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

  return File('./build/$name').copy('$home/bin/$name');
}
