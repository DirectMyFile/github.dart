part of github.common;

/// The [GitService] handles communication with git related methods of the
/// GitHub API.
///
/// API docs: https://developer.github.com/v3/git/blobs/
class GitService extends Service {
  GitService(GitHub github) : super(github);

  /// Fetches a blob from [slug] for a given [sha].
  ///
  /// API docs: https://developer.github.com/v3/git/blobs/#get-a-blob
  Future<GitBlob> getBlob(RepositorySlug slug, String sha) {
    return _github.getJSON('/repos/${slug.fullName}/git/blobs/${sha}',
        convert: GitBlob.fromJSON,
        statusCode: StatusCodes.OK) as Future<GitBlob>;
  }

  /// Creates a blob with specified [blob] content.
  ///
  /// API docs: https://developer.github.com/v3/git/blobs/#create-a-blob
  Future<GitBlob> createBlob(RepositorySlug slug, CreateGitBlob blob) {
    return _github.postJSON('/repos/${slug.fullName}/git/blobs',
        convert: GitBlob.fromJSON,
        statusCode: StatusCodes.CREATED,
        body: blob.toJSON()) as Future<GitBlob>;
  }

  /// Fetches a commit from [slug] for a given [sha].
  ///
  /// API docs: https://developer.github.com/v3/git/commits/#get-a-commit
  Future<GitCommit> getCommit(RepositorySlug slug, String sha) {
    return _github.getJSON('/repos/${slug.fullName}/git/commits/${sha}',
        convert: GitCommit.fromJSON,
        statusCode: StatusCodes.OK) as Future<GitCommit>;
  }

  /// Creates a new commit in a repository.
  ///
  /// API docs: https://developer.github.com/v3/git/commits/#create-a-commit
  Future<GitCommit> createCommit(RepositorySlug slug, CreateGitCommit commit) {
    return _github.postJSON('/repos/${slug.fullName}/git/commits',
        convert: GitCommit.fromJSON,
        statusCode: StatusCodes.CREATED,
        body: commit.toJSON()) as Future<GitCommit>;
  }

  /// Fetches a reference from a repository for the given [ref].
  ///
  /// Note: The [ref] in the URL must be formatted as "heads/branch", not just "branch".
  ///
  /// API docs: https://developer.github.com/v3/git/refs/#get-a-reference
  Future<GitReference> getReference(RepositorySlug slug, String ref) {
    return _github.getJSON('/repos/${slug.fullName}/git/refs/${ref}',
        convert: GitReference.fromJSON,
        statusCode: StatusCodes.OK) as Future<GitReference>;
  }

  /// Lists the references in a repository.
  ///
  /// This will return all references on the system, including things like notes
  /// and stashes if they exist on the server. A sub-namespace can be requested
  /// by specifying a [type], the most common being "heads" and "tags".
  ///
  /// API docs: https://developer.github.com/v3/git/refs/#get-all-references
  Stream<GitReference> listReferences(RepositorySlug slug, {String type}) {
    String path = '/repos/${slug.fullName}/git/refs';
    if (type != null) {
      path += '/$type';
    }

    return new PaginationHelper(_github)
        .objects('GET', path, GitReference.fromJSON) as Stream<GitReference>;
  }

  /// Creates a new reference in a repository.
  ///
  /// The [ref] is the name of the fully qualified reference
  /// (ie: refs/heads/master).
  ///
  /// API docs: https://developer.github.com/v3/git/refs/#create-a-reference
  Future<GitReference> createReference(
      RepositorySlug slug, String ref, String sha) {
    return _github.postJSON('/repos/${slug.fullName}/git/refs',
        convert: GitReference.fromJSON,
        statusCode: StatusCodes.CREATED,
        body: JSON.encode({'ref': ref, 'sha': sha})) as Future<GitReference>;
  }

