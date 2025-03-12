class DummyCallModel {
  String name;
  String phoneNumber;
  int callType;
  DateTime dateTime;
  bool isSelected;

  DummyCallModel({
    required this.name,
    required this.phoneNumber,
    required this.dateTime,
    required this.callType,
    this.isSelected = false,
  });
}

List<DummyCallModel> recentCalls = [
  DummyCallModel(
    name: 'John Doe',
    phoneNumber: '+15551234567',
    dateTime: DateTime.now().subtract(Duration(minutes: 5)),
    callType: 0, //outgoing
  ),
  DummyCallModel(
    name: 'Jane Smith',
    phoneNumber: '+15559876543',
    dateTime: DateTime.now().subtract(Duration(hours: 2)),
    callType: 1, //incoming
  ),
  DummyCallModel(
    name: 'Emergency Services',
    phoneNumber: '911',
    dateTime: DateTime.now().subtract(Duration(days: 1)),
    callType: 2, //missed
  ),
  DummyCallModel(
    name: 'Bob Johnson',
    phoneNumber: '+15552468013',
    dateTime: DateTime.now().subtract(Duration(days: 2, hours: 10)),
    callType: 0,
  ),
  DummyCallModel(
    name: 'Alice Brown',
    phoneNumber: '+15551357911',
    dateTime: DateTime.now().subtract(Duration(days: 3)),
    callType: 0,
  ),
  DummyCallModel(
    name: 'Charlie Wilson',
    phoneNumber: '+15553691214',
    dateTime: DateTime.now().subtract(Duration(days: 4, hours: 5)),
    callType: 2,
  ),
  DummyCallModel(
    name: 'David Garcia',
    phoneNumber: '+15554789016',
    dateTime: DateTime.now().subtract(Duration(days: 5)),
    callType: 0,
  ),
  DummyCallModel(
    name: 'Emily Rodriguez',
    phoneNumber: '+15555802468',
    dateTime: DateTime.now().subtract(Duration(days: 6, hours: 12)),
    callType: 1,
  ),
  DummyCallModel(
    name: 'Unknown Number',
    phoneNumber: '+15556913579',
    dateTime: DateTime.now().subtract(Duration(days: 7)),
    callType: 2,
  ),
  DummyCallModel(
    name: 'Unknown Number',
    phoneNumber: '+15556913579',
    dateTime: DateTime.now().subtract(Duration(days: 10)),
    callType: 2,
  ),
];
