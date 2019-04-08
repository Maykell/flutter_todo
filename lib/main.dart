import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lista_tarefas/Task.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
    theme: ThemeData(
      hintColor: Colors.brown,
      primarySwatch: Colors.brown,
    ),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Task> _tasklist = [];

  final _taskTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _readFile().then((data) {
      List items = json.decode(data);
      setState(() {
        _tasklist = items.map((item) => Task.fromJson(item)).toList();
      });
    });
  }

  /* ACTIONS */

  void _showAlertDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Tarefa",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            content: Text("Ops, que tal digitar uma tarefa?"),
            actions: <Widget>[
              FlatButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  void _showSnackBar(context, Task task, index) {
    final snackBar = SnackBar(
      content: Text('Tarefa ${task.title} removida!'),
      action: SnackBarAction(
        label: 'Desfazer',
        onPressed: () {
          setState(() {
            _tasklist.insert(index, task);
          });

          _writeFile();
        },
      ),
      duration: Duration(seconds: 3),
    );
    Scaffold.of(context).showSnackBar(snackBar);
  }

  void _addTodo() {
    String newTodo = _taskTextController.text;

    if (newTodo.isEmpty) {
      _showAlertDialog();
      return;
    }

    _taskTextController.clear();

    setState(() {
      _tasklist.add(Task(title: newTodo, checked: false));
    });

    _writeFile();
  }

  void _removeTodo(context, Task task, index) {
    setState(() {
      _tasklist.removeAt(index);
    });

    _writeFile();

    _showSnackBar(context, task, index);
  }

  /* FILES */

  Future<String> _getLocalPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> _getLocalFile() async {
    final path = await _getLocalPath();
    return File("$path/data.json");
  }

  Future<File> _writeFile() async {
    final file = await _getLocalFile();
    return file.writeAsString(json.encode(_tasklist));
  }

  Future<String> _readFile() async {
    try {
      final file = await _getLocalFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Future<void> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _tasklist.sort((a, b) {
        if (a.checked && !b.checked) return 1;
        if (!a.checked && b.checked)
          return -1;
        else
          return 0;
      });
    });
  }

  /* WIDGETS */

  Widget _taskList() {
    return _tasklist.length > 0
        ? ListView.builder(
            itemCount: _tasklist.length,
            itemBuilder: (context, index) {
              return _taskListItem(context, _tasklist[index], index);
            },
          )
        : _emptyList();
  }

  Widget _taskListItem(context, Task task, int index) {
    return Dismissible(
      key: Key("${task.title}$index"),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        _removeTodo(context, task, index);
      },
      background: Container(
        color: Colors.red[400],
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      child: CheckboxListTile(
        title: Text(task.title),
        value: task.checked,
        secondary: CircleAvatar(
          child: task.checked
              ? Icon(Icons.check)
              : Text(
                  task.title[0].toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
        onChanged: (bool value) {
          setState(() {
            task.checked = value;
          });
          _writeFile();
        },
      ),
    );
  }

  Widget _emptyList() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(
            Icons.add_box,
            size: 100.0,
            color: Colors.brown,
          ),
        ),
        Text(
          "Você não possui nenhuma tarefa no momento!",
          style: TextStyle(fontSize: 16.0, color: Colors.brown[200]),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        backgroundColor: Colors.brown,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addTodo,
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(10.0),
            child: TextField(
              controller: _taskTextController,
              decoration: InputDecoration(
                labelText: "Tarefa",
                labelStyle: TextStyle(
                  color: Colors.brown,
                ),
                border: OutlineInputBorder(),
                hintText: "Digite uma tarefa legal",
              ),
              cursorColor: Colors.brown,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.brown,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              child: _taskList(),
              onRefresh: _refresh,
            ),
          ),
        ],
      ),
    );
  }
}
