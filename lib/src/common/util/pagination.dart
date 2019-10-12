import "dart:async";
import "dart:convert" show jsonDecode;

import "package:http/http.dart" as http;

import '../../common.dart';

/// Internal Helper for dealing with GitHub Pagination.
class PaginationHelper {
  final GitHub github;

  PaginationHelper(this.github);

  Stream<http.Response> fetchStreamed(String method, String path,
      {int pages,
      Map<String, String> headers,
      Map<String, dynamic> params,
      String body,
      int statusCode = 200}) async* {
    int count = 0;

    if (params == null) {
      params = {};
    } else {
      params = Map.from(params);
    }
    assert(!params.containsKey('page'));

    do {
      final response = await github.request(method, path,
          headers: headers, params: params, body: body, statusCode: statusCode);

      yield response;

      count++;

      if (pages != null && count >= pages) {
        break;
      }

      final link = response.headers['link'];

      if (link == null) {
        break;
      }

      final info = parseLinkHeader(link);
      if (info == null) {
        break;
      }

      final next = info['next'];

      if (next == null) {
        break;
      }

      final nextUrl = Uri.parse(next);
      final nextPageArg = nextUrl.queryParameters['page'];
      assert(nextPageArg != null);
      params['page'] = nextPageArg;
    } while (true);
  }

  Stream<T> jsonObjects<T>(
    String method,
    String path, {
    int pages,
    Map<String, String> headers,
    Map<String, dynamic> params,
    String body,
    int statusCode = 200,
    String preview,
  }) async* {
    if (headers == null) headers = {};
    if (preview != null) {
      headers["Accept"] = preview;
    }
    headers.putIfAbsent("Accept", () => "application/vnd.github.v3+json");

    await for (final response in fetchStreamed(method, path,
        pages: pages,
        headers: headers,
        params: params,
        body: body,
        statusCode: statusCode)) {
      final json = jsonDecode(response.body) as List;

      for (final item in json) {
        yield item as T;
      }
    }
  }

  Stream<T> objects<S, T>(
      String method, String path, JSONConverter<S, T> converter,
      {int pages,
      Map<String, String> headers,
      Map<String, dynamic> params,
      String body,
      int statusCode = 200,
      String preview}) {
    return jsonObjects<S>(method, path,
            pages: pages,
            headers: headers,
            params: params,
            body: body,
            statusCode: statusCode,
            preview: preview)
        .map(converter);
  }
}

//TODO(kevmoo): use regex here.
Map<String, String> parseLinkHeader(String input) {
  final out = <String, String>{};
  final parts = input.split(", ");
  for (final part in parts) {
    if (part[0] != "<") {
      throw const FormatException("Invalid Link Header");
    }
    final kv = part.split("; ");
    String url = kv[0].substring(1);
    url = url.substring(0, url.length - 1);
    String key = kv[1];
    key = key.replaceAll('"', "").substring(4);
    out[key] = url;
  }
  return out;
}
