part of github.common;

/// Model class for a commit in a repository.
///
/// Note: The [RepositoryCommit] wraps a [GitCommit], so author/committer
/// information is in two places, but contain different details about them:
/// in [RepositoryCommit] "github details", in [GitCommit] "git details".
@immutable
class RepositoryCommit {
  /// API url.
  final String url;

  /// Commit SHA
  final String sha;

  /// Url to Commit Page
  @JsonKey(name: "html_url")
  final String htmlUrl;

  /// Comments url.
  @JsonKey(name: "comments_url")
  final String commentsUrl;

  /// A reference to the raw [GitCommit].
  final GitCommit commit;

  /// Commit Author
  final User author;

  /// Commit Committer.
  final User committer;

  /// Commit parents.
  final List<GitCommit> parents;

  /// Commit statistics.
  final CommitStats stats;

  /// The files changed in this commit.
  final List<CommitFile> files;

  const RepositoryCommit._({
    @required this.url,
    @required this.sha,
    @required this.htmlUrl,
    @required this.commentsUrl,
    @required this.commit,
    @required this.author,
    @required this.committer,
    @required this.stats,
    @required this.files,
    @required this.parents,
  });

  factory RepositoryCommit.fromJSON(Map<String, dynamic> input) {
    if (input == null) return null;

    final List<GitCommit> parents = input['parents'] != null
        ? (input['parents'] as List<dynamic>)
            .map((parent) => GitCommit.fromJson(parent))
            .toList()
        : null;

    final List<CommitFile> files = input['files'] != null
        ? (input['files'] as List<dynamic>)
            .map((file) => CommitFile.fromJSON(file))
            .toList()
        : null;

    return RepositoryCommit._(
      url: input['url'],
      sha: input['sha'],
      htmlUrl: input['html_url'],
      commentsUrl: input['comments_url'],
      commit: GitCommit.fromJSON(input['commit'] as Map<String, dynamic>),
      author: User.fromJson(input['author'] as Map<String, dynamic>),
      committer: User.fromJson(input['committer'] as Map<String, dynamic>),
      stats: CommitStats.fromJSON(input['stats'] as Map<String, dynamic>),
      parents: parents,
      files: files,
    );
  }
}

/// Model class for commit statistics.
@immutable
class CommitStats {
  /// Number of Additions.
  final int additions;

  /// Number of Deletions.
  final int deletions;

  /// Total changes.
  final int total;

  const CommitStats._({
    @required this.additions,
    @required this.deletions,
    @required this.total,
  });

  factory CommitStats.fromJSON(Map<String, dynamic> input) {
    if (input == null) return null;

    return CommitStats._(
      additions: input['additions'],
      deletions: input['deletions'],
      total: input['total'],
    );
  }
}

/// Model class of a file that was changed in a commit.
@immutable
class CommitFile {
  @JsonKey(name: "filename")
  final String name;

  final int additions;
  final int deletions;
  final int changes;
  final String status;

  @JsonKey(name: "raw_url")
  final String rawUrl;

  @JsonKey(name: "blob_url")
  final String blobUrl;

  final String patch;

  final Map<String, dynamic> json;

  const CommitFile._({
    @required this.name,
    @required this.additions,
    @required this.deletions,
    @required this.changes,
    @required this.status,
    @required this.rawUrl,
    @required this.blobUrl,
    @required this.patch,
    @required this.json,
  });

  factory CommitFile.fromJSON(Map<String, dynamic> input) {
    if (input == null) return null;

    return CommitFile._(
      name: input['filename'],
      additions: input['additions'],
      deletions: input['deletions'],
      changes: input['changes'],
      status: input['status'],
      rawUrl: input['raw_url'],
      blobUrl: input['blob_url'],
      patch: input['patch'],
      json: input,
    );
  }
}

/// Model class for a commit comment.
///
/// See https://developer.github.com/v3/repos/comments
@immutable
class CommitComment {
  /// Id of the comment
  final int id;

  /// Relative path of the file on which the comment has been posted
  final String path;

  /// Line on file
  final int line;

  /// Position on the diff
  final int position;

  /// SHA of the commit where the comment has been made
  final String commitId;

  final DateTime createdAt;

  /// Can be equals to [createdAt]
  final DateTime updatedAt;

  /// https://github.com/...
  final String htmlUrl;

  /// https://api.github.com/...
  final String apiUrl;

  /// Content of the comment
  final String body;

  const CommitComment._({
    @required this.id,
    @required this.line,
    @required this.position,
    @required this.path,
    @required this.apiUrl,
    @required this.commitId,
    @required this.createdAt,
    @required this.htmlUrl,
    @required this.updatedAt,
    @required this.body,
  });

  factory CommitComment.fromJSON(Map<String, dynamic> input) {
    return CommitComment._(
      id: input['id'],
      htmlUrl: input['html_url'],
      apiUrl: input['url'],
      body: input['body'],
      path: input['path'],
      position: input['position'],
      line: input['line'],
      commitId: input['commit_id'],
      createdAt: DateTime.parse(input['created_at']),
      updatedAt: DateTime.parse(input['updated_at']),
    );
  }
}
