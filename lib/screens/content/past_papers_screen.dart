import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class PastPapersScreen extends StatefulWidget {
  const PastPapersScreen({super.key});

  @override
  State<PastPapersScreen> createState() => _PastPapersScreenState();
}

class _PastPapersScreenState extends State<PastPapersScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _papers = [];
  bool _isTeacher = false; // We can check this dynamically

  @override
  void initState() {
    super.initState();
    _checkRoleAndFetch();
  }

  Future<void> _checkRoleAndFetch() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final roleRes = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      if (roleRes != null && roleRes['role'] == 'teacher') {
        setState(() => _isTeacher = true);
      }
    }
    await _fetchPapers();
  }

  Future<void> _fetchPapers() async {
    try {
      // Fetch papers
      final res = await _supabase
          .from('past_papers')
          .select()
          .order('year', ascending: false);
      setState(() => _papers = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('Error fetching papers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadPaper() async {
    final titleCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    final semCtrl = TextEditingController();
    
    // Pick file
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null) return;
    final file = result.files.single;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Past Paper'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selected: ${file.name}'),
            const SizedBox(height: 10),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title (e.g. Final Exam)')),
            const SizedBox(height: 10),
            TextField(controller: yearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year')),
            const SizedBox(height: 10),
            TextField(controller: semCtrl, decoration: const InputDecoration(labelText: 'Semester')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _performUpload(file, titleCtrl.text, yearCtrl.text, semCtrl.text);
            }, 
            child: const Text('Upload')
          )
        ],
      ),
    );
  }

  Future<void> _performUpload(PlatformFile file, String title, String yearStr, String sem) async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Upload
      final ext = file.extension ?? 'pdf';
      final path = 'papers/${DateTime.now().millisecondsSinceEpoch}.$ext';
      
      if (file.bytes != null) {
         await _supabase.storage.from('past-papers').uploadBinary(path, file.bytes!);
      } else if (file.path != null) {
         await _supabase.storage.from('past-papers').upload(path, File(file.path!));
      }

      final url = _supabase.storage.from('past-papers').getPublicUrl(path);

      // 2. Insert DB
      await _supabase.from('past_papers').insert({
        'title': title.isEmpty ? file.name : title,
        'year': int.tryParse(yearStr) ?? DateTime.now().year,
        'semester': sem,
        'file_url': url,
        'uploaded_by': user.id,
      });

      await _fetchPapers();
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded!')));

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Past Papers')),
      floatingActionButton: _isTeacher 
          ? FloatingActionButton(
              onPressed: _uploadPaper,
              child: const Icon(Icons.upload_file),
            )
          : null,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _papers.length,
            itemBuilder: (ctx, i) {
              final p = _papers[i];
              return ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(p['title'] ?? 'Untitled'),
                subtitle: Text('${p['semester'] ?? ''} - ${p['year']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () async {
                    final urlStr = p['file_url'];
                    if (urlStr != null) {
                       final uri = Uri.parse(urlStr);
                       try {
                         await launchUrl(uri, mode: LaunchMode.externalApplication);
                       } catch (e) {
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: $e')));
                         }
                       }
                    }
                  },
                ),
              );
            },
          ),
    );
  }
}
