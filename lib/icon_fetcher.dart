import 'dart:io';
import 'dart:math';
import 'package:figma/figma.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:http/http.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:concurrent_queue/concurrent_queue.dart';

import 'class_builder.dart';

class FigmaIconFetcher {
  FigmaIconFetcher({
    required this.figmaToken,
    required this.canvasKey,
    required this.fileKey,
    required this.xmlOuputPath,
    required this.outputPath,

  }) : _figmaClient = FigmaClient(figmaToken);

  final String figmaToken;
  final String canvasKey;
  final String fileKey;
  final Directory xmlOuputPath;
  final Directory outputPath;

  final FigmaClient _figmaClient;

  final ConcurrentQueue _fileInfoQueue = ConcurrentQueue(
    autoStart: true,
    concurrency: 5
  );

  final ConcurrentQueue _downloadQueue = ConcurrentQueue(
    autoStart: true,
    concurrency: 30
  );

  final ConcurrentQueue fileGeneretionQueue = ConcurrentQueue(
    autoStart: true,
    concurrency: 1
  );

  Future<void> fetch() async {
    final NodesResponse response = await _figmaClient.getFileNodes(fileKey, FigmaQuery(
      ids: [canvasKey],
    ));

    final Map<String, String> nameMap = <String, String>{};

    response.nodes![canvasKey]!.components!.forEach((key, value) {
      final String fileName = _cleanupFileName(value.name!);
      if (fileName != '' && !fileName.startsWith('.') && !_isNumeric(fileName[0])) {
        nameMap[key] = _cleanupFileName(value.name!);
      }
    });

    final List<String> componentIds = nameMap.keys.toList();

    print('Found ${componentIds.length} components, fetching file information');

    const int slotSize = 500;
    final int queueSize = (componentIds.length / slotSize).ceil();

    final Map<String, String> imageResults = <String, String>{};

    // fetch image paths
    final List<int> pages = Iterable<int>.generate(queueSize).toList();

    for(final int index in pages) {
      final int comidx = index * slotSize;
      final List<String> ids = componentIds.sublist(comidx, min(componentIds.length, comidx + 500));

      if (ids.isEmpty) {
        continue;
      }

      _fileInfoQueue.add(() async {
        try {
          final ImageResponse imageResponse = await _figmaClient.getImages(fileKey, FigmaQuery(
            // hack to get around the usage of ";" in the figma package
            ids: [ids.join(',')],
            format: 'svg',
            scale: 1,
            svgSimplifyStroke: true
          ));

          imageResults.addAll(imageResponse.images!);
        } on FigmaError catch (_) {} catch (_) { }
      });
    }

    await _fileInfoQueue.onIdle();

    print('got all file the information, fetching files');
    print('---');

    // download and write svg
    imageResults.entries.map((element) {
      return _downloadQueue.add(() async {
        final String? fileName = nameMap[element.key];

        final Response response = await get(Uri.parse(element.value));

        await File('${xmlOuputPath.absolute.path}/$fileName.svg').writeAsBytes(response.bodyBytes);
        print('$fileName.svg saved');

      });
    }).toList();

    await _downloadQueue.onIdle();
  }

  Future<void> build() async {

    final ConcurrentQueue dartFileQueue = ConcurrentQueue(
      autoStart: true,
      concurrency: 1
    );

    final dartFile = Glob('${xmlOuputPath.absolute.path}/*.svg');

    final List<FileSystemEntity> files = dartFile.listSync();

    for (final entity in files) {

      if (entity is File && entity.existsSync()) {
        final File file = entity;
        final String xml = file.readAsStringSync();
        final ReCase iconName = ReCase(path.basenameWithoutExtension(file.path));

        if (xml != '') {
          XmlDocument xmlDocument = XmlDocument.parse(xml);
          final String dartFile = buildPainterClass(iconName.pascalCase, xmlDocument);

          dartFileQueue.add(() async {
            final file = File('${outputPath.absolute.path}/${iconName.snakeCase}.dart');

            await file.writeAsString(dartFile);
            print('${path.basename(file.path)} saved');
          });
        } else {
          print('failed to generate from $iconName as it is empty');
        }
      }
    }

    await dartFileQueue.onIdle();
  }

  String _cleanupFileName (String fileName) {
    return path.basename(fileName)
      .replaceAll('_24px', '');
  }

  bool _isNumeric(String? s) {
    if(s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }
}
