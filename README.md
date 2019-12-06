# pubspec_updater

Creates a native tool to update all package versions in pubspec.yaml

```
$ dart install.dart
```

This will copy a tool called pubspec_updater in to /home/user/bin. Make sure you have a bin dir in home and it's added to your \$PATH.

Only tested on Linux, but should work on macOS.

Send in Pull Requests if it doesn't work for you. Let me know if there is a better way to build this.

Once the tool is installed, you can go to any flutter package directory with a pubspec.yaml file and run:

This will display what it will change, but not write out the changes

```
$ pubspec_updater
```

Run with -u to actually write the pubspec.yaml

```
$ pubspec_updater -u
```

There are other flags to control how it change the versions. Use -h for help.

```
$ pubspec_updater -h
```

It will also add versions for pubs with out a version. It avoids any versions with < or >

Code is based on https://github.com/mauriciotogneri/dapackages

Inspired by npm-check-updates https://github.com/tjunnone/npm-check-updates
