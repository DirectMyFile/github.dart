part of github.common;

/// Model class for a repository.
class Repository {
  /// Repository Name
  String name;

  /// Repository ID
  int id;

  /// Full Repository Name
  @ApiName("full_name")
  String fullName;

  /// Repository Owner
  UserInformation owner;

  /// If the Repository is Private
  @ApiName("private")
  bool isPrivate;

  /// If the Repository is a fork
  @ApiName("fork")
  bool isFork;

  /// Url to the GitHub Repository Page
  @ApiName("html_url")
  String htmlUrl;

  /// Repository Description
  String description;

  /// Repository Clone Urls
  @ApiName("clone_urls")
  CloneUrls cloneUrls;

  /// Url to the Repository Homepage
  String homepage;

  /// Repository Size
  int size;

  /// Repository Stars
  @ApiName("stargazers_count")
  int stargazersCount;

  /// Repository Watchers
  @ApiName("watchers_count")
  int watchersCount;

  /// Repository Language
  String language;

  /// If the Repository has Issues Enabled
  @ApiName("has_issues")
  bool hasIssues;

  /// If the Repository has the Wiki Enabled
  @ApiName("has_wiki")
  bool hasWiki;

  /// If the Repository has any Downloads
  @ApiName("has_downloads")
  bool hasDownloads;

  /// Number of Forks
  @ApiName("forks_count")
  int forksCount;

  /// Number of Open Issues
  @ApiName("open_issues_count")
  int openIssuesCount;

  /// Repository Default Branch
  String defaultBranch;

  /// Number of Subscribers
  @ApiName("subscribers_count")
  int subscribersCount;

  /// Number of users in the network
  @ApiName("network_count")
  int networkCount;

  /// The time the repository was created at
  @ApiName("created_at")
  DateTime createdAt;

  /// The last time the repository was pushed at
  @ApiName("pushed_at")
  DateTime pushedAt;

  static Repository fromJSON(Map<String, dynamic> input,
      [Repository instance]) {
    if (input == null) return null;

    if (instance == null) instance = new Repository();

    return instance
      ..name = input['name']
      ..id = input['id']
      ..fullName = input['full_name']
      ..isFork = input['fork']
      ..htmlUrl = input['html_url']
      ..description = input['description']
      ..cloneUrls = CloneUrls.fromJSON(input)
      ..homepage = input['homepage']
      ..size = input['size']
      ..stargazersCount = input['stargazers_count']
      ..watchersCount = input['watchers_count']
      ..language = input['language']
      ..hasIssues = input['has_issues']
      ..hasDownloads = input['has_downloads']
      ..hasWiki = input['has_wiki']
      ..defaultBranch = input['default_branch']
      ..openIssuesCount = input['open_issues_count']
      ..networkCount = input['network_count']
      ..subscribersCount = input['subscribers_count']
      ..forksCount = input['forks_count']
      ..createdAt = parseDateTime(input['created_at'])
      ..pushedAt = parseDateTime(input['pushed_at'])
      ..isPrivate = input['private']
      ..owner =
          UserInformation.fromJSON(input['owner'] as Map<String, dynamic>);
  }

  /// Gets the Repository Slug (Full Name).
  RepositorySlug slug() => new RepositorySlug(owner.login, name);

  @override
  String toString() => 'Repository: ${owner.login}/$name';
}

/// Repository Clone Urls
class CloneUrls {
  /// Git Protocol
  ///
  /// git://github.com/user/repo.git
  String git;

  /// SSH Protocol
  ///
  /// git@github.com:user/repo.git
  String ssh;

  /// HTTPS Protocol
  ///
  /// https://github.com/user/repo.git
  String https;

  /// Subversion Protocol
  ///
  /// https://github.com/user/repo
  String svn;

  static CloneUrls fromJSON(Map<String, dynamic> input) {
    if (input == null) return null;

    return new CloneUrls()
      ..git = input['git_url']
      ..ssh = input['ssh_url']
      ..https = input['clone_url']
      ..svn = input['svn_url'];
  }
}

class Tag {
  String name;
  CommitInfo commit;
  String zipUrl;
  String tarUrl;

  static Tag fromJSON(Map<String, dynamic> input) {
    if (input == null) {
      return null;
    }

    return new Tag()
      ..name = input['name']
      ..commit = CommitInfo.fromJson(input['commit'] as Map<String, dynamic>)
      ..tarUrl = input['tarball_url']
      ..zipUrl = input['zipball_url'];
  }

  @override
  String toString() => 'Tag: $name';
}

class CommitInfo {
  String sha;
  GitTree tree;

  static CommitInfo fromJson(Map<String, dynamic> input) {
    if (input == null) {
      return null;
    }

    return new CommitInfo()
      ..sha = input['sha']
      ..tree =
          GitTree.fromJSON(input['commit']['tree'] as Map<String, dynamic>);
  }
}

/// User Information
class UserInformation {
  /// Owner Username
  String login;

  /// Owner ID
  int id;

  /// Avatar Url
  @ApiName("avatar_url")
  String avatarUrl;

  /// Url to the user's GitHub Profile
  @ApiName("html_url")
  String htmlUrl;

