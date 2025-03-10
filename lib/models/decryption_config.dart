class DecryptionConfig {
  String sourceDirectory;
  String keyDirectory;
  String collegeCode;
  String destinationDirectory;
  String zipPassword;

  DecryptionConfig({
    this.sourceDirectory = '',
    this.keyDirectory = '',
    this.collegeCode = '',
    this.destinationDirectory = '',
    this.zipPassword = '',
  });

  bool get isComplete =>
      sourceDirectory.isNotEmpty &&
      collegeCode.isNotEmpty &&
      zipPassword.isNotEmpty;
}
