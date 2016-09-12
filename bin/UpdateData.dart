part of tsupdate;

class UpdateData {
  bool isReady;

  static final dynamic trans =
      UTF8.decoder.fuse(const LineSplitter()).fuse(const UpdateItemGenerator());

  List<UpdateItem> itemList;
  HttpClient client;
  YamlMap credData;

  UpdateData(YamlMap this.credData) {
    isReady = false;
    client = new HttpClient();
    client.addCredentials(Uri.parse(credData['website']), credData["realm"],
        new HttpClientBasicCredentials(credData["user"], credData["password"]));
    client.maxConnectionsPerHost = 5;
  }

  Future initData(UpdateItem criteria) async {
    HttpClientRequest req =
        await client.getUrl(Uri.parse(credData['master_file']));
    HttpClientResponse response = await req.close();
    itemList = await response
        .transform(trans)
        .where((item) => item.matchesCriteria(criteria))
        .toList();
    isReady = true;
  }

  void downloadPatches(String storePath) {
    itemList.forEach((UpdateItem ui) =>
        ui.downloadPatch(client, credData['website'], storePath));
  }
}
