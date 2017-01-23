library github.test.git_test;

import 'dart:async';
import 'dart:convert' show JSON;

import 'package:github/src/common.dart';
import 'package:github/src/util.dart';
import "package:http/http.dart" as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockGitHub extends Mock implements GitHub {}

void main() {
  MockGitHub github;
  GitService git;
  RepositorySlug repo;
  var someSha = 'someSHA';

  setUp(() {
    github = new MockGitHub();
    git = new GitService(github);
    repo = new RepositorySlug('o', 'n');
  });

  group('getBlob()', () {
    test('constructs correct path', () {
      git.getBlob(repo, 'sh');

      verify(github.getJSON('/repos/o/n/git/blobs/sh',
          convert: GitBlob.fromJSON, statusCode: StatusCodes.OK));
    });
  });

  group('createBlob()', () {
    test('constructs correct path', () {
      CreateGitBlob blob = new CreateGitBlob('bbb', 'utf-8');
      git.createBlob(repo, blob);

      verify(github.postJSON('/repos/o/n/git/blobs',
          convert: GitBlob.fromJSON,
          statusCode: StatusCodes.CREATED,
          body: blob.toJSON()));
    });

    test('creates valid JSON body', () {
      CreateGitBlob blob = new CreateGitBlob('bbb', 'utf-8');

      git.createBlob(repo, blob);
      var body = captureSentBody(github);
      expect(body['content'], equals('bbb'));
      expect(body['encoding'], equals('utf-8'));
    });
  });

  group('getCommit()', () {
    test('constructs correct path', () {
      git.getCommit(repo, 'sh');

      verify(github.getJSON('/repos/o/n/git/commits/sh',
          convert: GitCommit.fromJSON, statusCode: StatusCodes.OK));
    });
  });

  group('createCommit()', () {
    test('constructs correct path', () {
      CreateGitCommit commit = new CreateGitCommit('aMessage', 'aTreeSha');
      git.createCommit(repo, commit);

      verify(github.postJSON('/repos/o/n/git/commits',
          convert: GitCommit.fromJSON,
          statusCode: StatusCodes.CREATED,
          body: commit.toJSON()));
    });

    test('creates valid JSON body', () {
      // given
      String date = '2014-10-02T15:21:29Z';

      CreateGitCommit commit = new CreateGitCommit('aMessage', 'aTreeSha')
        ..parents = ['parentSha1', 'parentSha2']
        ..committer = new GitCommitUser('cName', 'cEmail', parseDateTime(date))
        ..author = new GitCommitUser('aName', 'aEmail', parseDateTime(date));

      // when
      git.createCommit(repo, commit);

      // then
      var body = captureSentBody(github);
      expect(body['message'], equals('aMessage'));
      expect(body['tree'], equals('aTreeSha'));
      expect(body['parents'], equals(['parentSha1', 'parentSha2']));
      expect(body['committer']['name'], equals('cName'));
      expect(body['committer']['email'], equals('cEmail'));
      expect(body['committer']['date'], equals(date));
      expect(body['author']['name'], equals('aName'));
      expect(body['author']['email'], equals('aEmail'));
      expect(body['author']['date'], equals(date));
    });
  });

  group('getReference()', () {
    test('constructs correct path', () {
      git.getReference(repo, 'heads/b');

      verify(github.getJSON('/repos/o/n/git/refs/heads/b',
          convert: GitReference.fromJSON, statusCode: StatusCodes.OK));
    });
  });

  group('createReference()', () {
    var someRef = 'refs/heads/b';
    test('constructs correct path', () {
      git.createReference(repo, someRef, someSha);

      verify(github.postJSON('/repos/o/n/git/refs',
          convert: GitReference.fromJSON,
          statusCode: StatusCodes.CREATED,
          body: JSON.encode({'ref': someRef, 'sha': someSha})));
    });

    test('creates valid JSON body', () {
      git.createReference(repo, someRef, someSha);

      var body = captureSentBody(github);
      expect(body['ref'], equals(someRef));
      expect(body['sha'], equals(someSha));
    });
  });

  group('editReference()', () {
    test('constructs correct path', () {
      // given
      http.Response expectedResponse = new http.Response('{}', 200);

      when(github.request(any, any,
              body: any, headers: typed(any, named: 'headers')))
          .thenReturn(new Future.value(expectedResponse));

      // when
      git.editReference(repo, 'heads/b', someSha);

      // then
      verify(github.request('PATCH', '/repos/o/n/git/refs/heads/b',
          headers: typed(any, named: 'headers'), body: any));
    });

    test('creates valid JSON body', () {
      // given
      http.Response expectedResponse = new http.Response('{}', 200);
      when(github.request(any, any,
              body: any, headers: typed(any, named: 'headers')))
          .thenReturn(new Future.value(expectedResponse));

      // when
      git.editReference(repo, 'heads/b', someSha, force: true);

      // then
      var captured = verify(github.request(any, any,
              body: captureAny, headers: typed(captureAny, named: 'headers')))
          .captured;

      var body = JSON.decode(captured[0]);
      var headers = captured[1];

      expect(body['sha'], equals(someSha));
      expect(body['force'], equals(true));
      expect(headers['content-length'], equals('30'));
    });
  });

  group('deleteReference()', () {
    test('constructs correct path', () {
      // given
      http.Response expectedResponse = new http.Response('{}', 200);
      when(github.request(any, any))
          .thenReturn(new Future.value(expectedResponse));

      // when
      git.deleteReference(repo, 'heads/b');

      // then
      verify(github.request('DELETE', '/repos/o/n/git/refs/heads/b'));
    });
  });

  group('getTag()', () {
    test('constructs correct path', () {
      git.getTag(repo, someSha);

      verify(github.getJSON('/repos/o/n/git/tags/someSHA',
          convert: GitTag.fromJSON, statusCode: StatusCodes.OK));
    });
  });

  group('createTag()', () {
    var createGitTag = new CreateGitTag('v0.0.1', 'a message', someSha,
        'commit', new GitCommitUser('aName', 'aEmail', new DateTime.now()));

    test('constructs correct path', () {
      git.createTag(repo, createGitTag);

      verify(github.postJSON('/repos/o/n/git/tags',
          convert: GitTag.fromJSON,
          statusCode: StatusCodes.CREATED,
          body: createGitTag.toJSON()));
    });

    test('creates valid JSON body', () {
      git.createTag(repo, createGitTag);

      var body = captureSentBody(github);
      expect(body['tag'], equals('v0.0.1'));
      expect(body['message'], equals('a message'));
      expect(body['object'], equals(someSha));
      expect(body['type'], equals('commit'));
      expect(body['tagger']['name'], equals('aName'));
    });
  });

  group('getTree()', () {
    test('constructs correct path', () {
      git.getTree(repo, 'sh');

      verify(github.getJSON('/repos/o/n/git/trees/sh',
          convert: GitTree.fromJSON, statusCode: StatusCodes.OK));
    });
  });

  group('getTree(recursive: true)', () {
    test('constructs correct path', () {
      git.getTree(repo, 'sh', recursive: true);

      verify(github.getJSON('/repos/o/n/git/trees/sh?recursive=1',
          convert: GitTree.fromJSON, statusCode: StatusCodes.OK));
    });
  });

  group('createTree()', () {
    test('constructs correct path', () {
      var createGitTree = new CreateGitTree([]);
      git.createTree(repo, createGitTree);

      verify(github.postJSON('/repos/o/n/git/trees',
          convert: GitTree.fromJSON,
          statusCode: StatusCodes.CREATED,
          body: createGitTree.toJSON()));
    });

    test('with sha creates valid JSON body', () {
      // given
      var treeEntry = new CreateGitTreeEntry('file.rb', '100644', 'blob',
          sha: '44b4fc6d56897b048c772eb4087f854f46256132');

      var tree = new CreateGitTree([treeEntry]);

      // when
      git.createTree(repo, tree);

      // then
      var body = captureSentBody(github);
      expect(body['tree'], isNotNull);
      expect(body['tree'][0]['path'], equals('file.rb'));
      expect(body['tree'][0]['mode'], equals('100644'));
      expect(body['tree'][0]['type'], equals('blob'));
      expect(body['tree'][0]['sha'],
          equals('44b4fc6d56897b048c772eb4087f854f46256132'));
      expect(body['tree'][0]['content'], isNull);
    });

    test('with content creates valid JSON body', () {
      // given
      var treeEntry = new CreateGitTreeEntry('file.rb', '100644', 'blob',
          content: 'some file content');

      var tree = new CreateGitTree([treeEntry]);

      // when
      git.createTree(repo, tree);

      // then
      var body = captureSentBody(github);
      expect(body['tree'], isNotNull);
      expect(body['tree'][0]['path'], equals('file.rb'));
      expect(body['tree'][0]['mode'], equals('100644'));
      expect(body['tree'][0]['type'], equals('blob'));
      expect(body['tree'][0]['sha'], isNull);
      expect(body['tree'][0]['content'], equals('some file content'));
    });
  });

  group('updateBranchProtection', () {
    var branchName = 'branchName';
    test('constructs correct path', () {
      var requiredStatusChecks = new RequiredStatusChecks()
        ..contexts = ['someContext']
        ..strict = true
        ..includeAdmins = true;

      var restrictions = new Restrictions();

      var expectedResponse = new http.Response('{}', StatusCodes.OK);
      when(github.request('PUT', '/repos/o/n/branches/$branchName/protection',
              body: any, preview: any))
          .thenReturn(expectedResponse);

      git.updateBranchProtection(
          repo, branchName, requiredStatusChecks, restrictions);

      var verif = verify(github.request(captureAny, captureAny,
              body: captureAny, preview: captureAny))
          .captured;

      expect(verif, 12);
    });
  });

  group('getBranchProtection', () {
    var branchName = 'branchName';
    test('constructs correct path', () {
      git.getBranchProtection(repo, branchName);

      verify(github.getJSON('/repos/o/n/branches/$branchName/protection',
          convert: BranchProtection.fromJSON,
          statusCode: StatusCodes.OK,
          preview: any));
    });

    test('adds the preview headers headers', () {
      git.getBranchProtection(repo, branchName);

      verify(github.getJSON(any,
          statusCode: any,
          preview: 'application/vnd.github.loki-preview+json',
          convert: any));
    });
  });
}

Map<String, dynamic> captureSentBody(MockGitHub github) {
  var bodyString = verify(
          github.postJSON(any, convert: any, statusCode: any, body: captureAny))
      .captured
      .single;

  var body = JSON.decode(bodyString) as Map<String, dynamic>;
  return body;
}
