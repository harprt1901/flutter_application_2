// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class Book {
  final String isbn;
  final String title;
  final String author;

  Book({required this.isbn, required this.title, required this.author});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      isbn: json['isbn'],
      title: json['title'],
      author: json['author'],
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Management App',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Book> books = [];
  TextEditingController isbnController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController authorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    final response = await http.get(Uri.parse('http://localhost:8000/books'));

    if (response.statusCode == 200) {
      setState(() {
        books = (json.decode(response.body) as List)
            .map((data) => Book.fromJson(data))
            .toList();
      });
    } else {
      throw Exception('Failed to load books');
    }
  }

  Future<void> addBook() async {
    final response = await http.post(
      Uri.parse('http://localhost:8000/books'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'isbn': isbnController.text,
        'title': titleController.text,
        'author': authorController.text,
      }),
    );

    if (response.statusCode == 200) {
      print('Book added successfully');
      isbnController.clear();
      titleController.clear();
      authorController.clear();
      await fetchBooks();
    } else {
      throw Exception('Failed to add book');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Management App'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(books[index].title),
                  subtitle: Text(books[index].author),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: isbnController,
                  decoration: InputDecoration(labelText: 'ISBN'),
                ),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: authorController,
                  decoration: InputDecoration(labelText: 'Author'),
                ),
                ElevatedButton(
                  onPressed: addBook,
                  child: Text('Add Book'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}