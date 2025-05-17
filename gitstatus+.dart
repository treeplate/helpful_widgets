import 'dart:io';

const String onBranch = 'On branch ';
const String upToDate = 'Your branch is up to date with \'';
const String behind = 'Your branch is behind \'';
const String ahead = 'Your branch is ahead of \'';
const String behindAheadMiddle = '\' by ';
RegExp behindEnd = RegExp(' commits?, and can be fast-forwarded\\.');
RegExp aheadEnd = RegExp(' commits?\\.');
const String nothingToCommit = 'nothing to commit, working tree clean';
const String unstagedChanges = 'Changes not staged for commit:';
const String stagedChanges = 'Changes to be committed:';
const String noCommits = 'No commits yet';

void main() {
  const bool logNoGitRepo = false;
  Directory dir = Directory('/Users/elih/dev');
  for (FileSystemEntity file in dir.listSync()) {
    // ignore: dead_code
    if (file is File && logNoGitRepo) {
      print('File: ${file.path}');
    } else if (file is Directory) {
      if (!file.listSync().any((e) => e.path.endsWith('.git'))) {
        // ignore: dead_code
        if (logNoGitRepo) {
          print('directory ${file.path} has no git repo');
        }
        continue;
      }
      List<String> gitStatus =
          Process.runSync('git', ['status'], workingDirectory: file.path)
              .stdout
              .replaceAll('\r\n', '\n')
              .split('\n');
      String branchNameLine = gitStatus.first;
      if (!branchNameLine.startsWith(onBranch)) {
        print(
            'Failed to parse branch name line for directory ${file.path}: $branchNameLine');
        continue;
      }
      String branch = branchNameLine.substring(onBranch.length);
      if (branch != 'main' && branch != 'master') {
        print('directory ${file.path} is on branch $branch');
      }
      String mainStatusLine = gitStatus[1];
      if (mainStatusLine.startsWith(behind)) {
        parseBehind(mainStatusLine, file);
        continue;
      }
      if (mainStatusLine.startsWith(ahead)) {
        parseAhead(mainStatusLine, file);
        continue;
      }
      if (mainStatusLine == '') {
        String noCommitsLine = gitStatus[2];
        if (noCommitsLine != noCommits) {
          print(
              'Failed to parse no commits line for directory ${file.path}: $noCommitsLine');
              continue;
        }
        print('directory ${file.path} has no commits');
        continue;
      }
      if (mainStatusLine == nothingToCommit || mainStatusLine == unstagedChanges) {
        print('directory ${file.path} has no remote');
        continue;
      }
      if (!mainStatusLine.startsWith(upToDate)) {
        print(
            'Failed to parse main status line for directory ${file.path}: $mainStatusLine');
        continue;
      }
      String workingTreeStatusLine = gitStatus[3];
      if (workingTreeStatusLine == unstagedChanges) {
        print('directory ${file.path} has unstaged changes');
        continue;
      }
      if (workingTreeStatusLine == stagedChanges) {
        print('directory ${file.path} has uncommited changes');
        continue;
      }
      if (workingTreeStatusLine != nothingToCommit) {
        print(
            'Failed to parse working tree status line: $workingTreeStatusLine');
        continue;
      }
    }
  }
}

void parseBehind(String mainStatusLine, Directory file) {
  int endingQuote = mainStatusLine.lastIndexOf('\'');
  String remoteName =
      mainStatusLine.substring(behind.length, endingQuote);
  int? commitCount = int.tryParse(mainStatusLine.substring(
      endingQuote + behindAheadMiddle.length,
      mainStatusLine.lastIndexOf(behindEnd)));
  if (commitCount == null) {
    print(
        'Failed to parse main status line for directory ${file.path}: $mainStatusLine');
    return;
  }
  print(
      'directory ${file.path} is behind remote \'$remoteName\' by $commitCount commits');
  return;
}

void parseAhead(String mainStatusLine, Directory file) {
  int endingQuote = mainStatusLine.lastIndexOf('\'');
  String remoteName =
      mainStatusLine.substring(ahead.length, endingQuote);
  int? commitCount = int.tryParse(mainStatusLine.substring(
      endingQuote + behindAheadMiddle.length,
      mainStatusLine.lastIndexOf(aheadEnd)));
  if (commitCount == null) {
    print(
        'Failed to parse main status line for directory ${file.path}: $mainStatusLine');
    return;
  }
  print(
      'directory ${file.path} is ahead of remote \'$remoteName\' by $commitCount commits');
  return;
}
