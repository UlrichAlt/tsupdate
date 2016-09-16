part of tsupdate;

class UpdateItem {
  String accessLevel;
  String fileName;
  int size;
  String version;
  Digest md5Hash;
  String platform;
  String product;

  UpdateItem(this.accessLevel, this.version, this.platform, this.product,
      this.fileName, this.size, String digestString) {
    if (digestString != null)
      md5Hash = new Digest(hex.decode(digestString));
    else
      md5Hash = null;
  }

  bool matchesCriteria(UpdateItem criteria) =>
      platform == criteria.platform &&
      accessLevel == criteria.accessLevel &&
      version == criteria.version;

  bool operator ==(UpdateItem criteria) =>
      accessLevel == criteria.accessLevel &&
      fileName == criteria.fileName &&
      size == criteria.size &&
      version == criteria.version &&
      platform == criteria.platform &&
      product == criteria.product &&
      ((md5Hash != null) && (criteria.md5Hash != null)
          ? md5Hash == criteria.md5Hash
          : true);

  String getCompletePath(String storePath) =>
      path.join(storePath, version, platform, product, fileName);

  Future<bool> isValid(String storePath) async {
    File f = new File(getCompletePath(storePath));
    if (!await f.exists()) return false;
    FileStat stat = await f.stat();
    if (stat.size != size) return false;
    return await computeMd5(f) == md5Hash;
  }

  Future<Digest> computeMd5(File fileName) =>
      md5.bind(fileName.openRead()).first;

  void writeMasterFileEntry(IOSink sink) =>
      sink.write("$accessLevel $version/$platform/$product/$fileName $size bytes MD5:${hex.encode(md5Hash.bytes)}\r\n");

  Future downloadPatchIfInvalid(
      HttpClient client, String baseUrl, String storePath, IOSink sink) async {
    String completePath = getCompletePath(storePath);
    if (!await isValid(storePath)) {
      HttpClientRequest req = await client
          .getUrl(Uri.parse("$baseUrl/$version/$platform/$product/$fileName"));
      HttpClientResponse res = await req.close();
      new File(completePath).create(recursive: true).then((File f) {
        print("Downloading $completePath");
        writeMasterFileEntry(sink);
        res.pipe(f.openWrite()).whenComplete(() {
          computeMd5(f).then((Digest dig) {
            if (md5Hash != null) {
              if (md5Hash != dig)
                print("Error in MD5 checksum for $completePath");
            } else
              md5Hash = dig;
          });
        });
      });
    }
  }
}

class UpdateItemFromWeb extends Converter<String, UpdateItem> {
  const UpdateItemFromWeb();

  static final RegExp parseLine = new RegExp(
      r"((Com|Dev|Test)[\s-]+)?([0-9\.]+)\/(x86|x64)\/([\w'\s]+)\/([^\/]+)\s(\d+)\sbytes(\sMD5:([0-9A-Fa-f]+))?$");

  UpdateItem convert(String str) {
    Match match = parseLine.firstMatch(str);
    if (match != null)
      return new UpdateItem(
          match.group(2),
          match.group(3),
          match.group(4),
          match.group(5),
          match.group(6),
          int.parse(match.group(7)),
          match.group(9));
    else
      return null;
  }

  UpdateItemSink startChunkedConversion(dynamic sink) {
    return new UpdateItemSink(sink);
  }
}

class UpdateItemSink extends ChunkedConversionSink<String> {
  final dynamic _outSink;
  UpdateItemSink(this._outSink);

  void add(String data) {
    UpdateItem item = const UpdateItemFromWeb().convert(data);
    if (item != null) _outSink.add(item);
  }

  void close() {
    _outSink.close();
  }
}
