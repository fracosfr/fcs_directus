import 'package:fcs_directus/src/models/item_model.dart';

class DirectusFileModelColums {
  final String storage = "storage";
  final String filenameDisk = "filename_disk";
  final String filenameDownload = "filename_download";
  final String title = "title";
  final String type = "type";
  final String folder = "folder";
  final String uploadedBy = "uploaded_by";
  final String modifiedOn = "modified_on";
  final String filesize = "filesize";
  final String width = "width";
  final String height = "height";
  final String focalPointX = "focal_point_x";
  final String focalPointY = "focal_point_y";
  final String duration = "duration";
  final String description = "description";
  final String location = "location";
  final String tags = "tags";
  final String metadata = "metadata";
}

class DirectusFile extends DirectusItemModel {
  DirectusFile.creator(super.data) : super.creator();
  DirectusFile(String title, {String? type, String? fileNameDownload}) {
    this.title = title;
    this.type = type;
    this.fileNameDownload = fileNameDownload;
    storage = "local";
  }

  @override
  int get cascadeLevel => 1;

  @override
  String? get itemName => "directus_files";

  static DirectusFileModelColums get cols => DirectusFileModelColums();

  String? get storage => getValue(cols.storage);
  set storage(String? value) => setValue(cols.storage, value);

  String? get fileNameDisk => getValue(cols.filenameDisk);

  String? get fileNameDownload => getValue(cols.filenameDownload);
  set fileNameDownload(String? value) => setValue(cols.filenameDownload, value);

  String? get title => getValue(cols.title);
  set title(String? value) => setValue(cols.title, value);

  String? get type => getValue(cols.type);
  set type(String? value) => setValue(cols.type, value);

  String? get folder => getValue(cols.folder);
  String? get uploadedBy => getValue(cols.uploadedBy);
  DateTime? get modifiedOn => getValue(cols.modifiedOn);
  int? get filesize => getValue(cols.filesize);
  int? get width => getValue(cols.width);
  int? get height => getValue(cols.height);
  int? get focalPointX => getValue(cols.focalPointX);
  int? get focalPointY => getValue(cols.focalPointY);
  int? get duration => getValue(cols.duration);
  String? get description => getValue(cols.description);
  String? get location => getValue(cols.location);
  List<String> get tags => getValue(cols.tags);
  set tags(List<String> value) => setValue(cols.tags, value);
  Map<dynamic, dynamic> get metadata => getValue(cols.metadata);
}
	//"metadata": {
	//	"icc": {
	//		"version": "2.1",
	//		"intent": "Perceptual",
	//		"cmm": "lcms",
	//		"deviceClass": "Monitor",
	//		"colorSpace": "RGB",
	//		"connectionSpace": "XYZ",
	//		"platform": "Apple",
	//		"creator": "lcms",
	//		"description": "c2",
	//		"copyright": ""
	//	}
	//}