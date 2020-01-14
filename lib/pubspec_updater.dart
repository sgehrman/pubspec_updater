library pubspec_updater;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart';
import 'package:yaml/yaml.dart';
import 'package:args/args.dart';

Future main(List<String> args) async {
  runUpdater(args);
}

Updater runUpdater(args) {
  final parser = ArgParser();

  parser.addFlag('help',
      abbr: 'h', defaultsTo: false, negatable: false, help: 'Show help');
  parser.addFlag('version',
      abbr: 'v', defaultsTo: false, negatable: false, help: 'Show version');
  parser.addFlag('carets',
      abbr: 'c',
      defaultsTo: false,
      negatable: false,
      help: 'Adds ^ in front of all versions.');
  parser.addFlag('nocarets',
      abbr: 'n',
      defaultsTo: false,
      negatable: false,
      help: 'Removes all ^ in front of all versions.');
  parser.addFlag('update',
      abbr: 'u',
      defaultsTo: false,
      negatable: false,
      help: 'Write results to pubspec.yaml');
  parser.addFlag('removeRanges',
      abbr: 'r',
      defaultsTo: false,
      negatable: false,
      help:
          'Removes < <= > >= from versions and just puts in the latest version.  Otherwise it ignores those packages.');

  return Updater(parser, parser.parse(args));
}

class Updater {
  Updater(this.parser, ArgResults options)
      : version = options['version'],
        carets = options['carets'],
        nocarets = options['nocarets'],
        help = options['help'],
        update = options['update'],
        removeRanges = options['removeRanges'] {
    run();
  }

  final bool help;
  final bool version;
  final bool carets;
  final bool update;
  final bool removeRanges;
  final bool nocarets;
  final ArgParser parser;

  void run() {
    if (help) {
      stdout.writeln(parser.usage);
    } else if (version) {
      // can we get the version at compile time with dart2native?
      stdout.writeln('version: 1.0.1');
    } else {
      runUpdate();
    }
  }

  void writeUpdateInfo(List<Dependency> dependencies) {
    if (dependencies.isNotEmpty) {
      for (int x = 0; x < dependencies.length; x++) {
        if (dependencies[x].hasNewVersion) {
          stdout.writeln(dependencies[x].toString());
        }
      }
    } else {
      stdout.writeln('Nothing to update');
    }

    stdout.writeln();
  }

  Future runUpdate() async {
    final File file = File('./pubspec.yaml');

    final List<Dependency> dependencies =
        await getDependencies(file, 'dependencies');

    final List<Dependency> devDependencies =
        await getDependencies(file, 'dev_dependencies');

    dependencies.addAll(devDependencies);

    await updateDependencies(dependencies);

    writeUpdateInfo(dependencies);

    if (update) {
      await updateFile(file, dependencies);
    } else {
      stdout.writeln('Run with -u to update pubspec.yaml');
    }
  }

  Future<List<Dependency>> getDependencies(File file, String section) async {
    final List<Dependency> list = <Dependency>[];

    final String content = await file.readAsString();
    final dynamic yaml = loadYaml(content);
    final YamlMap dependencies = yaml[section];

    if (dependencies != null) {
      for (final entry in dependencies.entries) {
        // avoid YamlMaps
        if (entry.value is String || entry.value == null) {
          final String name = entry.key.toString();
          final String value = entry.value is String ? entry.value : '';

          // avoid > <
          if (removeRanges ||
              (!value.startsWith('>') && !value.startsWith('<')))
            list.add(Dependency(name, value));
        }
      }
    }

    return list;
  }

  Future<void> updateDependencies(List<Dependency> list) async {
    for (int i = 0; i < list.length; i++) {
      final Dependency dependency = list[i];

      if (i > 0) {
        stdout.write('\r');
      }

      stdout.write('Analyzing dependency ${i + 1}/${list.length}');

      String lastVersion = await getLatestVersion(dependency.name);

      if (!nocarets) {
        if (dependency.hadCaret || carets) {
          lastVersion = '^' + lastVersion;
        }
      }

      dependency.update(lastVersion);
    }

    stdout.writeln();
    stdout.writeln();
  }

  Future<String> getLatestVersion(String name) async {
    final Response response =
        await get('https://pub.dartlang.org/api/packages/$name');
    final dynamic json = jsonDecode(response.body);

    return json['latest']['version'];
  }

  String searchString(Dependency dependency, String quote) {
    // space added to catch the case of image: and xx_image:
    // we don't want to match the xx_ version
    String search = ' ${dependency.name}:';

    if (dependency.currentVersion.isNotEmpty) {
      search += ' $quote${dependency.currentVersion}$quote';
    }

    return search;
  }

  String buildSearchString(String yaml, Dependency dependency) {
    String search = searchString(dependency, '');

    // the version could have quotes for < > <= etc.
    // if we can't find it, add " or ' and try again
    if (!yaml.contains(search)) {
      search = searchString(dependency, '"');
    }

    if (!yaml.contains(search)) {
      search = searchString(dependency, "'");
    }

    if (!yaml.contains(search)) {
      search = null;
    }

    return search;
  }

  Future<void> updateFile(File file, List<Dependency> list) async {
    String yaml = await file.readAsString();

    for (final dependency in list) {
      if (dependency.hasNewVersion) {
        final String search = buildSearchString(yaml, dependency);

        if (search != null) {
          // space added to catch the case of image: and xx_image:
          // see searchString above
          final String replace =
              ' ${dependency.name}: ${dependency.newVersion}';

          yaml = yaml.replaceFirst(search, replace);
        } else {
          stdout.writeln(
              'Could not find ${dependency.name} in pubspec.yaml.  Not replaced.');
        }
      }
    }

    file.writeAsStringSync(yaml);

    stdout.writeln('pubspec.yaml updated');
  }
}

class Dependency {
  Dependency(this.name, this.currentVersion) : newVersion = currentVersion {
    if (currentVersion.isNotEmpty && currentVersion.startsWith('^')) {
      hadCaret = true;
    }
  }

  final String name;
  final String currentVersion;
  String newVersion;
  bool hadCaret = false;

  bool get hasNewVersion => currentVersion != newVersion;

  void update(String version) {
    newVersion = version;
  }

  @override
  String toString() {
    final String left = '$name: $currentVersion';
    final String right = '$name: $newVersion';

    final String padding = ' ' * max(2, 20 - left.length);

    return '$left$padding->     $right';
  }
}
