import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class Book {
  final String isbn;
  final String title;
  final String author;
  final String coverType;

  Book({
    required this.isbn,
    required this.title,
    required this.author,
    required this.coverType,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      isbn: json['isbn'],
      title: json['title'],
      author: json['author'],
      coverType: json['coverType'],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BookList(),
    );
  }
}

class BookList extends StatefulWidget {
  const BookList({Key? key}) : super(key: key);

  @override
  _BookListState createState() => _BookListState();
}

class _BookListState extends State<BookList> {
  List<Book> books = [];
  TextEditingController isbnController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController authorController = TextEditingController();
  TextEditingController coverTypeController = TextEditingController();

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
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/books'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'isbn': isbnController.text,
          'title': titleController.text,
          'author': authorController.text,
          'coverType': coverTypeController.text,
        }),
      );

      if (response.statusCode == 200) {
        print('Book added successfully');
        fetchBooks();
      } else {
        print('Failed to add book. Error: ${response.body}');
        // Handle errors, display an error message to the user if needed
      }
    } catch (e) {
      print('Exception during addBook: $e');
      // Handle exceptions, display an error message to the user if needed
    }
  }

  Future<void> editBook(Book book) async {
    isbnController.text = book.isbn;
    titleController.text = book.title;
    authorController.text = book.author;
    coverTypeController.text = book.coverType;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Book'),
          content: Column(
            children: [
              TextField(
                controller: isbnController,
                decoration: const InputDecoration(labelText: 'ISBN'),
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
              TextField(
                controller: coverTypeController,
                decoration: const InputDecoration(labelText: 'Cover Type'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await updateBook(
                  book,
                  isbnController.text,
                  titleController.text,
                  authorController.text,
                  coverTypeController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateBook(
    Book book,
    String newIsbn,
    String newTitle,
    String newAuthor,
    String newCoverType,
  ) async {
    final response = await http.put(
      Uri.parse('http://localhost:8000/books/${book.isbn}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'isbn': newIsbn,
        'title': newTitle,
        'author': newAuthor,
        'coverType': newCoverType,
      }),
    );

    if (response.statusCode == 200) {
      fetchBooks();
    } else {
      if (kDebugMode) {
        print('Failed to update book. Error: ${response.body}');
      }
    }
  }

  Future<void> removeBook(Book book) async {
    bool confirmRemove = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Remove'),
          content: const Text('Are you sure you want to remove this book?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context, true);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmRemove == true) {
      final response =
          await http.delete(Uri.parse('http://localhost:8000/books/${book.isbn}'));

      if (response.statusCode == 200) {
        // Do nothing here as the list is already refreshed in fetchBooks
      } else {
        if (kDebugMode) {
          print('Failed to remove book. Error: ${response.body}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Management App'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(books[index].title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Author: ${books[index].author}'),
                      Text('ISBN: ${books[index].isbn}'),
                      Text('Cover Type: ${books[index].coverType}'),
                    ],
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Options'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await editBook(books[index]);
                                },
                                child: const Text('Edit Book'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await removeBook(books[index]);
                                },
                                child: const Text('Remove Book'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Add a New Book'),
                        content: Column(
                          children: [
                            TextField(
                              controller: isbnController,
                              decoration: const InputDecoration(labelText: 'ISBN'),
                            ),
                            TextField(
                              controller: titleController,
                              decoration: const InputDecoration(labelText: 'Title'),
                            ),
                            TextField(
                              controller: authorController,
                              decoration: const InputDecoration(labelText: 'Author'),
                            ),
                            TextField(
                              controller: coverTypeController,
                              decoration: const InputDecoration(labelText: 'Cover Type'),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              addBook();
                              Navigator.pop(context);
                            },
                            child: const Text('Add Book'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
