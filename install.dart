import 'dart:io';

main() async {
  await getPub();
  await removeBuild();
  await makeBuildDir();
  await buildNative();
  await install();
}

getPub() async {
  return Process.run('flutter', ['pub', 'get']).then((ProcessResult results) {
    stdout.write(results.stdout);
    stdout.write(results.stderr);
  });
}

removeBuild() async {
  return Process.run('rm', ['-r', './build']).then((ProcessResult results) {
    stdout.write(results.stdout);
    stdout.write(results.stderr);
  });
}

makeBuildDir() async {
  return Process.run('mkdir', ['build']).then((ProcessResult results) {
    stdout.write(results.stdout);
    stdout.write(results.stderr);
  });
}

buildNative() async {
  return Process.run('dart2native', [
    './lib/pubspec_updater.dart',
    '-p',
    './.packages',
    '-o',
    './build/pubspec_updater'
  ]).then((ProcessResult results) {
    stdout.write(results.stdout);
    stdout.write(results.stderr);
  });
}

install() async {
  // didn't see to like the ~/bin
  String home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

  return Process.run('mv', ['./build/pubspec_updater', '$home/bin'])
      .then((ProcessResult results) {
    stdout.write(results.stdout);
    stdout.write(results.stderr);
  });
}
