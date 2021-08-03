import 'package:dart_style/dart_style.dart';
import 'package:xml/xml.dart';
import 'package:code_builder/code_builder.dart';

  String buildPainterClass(String iconName, XmlDocument xmlDocument) {

    final XmlElement svgElement =  xmlDocument.findElements('svg').first;

    final painterClass = Class((classBuilder) {
      classBuilder.name = '_${iconName}Painter';
      classBuilder.extend = refer('CustomPainter', 'package:flutter/material.dart');

      classBuilder.constructors.add(Constructor((constructorBuilder) {
        constructorBuilder.optionalParameters.add(
          Parameter((parameterBuilder) {
            parameterBuilder.type = refer('Color', 'package:flutter/material.dart');
            parameterBuilder.name = 'color';
            parameterBuilder.named = true;
            parameterBuilder.required = true;
          })
        );
        constructorBuilder.initializers.add(
            const Code('_paint = Paint()')
        );
        constructorBuilder.body = const Code('''
          _paint.color = color;
          _paint.style = PaintingStyle.fill;
        ''');
      }));

      classBuilder.fields.add(Field((fieldBuilder) {
        fieldBuilder.name = 'width';
        fieldBuilder.type = refer('double');
        fieldBuilder.modifier = FieldModifier.final$;
        fieldBuilder.assignment = const Code('24');
      }));

      classBuilder.fields.add(Field((fieldBuilder) {
        fieldBuilder.name = 'height';
        fieldBuilder.type = refer('double');
        fieldBuilder.modifier = FieldModifier.final$;
        fieldBuilder.assignment = const Code('24');
      }));

      classBuilder.fields.add(Field((fieldBuilder) {
        fieldBuilder.name = '_paint';
        fieldBuilder.modifier = FieldModifier.final$;
        fieldBuilder.type = refer('Paint', 'package:flutter/material.dart');
      }));

      classBuilder.methods.add(Method.returnsVoid((methodBuilder) {
        methodBuilder.name = 'setColor';
        methodBuilder.requiredParameters.addAll([
          Parameter((parameterBuilder) {
            parameterBuilder.name = 'color';
            parameterBuilder.type = refer('Color', 'package:flutter/material.dart');
          }),
        ]);
        methodBuilder.body = const Code(
          '_paint.color = color;'
        );
      }));

      classBuilder.methods.add(Method.returnsVoid((methodBuilder) {
        methodBuilder.name = 'paint';
        methodBuilder.requiredParameters.addAll([
          Parameter((parameterBuilder) {
            parameterBuilder.name = 'canvas';
            parameterBuilder.type = refer('Canvas', 'package:flutter/material.dart');
          }),
          Parameter((parameterBuilder) {
            parameterBuilder.name = 'size';
            parameterBuilder.type = refer('Size', 'package:flutter/material.dart');
          }),
        ]);
        methodBuilder.annotations.add(refer('override'));


        final List<Code> codeList = <Code>[];
        _traverseSvgXmlTree(codeList, element: svgElement);

        methodBuilder.body = Block.of([
          const Code('''
            final Matrix4 matrix4 = Matrix4.identity();
            matrix4.scale(size.width / width, size.height / height);
          '''),
          ...codeList
        ]);
      }));

      classBuilder.methods.add(Method((methodBuilder) {
        methodBuilder.name = 'shouldRepaint';
        methodBuilder.annotations.add(refer('override'));
        methodBuilder.requiredParameters.add(Parameter((parameterBuilder) {
          parameterBuilder.type = refer(classBuilder.name!);
          parameterBuilder.name = 'oldDelegate';
        }));
        methodBuilder.body = const Code('return oldDelegate._paint != _paint;');
        methodBuilder.returns = refer('bool');
      }));

    });


    final iconClass = Class((classBuilder) {
      classBuilder.name = '${iconName}Icon';
      classBuilder.extend = refer('StatelessWidget', 'package:flutter/material.dart');
      classBuilder.implements.add(
        refer('PaintedIcon', 'package:figma_icon_builder/painted_icon.dart'),
      );
      classBuilder.constructors.add(Constructor((constructorBuilder) {
        final Parameter keyParam = Parameter((parameterBuilder) {
          parameterBuilder.type = refer('Key?', 'package:flutter/material.dart');
          parameterBuilder.name = 'key';
          parameterBuilder.named = true;
        });

        final Parameter foregroundColorParam = Parameter((parameterBuilder) {
          parameterBuilder.name = 'foregroundColor';
          parameterBuilder.named = true;
          parameterBuilder.toThis = true;
        });

        final sizeParam = Parameter((parameterBuilder) {
          parameterBuilder.name = 'size';
          parameterBuilder.defaultTo = const Code('const Size(24, 24)');
          parameterBuilder.named = true;
          parameterBuilder.toThis = true;
        });

        constructorBuilder.optionalParameters.addAll([
          keyParam,
          foregroundColorParam,
          sizeParam
        ]);
        constructorBuilder.constant = true;
        constructorBuilder.initializers.add(
            Code('super(key: ${keyParam.name})')
        );

      }));

      classBuilder.fields.add(Field((fieldBuilder) {
        fieldBuilder.type = refer('Color?', 'package:flutter/material.dart');
        fieldBuilder.name = 'foregroundColor';
        fieldBuilder.modifier = FieldModifier.final$;
      }));

      classBuilder.fields.add(Field((fieldBuilder) {
        fieldBuilder.type = refer('Size', 'package:flutter/material.dart');
        fieldBuilder.name = 'size';
        fieldBuilder.modifier = FieldModifier.final$;
      }));

      classBuilder.methods.add(Method((methodBuilder) {
        methodBuilder.name = 'build';
        methodBuilder.annotations.add(refer('override'));
        methodBuilder.returns = refer('Widget', 'package:flutter/material.dart');
        methodBuilder.requiredParameters.addAll([
          Parameter((parameterBuilder) {
            parameterBuilder.name = 'context';
            parameterBuilder.type = refer('BuildContext');
          }),
        ]);
        methodBuilder.body = Block.of([
          Code('''
            final IconThemeData iconThemeData = IconTheme.of(context);
            return ConstrainedBox(
              constraints: BoxConstraints.tight(size),
              child: CustomPaint(
                key: key,
                painter: ${painterClass.name}(
                  color: foregroundColor ?? iconThemeData.color ?? Colors.black,
                ),
                size: size,
              ),
            );
          '''),
        ]);

      }));

      classBuilder.methods.add(Method((methodBuilder) {
        methodBuilder.name = 'withColor';
        methodBuilder.annotations.add(refer('override'));
        methodBuilder.returns = refer('PaintedIcon');
        methodBuilder.requiredParameters.addAll([
          Parameter((parameterBuilder) {
            parameterBuilder.name = 'foregroundColor';
            parameterBuilder.type = refer('Color', 'package:flutter/material.dart');
          }),
        ]);

        methodBuilder.body = Block.of([
          Code('''
            return ${classBuilder.name}(
              key: key,
              foregroundColor: foregroundColor,
              size: size,
            );
          '''),
        ]);
      }));

      classBuilder.methods.add(Method((methodBuilder) {
        methodBuilder.name = 'withSize';
        methodBuilder.annotations.add(refer('override'));
        methodBuilder.returns = refer('PaintedIcon');
        methodBuilder.requiredParameters.addAll([
          Parameter((parameterBuilder) {
            parameterBuilder.name = 'size';
            parameterBuilder.type = refer('Size', 'package:flutter/material.dart');
          }),
        ]);

        methodBuilder.body = Block.of([
          Code('''
            return ${classBuilder.name}(
              key: key,
              foregroundColor: foregroundColor,
              size: size,
            );
          '''),
        ]);
      }));


    });

    final library = Library((libraryBuilder) {
      libraryBuilder.directives.addAll([
        Directive.import('package:flutter/material.dart'),
        Directive.import('package:path_drawing/path_drawing.dart'),
        Directive.import('package:figma_icon/figma_icon.dart'),
        Directive.import('package:flutter/rendering.dart'),
      ]);
      libraryBuilder.body.addAll([
        painterClass,
        iconClass
      ]);
    });


    final emitter = DartEmitter(
      allocator: Allocator.none,
      orderDirectives: false,
      useNullSafetySyntax: true
    );
    return DartFormatter().format('${library.accept(emitter)}');
  }

  void _traverseSvgXmlTree(List<Code> codeList, { required XmlElement element, int j = 1 }) {

    for(int i = 0; i < element.children.length; i += 1) {
      final XmlNode node = element.children[i];

      if (node is XmlElement) {
        final XmlElement currentElement = node;
        if (currentElement.name.local == 'path') {
          final pathKey = 'path\$$j\$$i';

          codeList.add(Code('''
            final Path $pathKey = parseSvgPathData('${currentElement.getAttribute('d')}');'''));

          final fillRule = currentElement.getAttribute('fill-rule');

          if (fillRule == 'evenodd') {
            codeList.add(Code('''
              $pathKey.fillType = PathFillType.evenOdd;'''));
          } else if (fillRule == 'nonzero') {
            codeList.add(Code('''
              $pathKey.fillType = PathFillType.nonZero;'''));
          }

          codeList.add(Code('''
            canvas.drawPath($pathKey.transform(matrix4.storage), _paint);
          '''));

        } else if (currentElement.name.local == 'rect') {
          throw UnimplementedError();
        } else if (currentElement.name.local == 'circle') {
          throw UnimplementedError();
        } else if (currentElement.name.local == 'g' && currentElement.children.isNotEmpty) {
          // down the rabit hole
          _traverseSvgXmlTree(codeList, element: currentElement, j: j+1);
        }
      }
    }
  }