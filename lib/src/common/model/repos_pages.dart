part of github.common;

/// GitHub Pages Information
@immutable
class RepositoryPages {
  /// Pages CNAME
  final String cname;

  /// Pages Status
  final String status;

  /// If the repo has a custom 404
  @JsonKey(name: "custom_404")
  final bool hasCustom404;

  const RepositoryPages._({
    @required this.cname,
    @required this.status,
    @required this.hasCustom404,
  });

  factory RepositoryPages.fromJSON(Map<String, dynamic> input) {
    if (input == null) return null;

    return RepositoryPages._(
      cname: input['cname'],
      status: input['status'],
      hasCustom404: input['custom_404'],
    );
  }
}

@immutable
class PageBuild {
  final String url;
  final String status;
  final PageBuildError error;
  final PageBuildPusher pusher;
  final String commit;
  final int duration;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PageBuild._({
    @required this.url,
    @required this.status,
    @required this.error,
    @required this.pusher,
    @required this.commit,
    @required this.duration,
    @required this.createdAt,
    @required this.updatedAt,
  });

  factory PageBuild._fromJSON(Map<String, dynamic> input) {
    if (input == null) return null;
    return PageBuild._(
      url: input["url"],
      status: input["status"],
      error: PageBuildError._fromJSON(input["error"] as Map<String, dynamic>),
      pusher:
          PageBuildPusher._fromJSON(input["pusher"] as Map<String, dynamic>),
      commit: input["commit"],
      duration: input["duration"],
      createdAt: parseDateTime(input["created_at"]),
      updatedAt: parseDateTime(input["updated_at"]),
    );
  }
}

@immutable
class PageBuildPusher {
  final String login;
  final int id;
  final String apiUrl;
  final String htmlUrl;
  final String type;
  final bool siteAdmin;

  const PageBuildPusher._({
    @required this.login,
    @required this.id,
    @required this.apiUrl,
    @required this.htmlUrl,
    @required this.type,
    @required this.siteAdmin,
  });

  factory PageBuildPusher._fromJSON(Map<String, dynamic> input) {
    if (input == null) return null;
    return PageBuildPusher._(
      login: input["login"],
      id: input["id"],
      apiUrl: input["url"],
      htmlUrl: input["html_url"],
      type: input["type"],
      siteAdmin: input["site_admin"],
    );
  }
}

@immutable
class PageBuildError {
  final String message;
  const PageBuildError._({@required this.message});

  factory PageBuildError._fromJSON(Map<String, dynamic> input) {
    if (input == null) return null;
    return PageBuildError._(
      message: input["message"],
    );
  }
}
