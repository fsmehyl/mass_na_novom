import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:xml/xml.dart' as xml;
import 'graph.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';


class FormBuilderPackage extends StatefulWidget {
  final String xmlFilePath;

  const FormBuilderPackage({
    super.key,
    required this.xmlFilePath,
  });

  @override
  State<FormBuilderPackage> createState() => _FormBuilderPackageState();
}

class _FormBuilderPackageState extends State<FormBuilderPackage> {
  final _formKey = GlobalKey<FormBuilderState>();
  List<Map<String, dynamic>> questions = [];
  Map<String, dynamic> answers = {};
  String _formTitle = 'Načítava sa...';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    initializeDateFormatting('sk', null).then((_) {
    // Dátumové dáta sú inicializované, môžete pokračovať
  });
  }

  Future<void> _loadQuestions() async {
    final file = File(widget.xmlFilePath);
    final data = await file.readAsString();
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
  }

  void _collectAnswers() {
    for (var question in questions) {
      final questionId = question['id'];
      final selectedAnswer = _formKey.currentState?.fields[questionId]?.value;

      if (selectedAnswer != null) {
        answers[questionId] = selectedAnswer;
      }
    }
  }

  List<Widget> _buildFormFields() {
    return questions.map((question) {
      switch (question['type']) {
        case 'text':
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: FormBuilderTextField(
              name: question['id'],
              decoration: InputDecoration(
                labelText: question['text'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
              ),
            ),
          );
        case 'number':
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: FormBuilderTextField(
              name: question['id'],
              decoration: InputDecoration(
                labelText: question['text'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
              ),
              keyboardType: TextInputType.number,
            ),
          );
        case 'date':
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: FormBuilderDateTimePicker(
              name: question['id'],
              inputType: InputType.date,
              decoration: InputDecoration(
                labelText: question['text'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
              ),
              format: DateFormat('dd. MMMM yyyy', 'sk'),
            ),
          );
        case 'time':
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: FormBuilderDateTimePicker(
              name: question['id'],
              inputType: InputType.time,
              decoration: InputDecoration(
                labelText: question['text'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
              ),
            ),
          );
        case 'select':
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: FormBuilderDropdown<String>(
              name: question['id'],
              decoration: InputDecoration(
                labelText: question['text'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
              ),
              items: question['options']
                  .map<DropdownMenuItem<String>>((option) =>
                      DropdownMenuItem<String>(
                          value: option['text'], child: Text(option['text'])))
                  .toList(),
            ),
          );
        case 'radio':
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: FormBuilderRadioGroup<String>(
              name: question['id'],
              decoration: InputDecoration(
                labelText: question['text'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              options: question['options']
                  .map<FormBuilderFieldOption<String>>(
                    (option) => FormBuilderFieldOption<String>(
                      value: option['text'],
                      child: Text(option['text']),
                    ),
                  )
                  .toList(),
            ),
          );
        case 'checkbox':
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: FormBuilderCheckboxGroup(
              name: question['id'], // Unikátny názov pre túto otázku
              decoration: InputDecoration(
                labelText: question['text'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              options: (question['options'] as List<Map<String, dynamic>>)
                  .map((option) => FormBuilderFieldOption<String>(
                        value: option['text'], // Hodnota pre možnosť
                        child: Text(option['text']), // Zobrazený text
                      ))
                  .toList(),
            ),
          );

        case 'switch':
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: FormBuilderSwitch(
              name: question['id'],
              title: Text(question['text']),
            ),
          );
        case 'slider':
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: FormBuilderSlider(
              name: question['id'],
              min: 0.0,
              max: 100.0,
              initialValue: 50.0,
              decoration: InputDecoration(
                labelText: question['text'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        case 'range_slider':
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: FormBuilderRangeSlider(
              name: question['id'],
              min: 0.0,
              max: 100.0,
              initialValue: const RangeValues(20.0, 80.0),
              decoration: InputDecoration(
                labelText: question['text'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        default:
          return const SizedBox.shrink();
      }
    }).toList();
  }

  void _calculateCategoryScores() {
    _collectAnswers(); // Gather answers before navigating

    // Initialize category scores
    Map<String, double> categoryScores = {};

    for (var question in questions) {
      final questionId = question['id'];
      final selectedAnswer = _formKey.currentState?.fields[questionId]?.value;

      if (selectedAnswer != null &&
          selectedAnswer is String &&
          selectedAnswer.isNotEmpty) {
        final option = question['options'].firstWhere(
          (opt) => opt['text'] == selectedAnswer,
          orElse: () => <String, Object>{},
        );

        if (option.isNotEmpty) {
          final categoryWeights =
              option['categoryWeights'] as Map<String, double>;

          categoryWeights.forEach((category, weight) {
            categoryScores[category] =
                (categoryScores[category] ?? 0.0) + weight;
          });
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
         _formTitle,
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ),
      body: questions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display collected answers above the form
                    if (answers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: answers.entries.map((entry) {
                            return Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            );
                          }).toList(),
                        ),
                      ),
                    FormBuilder(
                      key: _formKey,
                      child: Column(
                        children: [
                          ..._buildFormFields(),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.saveAndValidate() ??
                                  false) {
                                _calculateCategoryScores();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please complete the form.'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0, vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Pozri výsledky",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
