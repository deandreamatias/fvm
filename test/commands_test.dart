@Timeout(Duration(minutes: 5))
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/context.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

final runner = TestFvmCommandRunner();

void main() {
  groupWithContext('Channel Workflow:', () {
    final runner = TestFvmCommandRunner();

    testWithContext('Install Channel', () async {
      // await testContextWrapper(contextKey, () async {
      await runner.run('fvm install $channel');

      final cacheVersion = CacheService.getVersion(FlutterVersion(channel));

      final existingChannel = await getBranch(channel);
      expect(cacheVersion != null, true, reason: 'Install does not exist');

      expect(existingChannel, channel);
    });

    testWithContext('List Channel', () async {
      final exitCode = await runner.run('fvm list');

      expect(exitCode, ExitCode.success.code);
    });

    testWithContext('Use Channel', () async {
      try {
        // Run foce to test within fvm
        await runner.run('fvm use $channel --force');

        final project = await ProjectService.findAncestor();

        final linkExists = project.cacheVersionSymlink.existsSync();

        final targetBin = project.cacheVersionSymlink.targetSync();

        final channelBin = CacheService.getVersionCacheDir(channel);

        expect(targetBin == channelBin.path, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    testWithContext('Use Flutter SDK globally', () async {
      try {
        await runner.run('fvm global $channel');
        final linkExists = ctx.globalCacheLink.existsSync();

        final targetVersion = basename(await ctx.globalCacheLink.target());

        expect(targetVersion == channel, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    testWithContext('Remove Channel Command', () async {
      try {
        await runner.run('fvm remove $channel');
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    testWithContext('Install Release', () async {
      await runner.run('fvm install $release');
      final valid = FlutterVersion(release);
      final existingRelease = await getTag(valid.name);

      final cacheVersion = CacheService.getVersion(valid);

      expect(cacheVersion != null, true, reason: 'Install does not exist');

      expect(existingRelease, valid.name);
    });

    testWithContext('Install commit', () async {
      final gitHash = 'fb57da5f945d02ef4f98dfd9409a72b7cce74268';
      final shortGitHash = 'fb57da5';
      await runner.run('fvm install $gitHash');
      final valid = FlutterVersion(gitHash);

      await runner.run('fvm install $shortGitHash');
      final validShort = FlutterVersion(shortGitHash);

      final cacheVersion = CacheService.getVersion(valid);
      final cacheVersionShort = CacheService.getVersion(validShort);

      expect(cacheVersion != null, true, reason: 'Install does not exist');
      expect(cacheVersionShort != null, true, reason: 'Install does not exist');
    });

    testWithContext('Use Release', () async {
      final exitCode = await runner.run('fvm use $release --force');

      final project = await ProjectService.findAncestor();
      final linkExists = project.cacheVersionSymlink.existsSync();

      final targetPath = project.cacheVersionSymlink.targetSync();
      final valid = FlutterVersion(release);
      final versionDir = CacheService.getVersionCacheDir(valid.name);

      expect(targetPath == versionDir.path, true);
      expect(linkExists, true);
      expect(exitCode, ExitCode.success.code);
    });

    testWithContext('List Command', () async {
      expect(await runner.run('fvm list'), ExitCode.success.code);
    });

    testWithContext('Remove Release', () async {
      expect(await runner.run('fvm remove $release'), ExitCode.success.code);
    });
  });

  groupWithContext('Commands', () {
    test('Get Version', () async {
      expect(
        await runner.run('fvm --version'),
        ExitCode.success.code,
      );

      expect(
        await runner.run('fvm -v'),
        ExitCode.success.code,
      );
    });

    testWithContext('Doctor Command', () async {
      expect(
        await runner.run('fvm doctor'),
        ExitCode.success.code,
      );
    });

    testWithContext('Flavor Command', () async {
      await runner.run('fvm install $channel');

      expect(
        await runner.run(
          'fvm use $channel --flavor production',
        ),
        ExitCode.success.code,
      );

      expect(
        await runner.run('fvm flavor production'),
        ExitCode.success.code,
      );
    });
  });
}
