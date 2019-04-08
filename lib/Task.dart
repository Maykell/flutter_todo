class Task {
  final String title;
  bool checked;

  Task({this.title, this.checked});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(title: json["title"], checked: json["checked"]);
  }

  Map<String, dynamic> toJson() => {"title": title, "checked": checked};
}
