library tsupdate;

import 'package:args/args.dart';
import 'package:crypto/crypto.dart' show Digest, md5;
import 'dart:io';
import 'dart:async';
import 'package:convert/convert.dart';
import 'dart:convert';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

part "UpdateItem.dart";
part "UpdateData.dart";

ArgResults setupParser(List<String> args) {
  ArgParser parser = new ArgParser();
  parser.addOption('path', abbr: 'p', help: 'Path to store downloads');
  parser.addOption('version', abbr: 'v', help: 'Version to download');
  parser.addOption('access',
      abbr: 'a',
      help: 'Access Level',
      allowed: ['Com', 'Test', 'Dev'],
      defaultsTo: 'Com');
  parser.addOption('arch',
      abbr: 'r',
      help: 'Architecture',
      allowed: ['x86', 'x64'],
      defaultsTo: 'x64');
  parser.addOption('cred',
      abbr: 'c', help: "Credentials file", defaultsTo: "credentials.yaml");
  ArgResults result = parser.parse(args);
  if (!result.wasParsed('path') || !result.wasParsed('version')) {
    print(parser.usage);
    return null;
  } else
    return result;
}

main(List<String> args) async {
  ArgResults argParseResult = setupParser(args);
  if (argParseResult != null) {
    YamlMap credData = loadYaml((new File(argParseResult['cred'])).readAsStringSync());
    new Directory(argParseResult['path']).createSync(recursive: true);

    UpdateData updateData = new UpdateData(credData);

    await updateData.initData(new UpdateItem(argParseResult['access'],
        argParseResult['version'], argParseResult['arch'], null, null, null, null));

    updateData.downloadPatches(argParseResult['path']);
  }
}
