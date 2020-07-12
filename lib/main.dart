import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _todoTextFieldController = TextEditingController();
  List _todoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedIndex;

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    String data  = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Widget _buildListItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white,),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_todoList[index]['title']),
        value: _todoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(_todoList[index]['ok']?Icons.check:Icons.error),
        ),
        onChanged: (checked) {
          setState(() {
            _todoList[index]['ok'] = checked;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemovedIndex = index;
          _lastRemoved = Map.from(_todoList[index]);
          _todoList.removeAt(index);
          _saveData();

          final snackBar = SnackBar(
            content: Text('Tarefa "${_lastRemoved['title']}" removida.'),
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _todoList.insert(_lastRemovedIndex, _lastRemoved);
                  _saveData();
                });
              },
            ),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snackBar);
        });
      },
    );
  }

  void _addTodo() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo['title'] = _todoTextFieldController.text;
      newTodo['ok'] = false;
      _todoList.add(newTodo);
      _saveData();
      _todoTextFieldController.text = '';
    });
  }

  Future<Null> _refreshTodo() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _todoList.sort((a, b){
        if(a['ok'] && b['ok']) return 0;
        else if(a['ok'] && !b['ok']) return 1;
        else return -1;
      });
      _saveData();
    });
  }

  @override
  void initState() {
    super.initState();
    _readData().then((value) {
      setState(() {
        _todoList = json.decode(value);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Nova tarefa',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                    controller: _todoTextFieldController,
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text('Add'),
                  textColor: Colors.white,
                  onPressed: _addTodo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshTodo,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _todoList.length,
                  itemBuilder: _buildListItem
              ),
            )
          )
        ],
      ),
    );
  }
}

