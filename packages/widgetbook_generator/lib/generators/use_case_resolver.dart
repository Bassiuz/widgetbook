import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../extensions/element_extensions.dart';
import '../extensions/json_list_formatter.dart';
import '../models/widgetbook_use_case_data.dart';

class UseCaseResolver extends GeneratorForAnnotation<UseCase> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element.isPrivate) {
      throw InvalidGenerationSourceError(
        'Widgetbook annotations cannot be applied to private methods',
        element: element,
      );
    }

    final useCaseName = annotation.read('name').stringValue;
    final typeElement = annotation.read('type').typeValue.element!;
    final designLinkReader = annotation.read('designLink');
    String? designLink;
    if (!designLinkReader.isNull) {
      designLink = designLinkReader.stringValue;
    }

    final typeValue = annotation.read('type').typeValue;
    final componentName = typeValue
        .getDisplayString(
          withNullability: false,
        )
        // Generic widgets shouldn't have a "<dynamic>" suffix
        // if no type parameter is specified.
        .replaceAll(
          '<dynamic>',
          '',
        );

    final componentDefinitionPath = typeValue.element!.librarySource!.fullName;

    String importStatement = _convertAssetImport(importStatement: element.importStatement);

    final data = WidgetbookUseCaseData(
      name: element.name!,
      useCaseName: useCaseName,
      componentName: componentName,
      importStatement: importStatement,
      componentImportStatement: typeElement.importStatement,
      dependencies: typeElement.dependencies,
      componentDefinitionPath: componentDefinitionPath,
      useCaseDefinitionPath: element.librarySource!.fullName,
      designLink: designLink,
    );

    return [data].toJson();
  }

  String _convertAssetImport({required String importStatement, String widgetbookLocationName = "/test/"}) {
    if (!importStatement.startsWith("asset:")) return importStatement;

    String strippedImportStatement = importStatement.substring(6);

    int dotCount = RegExp("/").allMatches(widgetbookLocationName).length;

    String result = strippedImportStatement;

    // add "../" for each time we have dotcount to result

    for (int i = 0; i < dotCount; i++) {
      result = "../" + result;
    }

    return result;
  }
}
