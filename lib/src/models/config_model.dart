// Use just for reference, should not change

import 'dart:io';

import 'package:args/args.dart';
import 'package:jsonc/jsonc.dart';

import '../utils/change_case.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../utils/pretty_json.dart';

class ConfigKeys {
  final String key;

  static const ConfigKeys cachePath = ConfigKeys('cache_path');
  static const ConfigKeys useGitCache = ConfigKeys('git_cache');
  static const ConfigKeys gitCachePath = ConfigKeys('git_cache_path');
  static const ConfigKeys flutterUrl = ConfigKeys('flutter_url');
  static const ConfigKeys priviledgedAccess = ConfigKeys('priviledged_access');

  static const values = <ConfigKeys>[
    cachePath,
    useGitCache,
    gitCachePath,
    flutterUrl,
  ];

  const ConfigKeys(this.key);

  static ConfigKeys fromName(String name) {
    return values.firstWhere((e) => e.key == name);
  }

  static argResultsToMap(ArgResults argResults) {
    final configMap = <String, dynamic>{};

    for (final key in values) {
      final value = argResults[key.paramKey];
      if (value != null) {
        configMap[key.propKey] = value;
      }
    }

    return configMap;
  }

  static injectArgParser(ArgParser argParser) {
    final configKeysFuncs = {
      ConfigKeys.cachePath.key: () {
        argParser.addOption(
          ConfigKeys.cachePath.paramKey,
          help: 'Path where $kPackageName will cache versions',
        );
      },
      ConfigKeys.useGitCache.key: () {
        argParser.addFlag(
          ConfigKeys.useGitCache.paramKey,
          help:
              'Enable/Disable git cache globally, which is used for faster version installs.',
          defaultsTo: true,
          negatable: true,
        );
      },
      ConfigKeys.gitCachePath.key: () {
        argParser.addOption(
          ConfigKeys.gitCachePath.paramKey,
          help: 'Path where local Git reference cache is stored',
        );
      },
      ConfigKeys.flutterUrl.key: () {
        argParser.addOption(
          ConfigKeys.flutterUrl.paramKey,
          help: 'Flutter repository Git URL to clone from',
        );
      },
      ConfigKeys.priviledgedAccess.key: () {
        argParser.addFlag(
          ConfigKeys.priviledgedAccess.paramKey,
          help: 'Enable/Disable priviledged access for FVM',
          defaultsTo: true,
          negatable: true,
        );
      },
    };

    for (final key in values) {
      configKeysFuncs[key.key]?.call();
    }
  }

  ChangeCase get _recase => ChangeCase(key);

  String get envKey => 'FVM_${_recase.constantCase}';
  String get paramKey => _recase.paramCase;
  String get propKey => _recase.camelCase;

  @override
  operator ==(Object other) => other is ConfigKeys && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

class Config {
  // If should use gitCache
  bool? useGitCache;

  String? gitCachePath;

  /// Flutter repo url
  String? flutterUrl;

  /// Directory where FVM is stored
  String? cachePath;

  /// If FVM should run with priviledged access
  bool? priviledgedAccess;

  /// Constructor
  Config({
    required this.cachePath,
    required this.useGitCache,
    required this.gitCachePath,
    required this.flutterUrl,
    required this.priviledgedAccess,
  });

  factory Config.empty() {
    return Config(
      cachePath: null,
      useGitCache: null,
      gitCachePath: null,
      flutterUrl: null,
      priviledgedAccess: null,
    );
  }

  factory Config.fromMap(Map<String, dynamic> map) {
    return Config(
      cachePath: map[ConfigKeys.cachePath.propKey] as String?,
      useGitCache: map[ConfigKeys.useGitCache.propKey] as bool?,
      gitCachePath: map[ConfigKeys.gitCachePath.propKey] as String?,
      flutterUrl: map[ConfigKeys.flutterUrl.propKey] as String?,
      priviledgedAccess: map[ConfigKeys.priviledgedAccess.propKey] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (cachePath != null) ConfigKeys.cachePath.propKey: cachePath,
      if (useGitCache != null) ConfigKeys.useGitCache.propKey: useGitCache,
      if (gitCachePath != null) ConfigKeys.gitCachePath.propKey: gitCachePath,
      if (flutterUrl != null) ConfigKeys.flutterUrl.propKey: flutterUrl,
      if (priviledgedAccess != null)
        ConfigKeys.priviledgedAccess.propKey: priviledgedAccess,
    };
  }
}

/// App config
class AppConfig extends Config {
  /// Disables update notification
  bool? disableUpdateCheck;
  DateTime? lastUpdateCheck;

