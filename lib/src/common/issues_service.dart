import 'dart:async';
import 'dart:convert';

import 'package:github/src/common.dart';
import 'package:github/src/common/model/users.dart';
import 'package:github/src/common/util/pagination.dart';

/// The [IssuesService] handles communication with issues related methods of the
/// GitHub API.
///
/// API docs: https://developer.github.com/v3/issues/
class IssuesService extends Service {
  IssuesService(GitHub github) : super(github);

  /// List all issues across all the authenticated user’s visible repositories
  /// including owned repositories, member repositories, and organization repositories
  ///
  /// API docs: https://developer.github.com/v3/issues/#list-issues
  Stream<Issue> listAll(
      {int? milestoneNumber,
      String? state,
      String? direction,
      String? sort,
      DateTime? since,
      int? perPage,
      List<String>? labels}) {
    return _listIssues('/issues', milestoneNumber, state, direction, sort,
        since, perPage, labels);
  }

  /// List all issues across owned and member repositories for the authenticated
  /// user.
  ///
  /// API docs: https://developer.github.com/v3/issues/#list-issues
  Stream<Issue> listByUser(
      {int? milestoneNumber,
      String? state,
      String? direction,
      String? sort,
      DateTime? since,
      int? perPage,
      List<String>? labels}) {
    return _listIssues('/user/issues', milestoneNumber, state, direction, sort,
        since, perPage, labels);
  }

  /// List all issues for a given organization for the authenticated user.
  ///
  /// API docs: https://developer.github.com/v3/issues/#list-issues
  Stream<Issue> listByOrg(String org,
      {int? milestoneNumber,
      String? state,
      String? direction,
      String? sort,
      DateTime? since,
      int? perPage,
      List<String>? labels}) {
    return _listIssues('/orgs/$org/issues', milestoneNumber, state, direction,
        sort, since, perPage, labels);
  }

  /// Lists the issues for the specified repository.
  ///
  /// TODO: Implement more optional parameters.
  ///
  /// API docs:https://developer.github.com/v3/issues/#list-issues-for-a-repository
  Stream<Issue> listByRepo(RepositorySlug slug,
      {int? milestoneNumber,
      String? state,
      String? direction,
      String? sort,
      DateTime? since,
      int? perPage,
      List<String>? labels}) {
    return _listIssues('/repos/${slug.fullName}/issues', milestoneNumber, state,
        direction, sort, since, perPage, labels);
  }

  Stream<Issue> _listIssues(
      String pathSegment,
      int? milestoneNumber,
      String? state,
      String? direction,
      String? sort,
      DateTime? since,
      int? perPage,
      List<String>? labels) {
    final params = <String, dynamic>{};

    if (perPage != null) {
      params['per_page'] = perPage.toString();
    }

    if (milestoneNumber != null) {
      // should be a milestone number (e.g. '34') not a milestone title
      // (e.g. '1.15')
      params['milestone'] = milestoneNumber.toString();
    }

    if (state != null) {
      // should be `open`, `closed` or `all`
      params['state'] = state;
    }

    if (direction != null) {
      // should be `desc` or `asc`
      params['direction'] = direction;
    }

    if (sort != null) {
      // should be `created`, `updated`, `comments`
      params['sort'] = sort;
    }

    if (since != null) {
      // Only issues updated at or after this time are returned.
      // This is a timestamp in ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ.
      params['since'] = since.toUtc().toIso8601String();
    }

    if (labels != null && labels.isNotEmpty) {
      params['labels'] = labels.join(',');
    }

    return PaginationHelper(github).objects(
      'GET',
      pathSegment,
      (dynamic i) => Issue.fromJson(i),
      params: params,
    );
  }

