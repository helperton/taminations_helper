import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taminations/call_index.dart';
import 'package:taminations/math/hands.dart';

void main() {
  test('Extract all calls to JSON', () {
    final seen = <String>{};
    final allCalls = <Map<String, dynamic>>[];

    for (final entry in callIndex) {
      for (final ac in entry.calls) {
        final key = '${entry.title}|${ac.from}|${entry.level}';
        if (seen.contains(key)) continue;
        seen.add(key);

        final dancers = ac.formation.dancers;
        final formationDancers = <Map<String, dynamic>>[];
        for (final d in dancers) {
          final loc = d.location;
          formationDancers.add({
            'gender': d.gender == 1
                ? 'boy'
                : d.gender == 2
                    ? 'girl'
                    : 'phantom',
            'x': _r(loc.x),
            'y': _r(loc.y),
            'angle': _r(d.angleFacing * 180 / 3.14159265358979),
          });
        }

        final pathsList = <List<Map<String, dynamic>>>[];
        for (final path in ac.paths) {
          final movements = <Map<String, dynamic>>[];
          for (final m in path.movelist) {
            movements.add({
              'beats': _r(m.beats),
              'hands': Hands.getName(m.hands),
              'translate': {
                'cx1': _r(m.btranslate.cx1),
                'cy1': _r(m.btranslate.cy1),
                'cx2': _r(m.btranslate.cx2),
                'cy2': _r(m.btranslate.cy2),
                'x2': _r(m.btranslate.x2),
                'y2': _r(m.btranslate.y2),
              },
              'rotate': {
                'cx1': _r(m.brotate.cx1),
                'cy1': _r(m.brotate.cy1),
                'cx2': _r(m.brotate.cx2),
                'cy2': _r(m.brotate.cy2),
                'x2': _r(m.brotate.x2),
                'y2': _r(m.brotate.y2),
              },
            });
          }
          pathsList.add(movements);
        }

        allCalls.add({
          'title': ac.title,
          'level': entry.level,
          'from': ac.from,
          'difficulty': ac.difficulty,
          'parts': ac.parts,
          'fractions': ac.fractions,
          'formation': {
            'name': ac.formation.name,
            'dancers': formationDancers,
          },
          'paths': pathsList,
        });
      }
    }

    final outputPath =
        '/Users/jmcclintock/Documents/CallingApps/SquareCraft/SquareCraft/Taminations/TaminationsCalls.json';
    final file = File(outputPath);
    final encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(allCalls));
    print('Wrote ${allCalls.length} call variations to $outputPath');
  });
}

double _r(double v) => (v * 10000).roundToDouble() / 10000;