  /// Constructor
  AppConfig({
    required this.disableUpdateCheck,
    required this.lastUpdateCheck,
    required super.cachePath,
    required super.useGitCache,
    required super.gitCachePath,
    required super.flutterUrl,
    required super.priviledgedAccess,
  });

  factory AppConfig.empty() {
    return AppConfig(
      disableUpdateCheck: null,
      lastUpdateCheck: null,
      cachePath: null,
      useGitCache: null,
      gitCachePath: null,
      flutterUrl: null,
      priviledgedAccess: null,
    );
  }

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    final envConfig = Config.fromMap(map);

    return AppConfig(
      disableUpdateCheck: map['disableUpdateCheck'] as bool?,
      lastUpdateCheck: map['lastUpdateCheck'] != null
          ? DateTime.parse(map['lastUpdateCheck'] as String)
          : null,
      cachePath: envConfig.cachePath,
      useGitCache: envConfig.useGitCache,
      gitCachePath: envConfig.gitCachePath,
      flutterUrl: envConfig.flutterUrl,
      priviledgedAccess: envConfig.priviledgedAccess,
    );
  }

  factory AppConfig.fromJson(String source) {
    return AppConfig.fromMap(jsonc.decode(source) as Map<String, dynamic>);
  }

  static AppConfig? loadFromPath(String path) {
    final configFile = File(path);

    return configFile.existsSync()
        ? AppConfig.fromJson(configFile.readAsStringSync())
        : null;
  }

  AppConfig copyWith({
    String? cachePath,
    bool? useGitCache,
    String? gitCachePath,
    String? flutterUrl,
    bool? disableUpdateCheck,
    DateTime? lastUpdateCheck,
    bool? priviledgedAccess,
  }) {
    return AppConfig(
      disableUpdateCheck: disableUpdateCheck ?? this.disableUpdateCheck,
      lastUpdateCheck: lastUpdateCheck ?? this.lastUpdateCheck,
      cachePath: cachePath ?? this.cachePath,
      useGitCache: useGitCache ?? this.useGitCache,
      gitCachePath: gitCachePath ?? this.gitCachePath,
      flutterUrl: flutterUrl ?? this.flutterUrl,
      priviledgedAccess: priviledgedAccess ?? this.priviledgedAccess,
    );
  }

  AppConfig merge(AppConfig? config) {
    return copyWith(
      cachePath: config?.cachePath,
      useGitCache: config?.useGitCache,
      gitCachePath: config?.gitCachePath,
      flutterUrl: config?.flutterUrl,
      disableUpdateCheck: config?.disableUpdateCheck,
      lastUpdateCheck: config?.lastUpdateCheck,
      priviledgedAccess: config?.priviledgedAccess,
    );
  }

  AppConfig mergeConfig(Config? config) {
    return copyWith(
      cachePath: config?.cachePath,
      useGitCache: config?.useGitCache,
      gitCachePath: config?.gitCachePath,
      flutterUrl: config?.flutterUrl,
      priviledgedAccess: config?.priviledgedAccess,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      if (disableUpdateCheck != null) 'disableUpdateCheck': disableUpdateCheck,
      if (lastUpdateCheck != null)
        'lastUpdateCheck': lastUpdateCheck?.toIso8601String(),
    };
  }
}

/// Project config
class ProjectConfig extends Config {
  /// Flutter SDK version configured
  String? flutterSdkVersion;

  /// Flavors configured
  Map<String, String>? flavors;

  /// If Vscode settings is not managed by FVM
  bool? _updateVscodeSettings;

  /// If FVM should update .gitignore
  bool? _updateGitIgnore;

  /// If should run pub get on sdk change
  bool? _runPubGetOnSdkChanges;

  /// Constructor
  ProjectConfig({
    super.cachePath,
    super.useGitCache,
    super.gitCachePath,
    super.flutterUrl,
    super.priviledgedAccess,
    this.flutterSdkVersion,
    this.flavors,
    bool? updateVscodeSettings,
    bool? updateGitIgnore,
    bool? runPubGetOnSdkChanges,
  })  : _updateVscodeSettings = updateVscodeSettings,
        _updateGitIgnore = updateGitIgnore,
        _runPubGetOnSdkChanges = runPubGetOnSdkChanges;