  static UserInformation fromJSON(Map<String, dynamic> input) {
    if (input == null) return null;

    return new UserInformation()
      ..login = input['login']
      ..id = input['id']
      ..avatarUrl = input['avatar_url']
      ..htmlUrl = input['html_url'];
  }
}

/// A Repository Slug
class RepositorySlug {
  /// Repository Owner
  final String owner;

  /// Repository Name
  final String name;

  RepositorySlug(this.owner, this.name);

  /// Creates a Repository Slug from a full name.
  factory RepositorySlug.full(String f) {
    var split = f.split("/");
    var o = split[0];
    var n = (split..removeAt(0)).join("/");
    return new RepositorySlug(o, n);
  }

  /// The Full Name of the Repository
  ///
  /// Example: owner/name
  String get fullName => "${owner}/${name}";

  @override
  bool operator ==(Object obj) =>
      obj is RepositorySlug && obj.fullName == fullName;

  @override
  int get hashCode => fullName.hashCode;

  @override
  String toString() => "${owner}/${name}";
}

/// Model class for a new repository to be created.
class CreateRepository {
  /// Repository Name
  final String name;

  /// Repository Description
  String description;

  /// Repository Homepage
  String homepage;

  /// If the repository should be private or not.
  bool private = false;

  /// If the repository should have issues enabled.
  @ApiName("has_issues")
  bool hasIssues = true;

  /// If the repository should have the wiki enabled.
  @ApiName("has_wiki")
  bool hasWiki = true;

  /// If the repository should have downloads enabled.
  @ApiName("has_downloads")
  bool hasDownloads = true;

  /// The Team ID (Only for Creating a Repository for an Organization)
  @OnlyWhen("Creating a repository for an organization")
  @ApiName("team_id")
  int teamID;

  /// If GitHub should auto initialize the repository.
  @ApiName("auto_init")
  bool autoInit = false;

  /// .gitignore template (only when [autoInit] is true)
  @OnlyWhen("autoInit is true")
  String gitignoreTemplate;

  /// License template (only when [autoInit] is true)
  @OnlyWhen("autoInit is true")
  String licenseTemplate;

  CreateRepository(this.name);

  String toJSON() {
    return JSON.encode({
      "name": name,
      "description": description,
      "homepage": homepage,
      "private": private,
      "has_issues": hasIssues,
      "has_wiki": hasWiki,
      "has_downloads": hasDownloads,
      "team_id": teamID,
      "auto_init": autoInit,
      "gitignore_template": gitignoreTemplate,
      "license_template": licenseTemplate
    });
  }
}

/// Model class for a branch.
class Branch {
  /// The name of the branch.
  String name;

  /// Commit Information
  CommitInfo commit;

  static Branch fromJSON(Map<String, dynamic> input) {
    if (input == null) return null;

    var branch = new Branch()
      ..name = input['name']
      ..commit = CommitInfo.fromJson(input['commit'] as Map<String, dynamic>);

    return branch;
  }
}

class BranchProtection {
  RequiredStatusChecks requiredStatusChecks;

  static BranchProtection fromJSON(Map<String, dynamic> input) {
    var branchProtection = new BranchProtection()
      ..requiredStatusChecks = RequiredStatusChecks
          .fromJSON(input['required_status_checks'] as Map<String, dynamic>);
    return branchProtection;
  }
}

class Restrictions {
  Map<String, dynamic> toMap() {
    return {
      'restrictions': {}
    };
  }
}

class RequiredStatusChecks {
  List<String> contexts = <String>[];
  bool strict;
  bool includeAdmins;

  static RequiredStatusChecks fromJSON(Map<String, dynamic> input) {
    var requiredStatusChecks = new RequiredStatusChecks()
      ..strict = input['strict']
      ..includeAdmins = input['include_admins']
      ..contexts = input['contexts'] as List<String>;

    return requiredStatusChecks;
  }

  Map toMap() {
    return {
      'required_status_checks': {
        'strict': strict,
        'include_admins': includeAdmins,
        'contexts': contexts
      }
    };
  }

  String toJson() => JSON.encode(toMap());
}

/// A Breakdown of the Languages a repository uses.
class LanguageBreakdown {
  final Map<String, int> _data;

  LanguageBreakdown(Map<String, int> data) : _data = data;

  /// The Primary Language
  String get primary {
    var list = mapToList(_data);
    list.sort((a, b) {
      return a.value.compareTo(b.value);
    });
    return list.first.key;
  }

  /// Names of Languages Used
  List<String> get names => _data.keys.toList()..sort();

  /// Actual Information
  ///
  /// This is a Map of the Language Name to the Number of Bytes of that language in the repository.
  Map<String, int> get info => _data;

  /// Creates a list of lists with a tuple of the language name and the bytes.
  List<List<dynamic>> toList() {
    var out = <List<dynamic>>[];
    for (var key in info.keys) {
      out.add([key, info[key]]);
    }
    return out;
  }

  @override
  String toString() {
    var buffer = new StringBuffer();
    _data.forEach((key, value) {
      buffer.writeln("${key}: ${value}");
    });
    return buffer.toString();
  }
}
