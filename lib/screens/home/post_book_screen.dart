import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';
import '../../models/book.dart';

class PostBookScreen extends StatefulWidget {
  final Book? editing;
  const PostBookScreen({super.key, this.editing});

  @override
  State<PostBookScreen> createState() => _PostBookScreenState();
}

class _PostBookScreenState extends State<PostBookScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _swapFor = TextEditingController();
  String _condition = 'New';
  bool _loading = false;
  XFile? _image;

  @override
  void initState() {
    super.initState();
    final b = widget.editing;
    if (b != null) {
      _title.text = b.title;
      _author.text = b.author;
      _swapFor.text = b.swapFor;
      _condition = b.condition;
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 400,
        imageQuality: 40,
      );
      if (image != null) {
        setState(() => _image = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<BookProvider>();
    final editing = widget.editing;
    return Scaffold(
      appBar: AppBar(title: Text(editing == null ? 'Post a Book' : 'Edit Book')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _title, validator: _req, decoration: const InputDecoration(labelText: 'Book Title')),
            const SizedBox(height: 12),
            TextFormField(controller: _author, validator: _req, decoration: const InputDecoration(labelText: 'Author')),
            const SizedBox(height: 12),
            TextFormField(controller: _swapFor, decoration: const InputDecoration(labelText: 'Swap For')),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _condition,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: const [
                DropdownMenuItem(value: 'New', child: Text('New')),
                DropdownMenuItem(value: 'Like New', child: Text('Like New')),
                DropdownMenuItem(value: 'Good', child: Text('Good')),
                DropdownMenuItem(value: 'Used', child: Text('Used')),
              ],
              onChanged: (v) => setState(() => _condition = v!),
            ),
            const SizedBox(height: 16),
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? FutureBuilder<Uint8List>(
                                future: _image!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    );
                                  }
                                  return const Center(child: CircularProgressIndicator());
                                },
                              )
                            : Image.file(
                                File(_image!.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                      )
                    : (widget.editing?.imageUrl.isNotEmpty == true)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildEditingImage(widget.editing!.imageUrl),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Tap to add cover image', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : () async {
                if (!_form.currentState!.validate()) return;
                setState(() => _loading = true);
                try {
                  if (editing == null) {
                    await prov.create(
                      title: _title.text.trim(),
                      author: _author.text.trim(),
                      condition: _condition,
                      swapFor: _swapFor.text.trim(),
                      image: _image,
                    );
                  } else {
                    await prov.update(
                      id: editing.id,
                      title: _title.text.trim(),
                      author: _author.text.trim(),
                      condition: _condition,
                      swapFor: _swapFor.text.trim(),
                      image: _image,
                      currentImageUrl: editing.imageUrl,
                    );
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Book ${editing == null ? 'posted' : 'updated'} successfully!')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
              child: _loading 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(_image != null ? 'Uploading image...' : 'Posting...'),
                      ],
                    )
                  : Text(editing == null ? 'Post' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      final base64String = imageUrl.split(',')[1];
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
}