  /// Returns ConfigDto from a map
  factory ProjectConfig.fromMap(Map<String, dynamic> map) {
    final envConfig = Config.fromMap(map);

    return ProjectConfig(
      cachePath: envConfig.cachePath,
      useGitCache: envConfig.useGitCache,
      gitCachePath: envConfig.gitCachePath,
      flutterUrl: envConfig.flutterUrl,
      priviledgedAccess: envConfig.priviledgedAccess,
      flutterSdkVersion: map['flutterSdkVersion'] ?? map['flutter'] as String?,
      flavors: map['flavors'] != null ? Map.from(map['flavors'] as Map) : null,
      updateVscodeSettings: map['updateVscodeSettings'] as bool?,
      updateGitIgnore: map['updateGitIgnore'] as bool?,
      runPubGetOnSdkChanges: map['runPubGetOnSdkChanges'] as bool?,
    );
  }

  /// Returns ConfigDto from a json string
  factory ProjectConfig.fromJson(String source) =>
      ProjectConfig.fromMap(jsonc.decode(source) as Map<String, dynamic>);

  static ProjectConfig? loadFromPath(String path) {
    final configFile = File(path);

    return configFile.existsSync()
        ? ProjectConfig.fromJson(configFile.readAsStringSync())
        : null;
  }

  /// Returns update vscode settings
  bool? get updateVscodeSettings => _updateVscodeSettings;

  /// Returns update git ignore
  bool? get updateGitIgnore => _updateGitIgnore;

  /// Returns run pub get on sdk changes
  bool? get runPubGetOnSdkChanges => _runPubGetOnSdkChanges;

  /// Copies current config and overrides with new values
  /// Returns a new ConfigDto

  ProjectConfig copyWith({
    String? cachePath,
    String? flutterSdkVersion,
    bool? useGitCache,
    bool? updateVscodeSettings,
    bool? updateGitIgnore,
    bool? runPubGetOnSdkChanges,
    bool? priviledgedAccess,
    String? gitCachePath,
    String? flutterUrl,
    Map<String, String>? flavors,
  }) {
    // merge map and override the keys
    final mergedFlavors = <String, String>{
      if (this.flavors != null) ...?this.flavors,
      // ignore: prefer-null-aware-spread
      if (flavors != null) ...flavors,
    };

    return ProjectConfig(
      cachePath: cachePath ?? this.cachePath,
      useGitCache: useGitCache ?? this.useGitCache,
      gitCachePath: gitCachePath ?? this.gitCachePath,
      flutterUrl: flutterUrl ?? this.flutterUrl,
      priviledgedAccess: priviledgedAccess ?? this.priviledgedAccess,
      flutterSdkVersion: flutterSdkVersion ?? this.flutterSdkVersion,
      flavors: mergedFlavors,
      updateVscodeSettings: updateVscodeSettings ?? _updateVscodeSettings,
      updateGitIgnore: updateGitIgnore ?? _updateGitIgnore,
      runPubGetOnSdkChanges: runPubGetOnSdkChanges ?? _runPubGetOnSdkChanges,
    );
  }

  ProjectConfig merge(ProjectConfig config) {
    return copyWith(
      cachePath: config.cachePath,
      flutterSdkVersion: config.flutterSdkVersion,
      useGitCache: config.useGitCache,
      updateVscodeSettings: config._updateVscodeSettings,
      updateGitIgnore: config._updateGitIgnore,
      runPubGetOnSdkChanges: config._runPubGetOnSdkChanges,
      priviledgedAccess: config.priviledgedAccess,
      gitCachePath: config.gitCachePath,
      flutterUrl: config.flutterUrl,
      flavors: config.flavors,
    );
  }

  void save(String path) {
    final jsonContents = prettyJson(toMap());

    path.file.write(jsonContents);
  }

  Map<String, dynamic> toLegacyMap() {
    return {
      if (flutterSdkVersion != null) 'flutterSdkVersion': flutterSdkVersion,
      if (flavors != null && flavors!.isNotEmpty) 'flavors': flavors,
    };
  }

  /// It checks each property for null prior to adding it to the map.
  /// This is to ensure the returned map doesn't contain any null values.
  /// Also, if [flavors] is not empty it adds it to the map.

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      if (flutterSdkVersion != null) 'flutter': flutterSdkVersion,
      if (_updateVscodeSettings != null)
        'updateVscodeSettings': _updateVscodeSettings,
      if (_updateGitIgnore != null) 'updateGitIgnore': _updateGitIgnore,
      if (_runPubGetOnSdkChanges != null)
        'runPubGetOnSdkChanges': _runPubGetOnSdkChanges,
      if (flavors != null && flavors!.isNotEmpty) 'flavors': flavors,
    };
  }
}
