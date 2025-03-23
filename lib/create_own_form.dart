import 'package:flutter/material.dart';
import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;




class CreateFormPage extends StatefulWidget {
  @override
  State<CreateFormPage> createState() => _CreateFormPageState();

}

class _CreateFormPageState extends State<CreateFormPage> {



  List<Map<String, dynamic>> customQuestions = [];

  int counter = 1;

  void _addQuestion(Map<String, dynamic> question) {
    
    question['id'] = counter;
    customQuestions.add(question);
    counter++;
    setState(() {});
  }


 void saveFormAsXmlWeb(String xmlString) {
  final blob = html.Blob([xmlString], 'application/xml');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'custom_form.xml')
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> _saveFormAsXml() async {
  final builder = xml.XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element('form', nest: () {
    for (var question in customQuestions) {
      builder.element('question', nest: () {
        builder.element('id', nest: question['id'].toString());
        builder.element('text', nest: question['text']);
        builder.element('type', nest: question['type']);
        if (question['options'] != null) {
          builder.element('options', nest: () {
            for (var option in question['options']) {
              builder.element(
                'option',
                attributes: {
                  'category1': 'SEX',
                  'weight1': option['SEX']!,
                  'category2': 'FYZ',
                  'weight2': option['FYZ']!,
                  'category3': 'PSY',
                  'weight3': option['PSY']!,
                  'category4': 'ZAN',
                  'weight4': option['ZAN']!,
                },
                nest: option['text'],
              );
            }
          });
        }
      });
    }
  });

  final xmlDocument = builder.buildDocument();
  final xmlString = xmlDocument.toXmlString(pretty: true);

  if (kIsWeb) {
    saveFormAsXmlWeb(xmlString);
  } else {
    try {
      PermissionStatus status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nemáš povolenie na zápis do úložiska')),
        );
        return;
      }

      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nevybral si priečinok na uloženie súboru')),
        );
        return;
      }

      final filePath = '$result/custom_form.xml';
      final file = File(filePath);
      await file.writeAsString(xmlString);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Formulár úspešne uložený: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba pri ukladaní: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text(
            'Vytvoriť formulár',
            style: TextStyle(
              color: Colors.white,
            ),
          )),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: customQuestions.length,
              itemBuilder: (context, index) {
                final question = customQuestions[index];
                return ListTile(
                  title: Text(question['text']),
                  subtitle: Text('Typ: ${question['type']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        customQuestions.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddQuestionPage(onSubmit: _addQuestion),
                ),
              );
            },
            child: const Text('Pridať otázku'),
          ),
          SizedBox(
            height: 15,
          ),
          if (customQuestions.isNotEmpty)
            ElevatedButton(
              onPressed: () async {
                await _saveFormAsXml();
              },
              child: const Text('Uložiť formulár'),
            ),
          SizedBox(
            height: 15,
          ),
        ],
      ),
    );
  }
}

class AddQuestionPage extends StatefulWidget {
  final void Function(Map<String, dynamic>) onSubmit;

  const AddQuestionPage({required this.onSubmit});

  @override
  _AddQuestionPageState createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  String _selectedType = 'text';
  List<Map<String, String>> _options = [];

  void _addOption(Map<String, String> option) {
    setState(() {
      _options.add(option);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pridať otázku',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'Otázka'),
                validator: (value) =>
                    value != null && value.isNotEmpty ? null : 'Zadajte otázku!',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: [
                  const DropdownMenuItem(value: 'text', child: Text('Text')),
                  const DropdownMenuItem(value: 'date', child: Text('Dátum')),
                  const DropdownMenuItem(value: 'radio', child: Text('Radio')),
                  const DropdownMenuItem(
                      value: 'select', child: Text('Select')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    _options.clear();
                  });
                },
                decoration: const InputDecoration(labelText: 'Typ otázky'),
              ),
              if (_selectedType == 'radio' || _selectedType == 'select')
                Column(
                  children: [
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _showAddOptionDialog(context);
                      },
                      child: const Text('Pridať možnosť'),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        final option = _options[index];
                        return ListTile(
                          title: Text(option['text'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _options.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSubmit({
                      'text': _questionController.text,
                      'type': _selectedType,
                      'options': _options,
                    });
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Uložiť otázku'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptionDialog(BuildContext context) {
    final optionController = TextEditingController();
    final categoryControllers =
        List.generate(4, (_) => TextEditingController());
    final categories = ['SEX', 'FYZ', 'PSY', 'ZAN'];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Pridať možnosť'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: optionController,
                decoration: InputDecoration(labelText: 'Text možnosti'),
              ),
              for (int i = 0; i < categories.length; i++)
                TextField(
                  controller: categoryControllers[i],
                  decoration: InputDecoration(
                    labelText: 'Váha pre ${categories[i]}',
                  ),
                  keyboardType: TextInputType.number,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zrušiť'),
            ),
            TextButton(
              onPressed: () {
                _addOption({
                  'text': optionController.text,
                  'SEX': categoryControllers[0].text.isEmpty
                      ? '0'
                      : categoryControllers[0].text,
                  'FYZ': categoryControllers[1].text.isEmpty
                      ? '0'
                      : categoryControllers[1].text,
                  'PSY': categoryControllers[2].text.isEmpty
                      ? '0'
                      : categoryControllers[2].text,
                  'ZAN': categoryControllers[3].text.isEmpty
                      ? '0'
                      : categoryControllers[3].text,
                });
                Navigator.pop(ctx);
              },
              child: const Text('Pridať'),
            ),
          ],
        );
      },
    );
  }
}