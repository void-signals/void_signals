class PerfRowStrings {
  const PerfRowStrings({
    required this.framework,
    required this.test,
    required this.time,
  });

  final String framework;
  final String test;
  final String time;
}

void logPerfResult(PerfRowStrings row) {
  print('| ${row.framework} | ${row.test} | ${row.time} |');
}

void printPerfReportHeaders() {
  print('| Framework | Test Case | Time (μs) |');
  print('| --- | --- | --- |');
}
