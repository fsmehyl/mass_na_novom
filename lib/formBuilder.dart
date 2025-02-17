import 'package:flutter/material.dart';
import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'package:intl/date_symbol_data_local.dart';
import 'graph.dart';
import 'package:flutter/services.dart' show rootBundle;

class FormBuilder extends StatefulWidget {
  final String xmlFilePath;
  final String formTitle;

  const FormBuilder({super.key, required this.xmlFilePath, required this.formTitle});

  @override
  _FormBuilderState createState() => _FormBuilderState();
}

class _FormBuilderState extends State<FormBuilder> {
  List<Map<String, dynamic>> questions = [];
  Map<String, dynamic> answers = {};
  String _formTitle = 'Načítava sa...';
  final _formKey = GlobalKey<FormState>(); // Pridané pre správu stavu formulára

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    initializeDateFormatting('sk', null).then((_) {});
  }

  Future<void> _loadQuestions() async {
    try {
    String data;

    // Načítanie súboru z assets alebo externého úložiska
    if (widget.xmlFilePath.startsWith('assets/')) {
      // Načítanie súboru z assets
      data = await rootBundle.loadString(widget.xmlFilePath);
    } else {
      // Načítanie externého súboru
      final file = File(widget.xmlFilePath);

      // Skontrolujte, či súbor existuje
      if (!await file.exists()) {
        print('Súbor neexistuje na ceste: ${widget.xmlFilePath}');
        return;
      }

      data = await file.readAsString();
    }

    final document = xml.XmlDocument.parse(data);
    final form = document.findAllElements('form').first;

    final titleNode = form.findElements('title').isNotEmpty
      ? form.findElements('title').first.text
      : "Bez názvu";

    List<Map<String, dynamic>> loadedQuestions = [];

    form.findAllElements('question').forEach((questionNode) {
      final id = questionNode.findElements('id').first.text;
      final text = questionNode.findElements('text').first.text;
      final type = questionNode.findElements('type').first.text;
      List<Map<String, dynamic>> options = [];

      if (type == 'radio' || type == 'select') {
        options = questionNode
            .findElements('options')
            .first
            .findElements('option')
            .map((optionNode) {
          // Extract categories and weights
          Map<String, double> categoryWeights = {};
          for (int i = 1; i <= 4; i++) {
            final category = optionNode.getAttribute('category$i');
            final weight =
                double.tryParse(optionNode.getAttribute('weight$i') ?? '0.0') ??
                    0.0;
            if (category != null && category.isNotEmpty) {
              categoryWeights[category] = weight;
            }
          }
          return {
            'text': optionNode.text.trim(),
            'categoryWeights': categoryWeights,
          };
        }).toList();
      }

      loadedQuestions.add({
        'id': id,
        'text': text,
        'type': type,
        'options': options,
      });
    });

    setState(() {
      _formTitle = titleNode;
      questions = loadedQuestions;
    });
  } catch (e) {
    print('Chyba pri načítaní otázok: $e');
  }
  }

  void _collectAnswers() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Uloží hodnoty do mapy answers
      print(answers); // Výpis odpovedí do konzoly
    }
  }

void _calculateCategoryScores() {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save(); // Uloží hodnoty do mapy answers

    // Initialize category scores
    Map<String, double> categoryScores = {};

    for (var question in questions) {
      final questionId = question['id'];
      final selectedAnswer = answers[questionId];

      if (selectedAnswer != null) {
        if (question['type'] == 'radio' || question['type'] == 'select') {
          // Pre rádio a select otázky
          final option = question['options'].firstWhere(
            (opt) => opt['text'] == selectedAnswer,
            orElse: () => <String, Object>{}, // Explicitne definovaný typ
          );

          if (option.isNotEmpty) {
            final categoryWeights = option['categoryWeights'] as Map<String, double>;
            categoryWeights.forEach((category, weight) {
              categoryScores[category] = (categoryScores[category] ?? 0.0) + weight;
            });
          }
        } else if (question['type'] == 'checkbox') {
          // Pre checkbox otázky
          final selectedOptions = selectedAnswer as List<String>;
          for (var optionText in selectedOptions) {
            final option = question['options'].firstWhere(
              (opt) => opt['text'] == optionText,
              orElse: () => <String, Object>{}, // Explicitne definovaný typ
            );

            if (option.isNotEmpty) {
              final categoryWeights = option['categoryWeights'] as Map<String, double>;
              categoryWeights.forEach((category, weight) {
                categoryScores[category] = (categoryScores[category] ?? 0.0) + weight;
              });
            }
          }
        }
      }
    }

    // Passing answers to graph.dart and showing category scores
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HorizontalBarChartWithLevels(
          values: categoryScores.values.toList(),
          answers: answers, // Send answers to the graph page
        ),
      ),
    );
  } else {
    // Ak formulár nie je platný, zobrazte upozornenie
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prosím, vyplňte všetky povinné polia.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.formTitle,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
           )),
           backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Priradenie GlobalKey k formuláru
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: questions.map((question) {
                    switch (question['type']) {
                      case 'text':
                        return _buildTextField(question);
                      case 'textarea':
                        return _buildTextareaField(question);
                      case 'radio':
                        return _buildRadioField(question);
                      case 'checkbox':
                        return _buildCheckboxField(question);
                      case 'select':
                        return _buildSelectField(question);
                      default:
                        return const SizedBox.shrink();
                    }
                  }).toList(),
                ),
                Column(
                  children: [
                    SizedBox(
                      child: ElevatedButton(
                        onPressed: _calculateCategoryScores, // Uloženie dát
                        child: Column(
                          children: [
                            SizedBox(height: 5),
                            Text(
                              'Kliknite pre zber dát...',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////

  Widget _buildTextField(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question['text'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        TextFormField(
          maxLines: 1,
          onSaved: (value) {
            answers[question['id']] = value;
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Toto pole je povinné';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextareaField(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question['text'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        TextFormField(
          maxLines: 4,
          onSaved: (value) {
            answers[question['id']] = value;
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Toto pole je povinné';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////

  Widget _buildRadioField(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question['text'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Column(
          children: question['options'].map<Widget>((option) {
            return Row(
              children: [
                Radio(
                  value: option['text'],
                  groupValue: answers[question['id']],
                  onChanged: (value) {
                    setState(() {
                      answers[question['id']] = value;
                    });
                  },
                ),
                Text(option['text']),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////

  Widget _buildCheckboxField(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['text'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Column(
          children: question['options'].map<Widget>((option) {
            return Row(
              children: [
                Checkbox(
                  value: answers[question['id']]?.contains(option['text']) ?? false,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        answers[question['id']] =
                            (answers[question['id']] ?? [])..add(option['text']);
                      } else {
                        answers[question['id']]?.remove(option['text']);
                      }
                    });
                  },
                ),
                Text(option['text']),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////

  Widget _buildSelectField(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question['text'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(
          items: question['options']
              .map<DropdownMenuItem<String>>((Map<String, dynamic> option) {
            return DropdownMenuItem<String>(
              value: option['text'],
              child: Text(option['text']),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              answers[question['id']] = newValue;
            });
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vyberte možnosť';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}