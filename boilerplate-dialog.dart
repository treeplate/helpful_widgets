class BoilerplateDialog extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const BoilerplateDialog(
      {super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(title),
            const SizedBox(height: 15),
            ...children,
          ],
        ),
      ),
    );
  }
