class DecryptionConfig {
  String sourceDirectory;
  String keyDirectory;
  String collegeCode;
  String destinationDirectory;

  DecryptionConfig({
    this.sourceDirectory = '',
    this.keyDirectory = '',
    this.collegeCode = '',
    this.destinationDirectory = '',
  });

  bool get isComplete =>
      sourceDirectory.isNotEmpty &&
      keyDirectory.isNotEmpty &&
      collegeCode.isNotEmpty &&
      destinationDirectory.isNotEmpty;
}