  /// Updates a reference in a repository.
  ///
  /// API docs: https://developer.github.com/v3/git/refs/#update-a-reference
  Future<GitReference> editReference(
      RepositorySlug slug, String ref, String sha,
      {bool force: false}) {
    String body = JSON.encode({'sha': sha, 'force': force});
    // Somehow the reference updates PATCH request needs a valid content-length.
    var headers = {'content-length': body.length.toString()};

    return _github
        .request('PATCH', '/repos/${slug.fullName}/git/refs/${ref}',
            body: body, headers: headers)
        .then((response) {
      return GitReference
          .fromJSON(JSON.decode(response.body) as Map<String, dynamic>);
    });
  }

  /// Deletes a reference.
  ///
  /// API docs: https://developer.github.com/v3/git/refs/#delete-a-reference
  Future<bool> deleteReference(RepositorySlug slug, String ref) {
    return _github
        .request("DELETE", "/repos/${slug.fullName}/git/refs/${ref}")
        .then((response) => response.statusCode == StatusCodes.NO_CONTENT);
  }

  /// Fetches a tag from the repo given a SHA.
  ///
  /// API docs: https://developer.github.com/v3/git/tags/#get-a-tag
  Future<GitTag> getTag(RepositorySlug slug, String sha) {
    return _github.getJSON('/repos/${slug.fullName}/git/tags/${sha}',
        convert: GitTag.fromJSON, statusCode: StatusCodes.OK) as Future<GitTag>;
  }

  /// Creates a new tag in a repository.
  ///
  /// API docs: https://developer.github.com/v3/git/tags/#create-a-tag-object
  Future<GitTag> createTag(RepositorySlug slug, CreateGitTag tag) {
    return _github.postJSON('/repos/${slug.fullName}/git/tags',
        convert: GitTag.fromJSON,
        statusCode: StatusCodes.CREATED,
        body: tag.toJSON()) as Future<GitTag>;
  }

  /// Fetches a tree from a repository for the given ref [sha].
  ///
  /// If [recursive] is set to true, the tree is fetched recursively.
  ///
  /// API docs: https://developer.github.com/v3/git/trees/#get-a-tree
  /// and https://developer.github.com/v3/git/trees/#get-a-tree-recursively
  Future<GitTree> getTree(RepositorySlug slug, String sha,
      {bool recursive: false}) {
    var path = '/repos/${slug.fullName}/git/trees/${sha}';
    if (recursive) {
      path += '?recursive=1';
    }

    return _github.getJSON(path,
        convert: GitTree.fromJSON,
        statusCode: StatusCodes.OK) as Future<GitTree>;
  }

  /// Creates a new tree in a repository.
  ///
  /// API docs: https://developer.github.com/v3/git/trees/#create-a-tree
  Future<GitTree> createTree(RepositorySlug slug, CreateGitTree tree) {
    return _github.postJSON('/repos/${slug.fullName}/git/trees',
        convert: GitTree.fromJSON,
        statusCode: StatusCodes.CREATED,
        body: tree.toJSON()) as Future<GitTree>;
  }

  Future<BranchProtection> getBranchProtection(
      RepositorySlug slug, String branchName) {
    return _github.getJSON(
        '/repos/${slug.fullName}/branches/$branchName/protection',
        statusCode: StatusCodes.OK,
        preview: 'application/vnd.github.loki-preview+json',
        convert: BranchProtection.fromJSON) as Future<BranchProtection>;
  }

  Future<bool> updateBranchProtection(
      RepositorySlug slug,
      String branchName,
      RequiredStatusChecks requiredStatusChecks,
      Restrictions restrictions) async {
    var body = {}
      ..addAll(requiredStatusChecks.toMap())
      ..addAll(restrictions.toMap());

    var path = '/repos/${slug.fullName}/branches/$branchName/protection';
    var r = await _github.request('PUT', path,
        preview: 'application/vnd.github.loki-preview+json',
        body: JSON.encode(body));

    if (r.statusCode != StatusCodes.OK) {
      print(r.body);
    }
    return r.statusCode == StatusCodes.OK;
  }
}
