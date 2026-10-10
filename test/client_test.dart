import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towerdeck/core/api/unraid_api.dart';
import 'package:towerdeck/core/api/unraid_client.dart';

/// Runs the client against a local HTTP server that mimics the Unraid API.
void main() {
  late HttpServer server;
  late Future<void> Function(HttpRequest) handler;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((r) => handler(r));
  });
  tearDown(() => server.close(force: true));

  UnraidClient client({String key = 'secret'}) =>
      UnraidClient(baseUrl: Uri.parse('http://127.0.0.1:${server.port}'), apiKey: key);

  Future<void> respond(HttpRequest r, Object body, {int status = 200}) async {
    r.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await r.response.close();
  }

  test('sends api key and returns data', () async {
    String? seenKey;
    Map<String, dynamic>? seenBody;
    handler = (r) async {
      seenKey = r.headers.value('x-api-key');
      seenBody = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      await respond(r, {
        'data': {
          'info': {
            'os': {'hostname': 'Tower'},
            'versions': {
              'core': {'unraid': '7.3.1'},
            },
          },
          'me': {
            'roles': ['ADMIN'],
          },
        },
      });
    };
    final probe = await UnraidApi(client()).probe();
    expect(seenKey, 'secret');
    expect(seenBody!['query'], contains('Probe'));
    expect(probe.hostname, 'Tower');
    expect(probe.roles, ['ADMIN']);
  });

  test('maps UNAUTHENTICATED to unauthorized', () async {
    handler = (r) => respond(r, {
          'errors': [
            {
              'message': 'Invalid CSRF token',
              'extensions': {'code': 'UNAUTHENTICATED'},
            },
          ],
          'data': null,
        });
    expect(
      () => client().execute('{ info { os { hostname } } }'),
      throwsA(isA<UnraidApiException>().having((e) => e.kind, 'kind', ApiErrorKind.unauthorized)),
    );
  });

  test('maps validation errors to unsupported', () async {
    handler = (r) => respond(r, status: 400, {
          'errors': [
            {
              'message': 'Cannot query field "restart" on type "DockerMutations".',
              'extensions': {'code': 'GRAPHQL_VALIDATION_FAILED'},
            },
          ],
        });
    expect(
      () => client().execute('mutation { docker { restart(id: "x") { id } } }'),
      throwsA(isA<UnraidApiException>().having((e) => e.kind, 'kind', ApiErrorKind.unsupported)),
    );
  });

  test('restart falls back to stop + start on old APIs', () async {
    final calls = <String>[];
    handler = (r) async {
      final q = (jsonDecode(await utf8.decodeStream(r)) as Map)['query'] as String;
      final op = RegExp(r'docker \{ (\w+)').firstMatch(q)!.group(1)!;
      calls.add(op);
      if (op == 'restart') {
        return respond(r, status: 400, {
          'errors': [
            {
              'message': 'Cannot query field "restart" on type "DockerMutations".',
              'extensions': {'code': 'GRAPHQL_VALIDATION_FAILED'},
            },
          ],
        });
      }
      await respond(r, {
        'data': {
          'docker': {
            op: {'id': 'x', 'state': 'RUNNING'},
          },
        },
      });
    };
    await UnraidApi(client()).containerAction('x', ContainerAction.restart);
    expect(calls, ['restart', 'stop', 'start']);
  });

  test('reports redirect target (http → https)', () async {
    handler = (r) async {
      r.response
        ..statusCode = 302
        ..headers.set('location', 'https://tower.local/graphql');
      await r.response.close();
    };
    expect(
      () => client().execute('{ online }'),
      throwsA(isA<UnraidApiException>()
          .having((e) => e.kind, 'kind', ApiErrorKind.redirect)
          .having((e) => e.redirectTo?.scheme, 'scheme', 'https')),
    );
  });

  test('keeps partial data when some fields fail', () async {
    handler = (r) => respond(r, {
          'errors': [
            {'message': 'VM service not running'},
          ],
          'data': {'vms': null, 'online': true},
        });
    final data = await client().execute('{ online vms { id } }');
    expect(data['online'], isTrue);
  });
}