  /// Gets a stream of [Reaction]s for an issue.
  /// The optional content param let's you filter the request for only reactions
  /// of that type.
  /// WARNING: ReactionType.plusOne and ReactionType.minusOne currently do not
  /// work and will throw an exception is used. All others without + or - signs
  /// work fine to filter.
  ///
  /// This API is currently in preview. It may break.
  ///
  /// See https://developer.github.com/v3/reactions/
  Stream<Reaction> listReactions(RepositorySlug slug, int issueNumber,
      {ReactionType? content}) {
    var query = content != null ? '?content=${content.content}' : '';
    return PaginationHelper(github).objects(
      'GET',
      '/repos/${slug.owner}/${slug.name}/issues/$issueNumber/reactions$query',
      (dynamic i) => Reaction.fromJson(i),
      headers: {
        'Accept': 'application/vnd.github.squirrel-girl-preview+json',
      },
    );
  }

  /// Edit an issue.
  ///
  /// API docs: https://developer.github.com/v3/issues/#edit-an-issue
  Future<Issue> edit(
      RepositorySlug slug, int issueNumber, IssueRequest issue) async {
    return github
        .request('PATCH', '/repos/${slug.fullName}/issues/$issueNumber',
            body: GitHubJson.encode(issue))
        .then<Issue>((response) {
      return Issue.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    });
  }

  /// Get an issue.
  ///
  /// API docs: https://developer.github.com/v3/issues/#get-a-single-issue
  Future<Issue> get(RepositorySlug slug, int issueNumber) =>
      github.getJSON('/repos/${slug.fullName}/issues/$issueNumber',
          convert: (dynamic i) => Issue.fromJson(i));

