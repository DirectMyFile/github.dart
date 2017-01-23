library github.test.integration.git_integration_test;

import 'dart:convert';

import 'dart:io';
import 'package:github/server.dart';

import 'package:test/test.dart';

void main() {
  String firstCommitSha;
  String firstCommitTreeSha;

  String createdTreeSha;
  String createdCommitSha;

  GitHub github;
  RepositorySlug slug;

  setUpAll(() {
    var authToken = Platform.environment['GITHUB_API_TOKEN'];
    var repoOwner = Platform.environment['GITHUB_DART_TEST_REPO_OWNER'];
    var repoName = Platform.environment['GITHUB_DART_TEST_REPO_NAME'];

    github = createGitHubClient(auth: new Authentication.withToken(authToken));
    slug = new RepositorySlug(repoOwner, repoName);
  });

  tearDownAll(() {
    github.dispose();
  });

  // Test definitions.
  test('get last commit of master', () async {
    var branch = await github.repositories.getBranch(slug, 'master');
    firstCommitSha = branch.commit.sha;
    firstCommitTreeSha = branch.commit.tree.sha;
  });

  test('create and get a new blob', () async {
    var newBlob = new CreateGitBlob('bbb', 'utf-8');

    // createBlob()
    var createdBlob = await github.git.createBlob(slug, newBlob);
    var createdBlobSha = createdBlob.sha;

    var fetchedBlob = await github.git.getBlob(slug, createdBlobSha);

    var base64Decoded = BASE64.decode(fetchedBlob.content);

    expect(UTF8.decode(base64Decoded), equals('bbb'));
    expect(fetchedBlob.encoding, equals('base64'));
    expect(
        fetchedBlob.url,
        equals(
            'https://api.github.com/repos/${slug.fullName}/git/blobs/${createdBlobSha}'));
    expect(fetchedBlob.sha, equals(createdBlobSha));
    expect(fetchedBlob.size, equals(3));
  });

  test('create and get a new tree', () async {
    var entry1 = new CreateGitTreeEntry('README.md', '100644', 'blob',
        content: 'This is a repository for integration tests.');
    var entry2 = new CreateGitTreeEntry('subdir/asdf.txt', '100644', 'blob',
        content: 'Some file in a folder.');

    var newTree = new CreateGitTree([entry1, entry2])
      ..baseTree = firstCommitTreeSha;

    // createTree()
    var createdTree = await github.git.createTree(slug, newTree);
    createdTreeSha = createdTree.sha;

    // getTree()
    var fetchedTree = await github.git.getTree(slug, createdTreeSha);

    expect(fetchedTree.sha, equals(createdTreeSha));
    expect(fetchedTree.entries.length, equals(2));
  });

  test('create and get a new commit', () async {
    var newCommit = new CreateGitCommit('My test commit', createdTreeSha)
      ..parents = [firstCommitSha];

    // createCommit()
    var createdCommit = await github.git.createCommit(slug, newCommit);
    createdCommitSha = createdCommit.sha;

    // getCommit()
    var fetchedCommit = await github.git.getCommit(slug, createdCommitSha);
    expect(fetchedCommit.sha, equals(createdCommitSha));
    expect(fetchedCommit.message, equals('My test commit'));
    expect(fetchedCommit.tree.sha, equals(createdTreeSha));
    expect(fetchedCommit.parents.first.sha, equals(firstCommitSha));
  });

  test('update heads/master reference to new commit', () {
    return github.git.editReference(slug, 'heads/master', createdCommitSha);
  });

  test('create and get a new reference (branch)', () async {
    var branchName = _randomGitName();

    await github.git
        .createReference(slug, 'refs/heads/$branchName', createdCommitSha);

    var fetchedRef = await github.git.getReference(slug, 'heads/$branchName');
    expect(fetchedRef.ref, equals('refs/heads/$branchName'));
    expect(fetchedRef.object.type, equals('commit'));
    expect(fetchedRef.object.sha, equals(createdCommitSha));
  });

  test('create and get a new tag', () async {
    var tagName = 'v${_randomGitName()}';

    var newTag = new CreateGitTag(tagName, 'Version 0.0.1', createdCommitSha,
        'commit', new GitCommitUser('aName', 'aEmail', new DateTime.now()));

    // createTag()
    var createdTag = await github.git.createTag(slug, newTag);
    var createdTagSha = createdTag.sha;

    // getTag()
    var fetchedTag = await github.git.getTag(slug, createdTagSha);
    expect(fetchedTag.tag, equals(tagName));
    expect(fetchedTag.sha, equals(createdTagSha));
    expect(fetchedTag.message, equals('Version 0.0.1'));
    expect(fetchedTag.tagger.name, equals('aName'));
    expect(fetchedTag.object.sha, equals(createdCommitSha));

    // Create a reference for the tag.
    await github.git.createReference(slug, 'refs/tags/$tagName', createdTagSha);
  });

  group('create and query issues', () {
    test('query issues', () async {
      var issues = await github.issues.listByRepo(slug).toList();

      var count = issues.length;

      var issueRequest = new IssueRequest()
        ..title = 'new issue - ${_randomGitName()}';

      await github.issues.create(slug, issueRequest);

      issues = await github.issues
          .listByRepo(slug, sort: 'updated', direction: 'desc')
          .toList();

      expect(issues, hasLength(count + 1));

      var issue = issues.first;

      expect(issue.title, issueRequest.title);
    });
  });

  group('branch protection', () {
    test('get protection', () async {
      var result = await github.git.getBranchProtection(slug, 'master');

      expect(result.requiredStatusChecks.contexts, isEmpty);
      expect(result.requiredStatusChecks.includeAdmins, isTrue);
      expect(result.requiredStatusChecks.strict, isTrue);
    });

    test('update protection', () async {
      var contexts = ['someContext', 'anotherContext'];
      var requiredStatusChecks = new RequiredStatusChecks()
        ..strict = false
        ..includeAdmins = true
        ..contexts = contexts;

      var restrictions = new Restrictions();

      var result = await github.git.updateBranchProtection(
          slug, 'master', requiredStatusChecks, restrictions);

      expect(result, isTrue);
    });
  });
}

String _randomGitName() {
  var now = new DateTime.now().toIso8601String().replaceAll(':', '_');

  return now.toString();
}
