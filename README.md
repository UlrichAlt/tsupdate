# TopSolid'Update Downloader

This is download script for TopSolid Updates from the update server. Written in [Dart](http://www.dartlang.org), it can run on any platform that Dart supports (Linux/Mac/Windows).

As opposed to Missler's provided TopSolid update tool, the location to store updates can be set freely, however it must be available and writable.

## TODOs:

* Detect incomplete downloads using the checksum and retry them next time
* Limit the number of patches to keep (last n patches)

Please note that proper credentials are needed to log into Missler's server. These credentials should be stored in a credentials.yaml file which *is not provided* by this package.