  /// Create an issue.
  ///
  /// API docs: https://developer.github.com/v3/issues/#create-an-issue
  Future<Issue> create(RepositorySlug slug, IssueRequest issue) async {
    final response = await github.request(
      'POST',
      '/repos/${slug.fullName}/issues',
      body: GitHubJson.encode(issue),
    );

    if (StatusCodes.isClientError(response.statusCode)) {
      //TODO: throw a more friendly error – better this than silent failure
      throw GitHubError(github, response.body);
    }

    return Issue.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Lists all available assignees (owners and collaborators) to which issues
  /// may be assigned.
  ///
  /// API docs: https://developer.github.com/v3/issues/assignees/#list-assignees
  Stream<User> listAssignees(RepositorySlug slug) {
    return PaginationHelper(github).objects('GET',
        '/repos/${slug.fullName}/assignees', (dynamic i) => User.fromJson(i));
  }

  /// Checks if a user is an assignee for the specified repository.
  ///
  /// API docs: https://developer.github.com/v3/issues/assignees/#check-assignee
  Future<bool> isAssignee(RepositorySlug slug, String repoName) {
    return github
        .request('GET', '/repos/${slug.fullName}/assignees/$repoName')
        .then((response) => response.statusCode == StatusCodes.NO_CONTENT);
  }

  /// Lists comments on the specified issue.
  ///
  /// API docs: https://developer.github.com/v3/issues/comments/#list-comments-on-an-issue
  Stream<IssueComment> listCommentsByIssue(
      RepositorySlug slug, int issueNumber) {
    return PaginationHelper(github).objects(
        'GET',
        '/repos/${slug.fullName}/issues/$issueNumber/comments',
        (dynamic i) => IssueComment.fromJson(i));
  }

  /// Lists all comments in a repository.
  ///
  /// API docs: https://developer.github.com/v3/issues/comments/#list-comments-on-an-issue
  Stream<IssueComment> listCommentsByRepo(RepositorySlug slug) {
    return PaginationHelper(github).objects(
        'GET',
        '/repos/${slug.fullName}/issues/comments',
        (dynamic i) => IssueComment.fromJson(i));
  }

  /// Fetches the specified issue comment.
  ///
  /// API docs: https://developer.github.com/v3/issues/comments/#get-a-single-comment
  Future<IssueComment> getComment(RepositorySlug slug, int id) =>
      github.getJSON('/repos/${slug.fullName}/issues/comments/$id',
          convert: (dynamic i) => IssueComment.fromJson(i));

  /// Creates a new comment on the specified issue
  ///
  /// API docs: https://developer.github.com/v3/issues/comments/#create-a-comment
  Future<IssueComment> createComment(
      RepositorySlug slug, int issueNumber, String body) {
    final it = GitHubJson.encode({'body': body});
    return github.postJSON(
      '/repos/${slug.fullName}/issues/$issueNumber/comments',
      body: it,
      convert: (dynamic i) => IssueComment.fromJson(i),
      statusCode: StatusCodes.CREATED,
    );
  }

  /// Updates an issue comment
  ///
  /// API docs: https://docs.github.com/en/rest/reference/issues#update-an-issue-comment
  Future<bool> updateComment(RepositorySlug slug, int id, String body) {
    final it = GitHubJson.encode({'body': body});
    return github
        .request('PATCH', '/repos/${slug.fullName}/issues/comments/$id',
            body: it)
        .then((response) => response.statusCode == StatusCodes.OK);
  }

  /// Deletes an issue comment.
  ///
  /// API docs: https://developer.github.com/v3/issues/comments/#delete-a-comment
  Future<bool> deleteComment(RepositorySlug slug, int id) {
    return github
        .request('DELETE', '/repos/${slug.fullName}/issues/comments/$id')
        .then((response) => response.statusCode == StatusCodes.NO_CONTENT);
  }

  // TODO: Implement issues events methods: https://developer.github.com/v3/issues/events/

  /// Lists all labels for a repository.
  ///
  /// API docs: https://developer.github.com/v3/issues/labels/#list-all-labels-for-this-repository
  Stream<IssueLabel> listLabels(RepositorySlug slug) {
    return PaginationHelper(github).objects(
        'GET',
        '/repos/${slug.fullName}/labels',
        (dynamic i) => IssueLabel.fromJson(i));
  }

  /// Fetches a single label.
  ///
  /// API docs: https://developer.github.com/v3/issues/labels/#get-a-single-label
  Future<IssueLabel> getLabel(RepositorySlug slug, String name) =>
      github.getJSON('/repos/${slug.fullName}/labels/$name',
          convert: (dynamic i) => IssueLabel.fromJson(i),
          statusCode: StatusCodes.OK);

  /// Creates a new label on the specified repository.
  ///
  /// API docs: https://developer.github.com/v3/issues/labels/#create-a-label
  Future<IssueLabel> createLabel(
      RepositorySlug slug, String name, String color) {
    return github.postJSON('/repos/${slug.fullName}/labels',
        body: GitHubJson.encode({'name': name, 'color': color}),
        convert: (dynamic i) => IssueLabel.fromJson(i));
  }

  /// Edits a label.
  ///
  /// API docs: https://developer.github.com/v3/issues/labels/#update-a-label
  Future<IssueLabel> editLabel(RepositorySlug slug, String name, String color) {
    return github.postJSON('/repos/${slug.fullName}/labels/$name',
        body: GitHubJson.encode({'name': name, 'color': color}),
        convert: (dynamic i) => IssueLabel.fromJson(i));
  }

  /// Deletes a label.
  ///
  /// API docs: https://developer.github.com/v3/issues/labels/#delete-a-label
  Future<bool> deleteLabel(RepositorySlug slug, String name) async {
    final response =
        await github.request('DELETE', '/repos/${slug.fullName}/labels/$name');

    return response.statusCode == StatusCodes.NO_CONTENT;
  }

  /// Lists all labels for an issue.
  ///
  /// API docs: https://developer.github.com/v3/issues/labels/#list-all-labels-for-this-repository
  Stream<IssueLabel> listLabelsByIssue(RepositorySlug slug, int issueNumber) {
    return PaginationHelper(github).objects(
        'GET',
        '/repos/${slug.fullName}/issues/$issueNumber/labels',
        (dynamic i) => IssueLabel.fromJson(i));
  }

  /// Adds labels to an issue.
  ///
  /// API docs: https://developer.github.com/v3/issues/labels/#add-labels-to-an-issue
  Future<List<IssueLabel>> addLabelsToIssue(
      RepositorySlug slug, int issueNumber, List<String> labels) {
    return github.postJSON<List<dynamic>, List<IssueLabel>>(
      '/repos/${slug.fullName}/issues/$issueNumber/labels',
      body: GitHubJson.encode(labels),
      convert: (input) => input
          .cast<Map<String, dynamic>>()
          .map((i) => IssueLabel.fromJson(i))
          .toList(),
    );
  }

  /// Replaces all labels for an issue.
  ///
  /// API docs: https://developer.github.com/v3/issues/labels/#replace-all-labels-for-an-issue
  Future<List<IssueLabel>> replaceLabelsForIssue(
      RepositorySlug slug, int issueNumber, List<String> labels) {
    return github
        .request('PUT', '/repos/${slug.fullName}/issues/$issueNumber/labels',
            body: GitHubJson.encode(labels))
        .then((response) {
      return jsonDecode(response.body)
          .map((Map<String, dynamic> it) => IssueLabel.fromJson(it));
    });
  }

  /// Removes a label for an issue.
  ///
  /// API docs: https://developer.github.com/v3/issues/labels/#remove-a-label-from-an-issue
  Future<bool> removeLabelForIssue(
      RepositorySlug slug, int issueNumber, String label) async {
    final response = await github.request(
        'DELETE', '/repos/${slug.fullName}/issues/$issueNumber/labels/$label');

    return response.statusCode == StatusCodes.OK;
  }

  /// Removes all labels for an issue.
  ///
  /// API docs: https://developer.github.com/v3/issues/labels/#remove-all-labels-from-an-issue
  Future<bool> removeAllLabelsForIssue(RepositorySlug slug, int issueNumber) {
    return github
        .request('DELETE', '/repos/${slug.fullName}/issues/$issueNumber/labels')
        .then((response) => response.statusCode == StatusCodes.NO_CONTENT);
  }

  /// Get labels for issues in a milestone
  ///
  /// API docs: https://docs.github.com/en/rest/reference/issues#list-labels-for-issues-in-a-milestone
  Stream<IssueLabel> listLabelsByMilestone(RepositorySlug slug, int number) {
    return PaginationHelper(github).objects(
        'GET',
        '/repos/${slug.fullName}/milestones/$number/labels',
        (i) => IssueLabel.fromJson(i));
  }

  /// Lists all milestones for a repository.
  ///
  /// API docs: https://developer.github.com/v3/issues/milestones/#list-milestones-for-a-repository
  Stream<Milestone> listMilestones(RepositorySlug slug) {
    return PaginationHelper(github).objects(
        'GET',
        '/repos/${slug.fullName}/milestones',
        (dynamic i) => Milestone.fromJson(i));
  }

  /// Fetches a single milestone
  ///
  /// API docs: https://docs.github.com/en/rest/reference/issues#get-a-milestone
  Future<Milestone> getMilestone(RepositorySlug slug, int number) {
    return github.getJSON('/repos/${slug.fullName}/milestones/$number',
        convert: (i) => Milestone.fromJson(i));
  }

  /// Creates a new milestone on the specified repository.
  ///
  /// API docs: https://developer.github.com/v3/issues/milestones/#create-a-milestone
  Future<Milestone> createMilestone(
      RepositorySlug slug, CreateMilestone request) {
    return github.postJSON('/repos/${slug.fullName}/milestones',
        body: GitHubJson.encode(request),
        convert: (dynamic i) => Milestone.fromJson(i));
  }

  /// Updates a milestone
  ///
  /// API docs: https://docs.github.com/en/rest/reference/issues#update-a-milestone
  Future<bool> updateMilestone(RepositorySlug slug, int number, String title) {
    final it = GitHubJson.encode({'title': title});
    return github
        .request('PATCH', '/repos/${slug.fullName}/milestones/$number',
            body: it)
        .then((response) => response.statusCode == StatusCodes.OK);
  }

  /// Deletes a milestone.
  ///
  /// API docs: https://developer.github.com/v3/issues/milestones/#delete-a-milestone
  Future<bool> deleteMilestone(RepositorySlug slug, int number) {
    return github
        .request('DELETE', '/repos/${slug.fullName}/milestones/$number')
        .then((response) => response.statusCode == StatusCodes.NO_CONTENT);
  }
}
