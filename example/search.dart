import 'dart:html';
import 'package:github/browser.dart';
import 'common.dart';

Future<void> main() async {
  await initViewSourceButton('search.dart');

  var searchBtn = querySelector('#submit');
  searchBtn.onClick.listen(search);
}

Future<void> search(_) async {
  CodeSearchResults results = await github.search.code(
    val('query'),
    language: val('language'),
    filename: val('filename'),
    user: val('user'),
    repo: val('repo'),
    org: val('org'),
    extension: val('ext'),
    fork: val('fork'),
    path: val('path'),
    size: val('size'),
    inFile: isChecked('infile'),
    inPath: isChecked('inpath'),
    perPage: int.tryParse(val('perpage')),
    pages: int.tryParse(val('pages')),
  );

  querySelector('#nresults').text =
      '${results.totalCount} result${results.totalCount == 1 ? "" : "s"} (showing ${results.items.length})';
  DivElement resultsDiv = querySelector('#results');
  resultsDiv.innerHtml = '';
  for (CodeSearchItem item in results.items) {
    var url = item.htmlUrl;
    var path = item.path;
    resultsDiv.append(DivElement()
      ..append(AnchorElement(href: url.toString())
        ..text = path
        ..target = '_blank'));
  }
}

String val(String id) => (querySelector("#$id") as InputElement).value;
bool isChecked(String id) =>
    (querySelector('#$id') as CheckboxInputElement).checked;
