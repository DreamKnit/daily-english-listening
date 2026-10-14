import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const DailyEnglishApp());
}

class DailyEnglishApp extends StatelessWidget {
  const DailyEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '每日英语听力',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class SubtitleLine {
  final Duration startTime;
  final Duration endTime;
  final String en;
  final String cn;

  SubtitleLine({
    required this.startTime,
    required this.endTime,
    required this.en,
    required this.cn,
  });
}

class Article {
  final String id;
  final String title;
  final String category;
  final String durationStr;
  final String audioUrl;
  final List<SubtitleLine> subtitles;

  Article({
    required this.id,
    required this.title,
    required this.category,
    required this.durationStr,
    required this.audioUrl,
    required this.subtitles,
  });
}

final List<Article> mockArticles = [
  Article(
    id: '1',
    title: 'The Power of Habit (习惯的力量)',
    category: 'VOA 慢速英语',
    durationStr: '00:25',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    subtitles: [
      SubtitleLine(
        startTime: const Duration(seconds: 0),
        endTime: const Duration(seconds: 5),
        en: 'Welcome to Daily English Listening practice.',
        cn: '欢迎来到每日英语听力练习。',
      ),
      SubtitleLine(
        startTime: const Duration(seconds: 5),
        endTime: const Duration(seconds: 11),
        en: 'Building a small habit every day leads to massive success.',
        cn: '每天培养一个小习惯，终将带来巨大的成功。',
      ),
      SubtitleLine(
        startTime: const Duration(seconds: 11),
        endTime: const Duration(seconds: 18),
        en: 'Persistence and patience are the keys to mastering a language.',
        cn: '坚持与耐心是掌握一门语言的关键。',
      ),
      SubtitleLine(
        startTime: const Duration(seconds: 18),
        endTime: const Duration(seconds: 25),
        en: 'Try clicking any word in this sentence to look it up.',
        cn: '试着点击这句话里的任意单词来查询释义。',
      ),
    ],
  ),
  Article(
    id: '2',
    title: 'Morning Coffee Conversation (早间咖啡对话)',
    category: '日常实用口语',
    durationStr: '00:20',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    subtitles: [
      SubtitleLine(
        startTime: const Duration(seconds: 0),
        endTime: const Duration(seconds: 6),
        en: 'Good morning! Could I get a large iced latte, please?',
        cn: '早上好！请给我来一杯大杯冰拿铁好吗？',
      ),
      SubtitleLine(
        startTime: const Duration(seconds: 6),
        endTime: const Duration(seconds: 12),
        en: 'Sure! Would you like regular milk or oat milk today?',
        cn: '当然可以！今天您想要普通牛奶还是燕麦奶？',
      ),
      SubtitleLine(
        startTime: const Duration(seconds: 12),
        endTime: const Duration(seconds: 20),
        en: 'Oat milk sounds great. Thank you so much!',
        cn: '燕麦奶听起来很棒。非常感谢！',
      ),
    ],
  ),
];

final Map<String, String> mockDictionary = {
  'welcome': '/ˈwelkəm/ interj./v. 欢迎；受欢迎的',
  'daily': '/ˈdeɪli/ adj. 每日的，日常的',
  'habit': '/ˈhæbɪt/ n. 习惯，习性',
  'massive': '/ˈmæsɪv/ adj. 巨大的，大量的',
  'success': '/səkˈses/ n. 成功，成就',
  'persistence': '/pəˈsɪstəns/ n. 坚持不懈，毅力',
  'patience': '/ˈpeɪʃns/ n. 耐心，忍耐力',
  'language': '/ˈlæŋɡwɪdʒ/ n. 语言；语言文字',
  'mastering': '/ˈmɑːstərɪŋ/ v. 精通，掌握',
  'clicking': '/ˈklɪkɪŋ/ v. 点击',
  'sentence': '/ˈsentəns/ n. 句子；宣判',
  'morning': '/ˈmɔːnɪŋ/ n. 早晨，上午',
  'latte': '/ˈlɑːteɪ/ n. 拿铁咖啡',
};

final List<Map<String, String>> savedWords = [];

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const ArticleListScreen(),
      const VocabularyScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.headphones), label: '每日听力'),
          NavigationDestination(icon: Icon(Icons.book), label: '生词本'),
        ],
      ),
    );
  }
}

class ArticleListScreen extends StatelessWidget {
  const ArticleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日英语听力', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: mockArticles.length,
        itemBuilder: (context, index) {
          final article = mockArticles[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.play_arrow_rounded, size: 32),
              ),
              title: Text(article.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(article.category, style: const TextStyle(fontSize: 12, color: Colors.blue)),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(article.durationStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlayerScreen(article: article)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

enum LanguageMode { bilingual, englishOnly, chineseOnly }

class PlayerScreen extends StatefulWidget {
  final Article article;
  const PlayerScreen({super.key, required this.article});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 25);
  double _playbackRate = 1.0;
  bool _isSingleLoop = false;
  LanguageMode _langMode = LanguageMode.bilingual;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    _audioPlayer.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);

      if (_isSingleLoop) {
        final currentLine = _getCurrentSubtitleLine();
        if (currentLine != null && pos >= currentLine.endTime) {
          _audioPlayer.seek(currentLine.startTime);
        }
      }
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      if (!mounted) return;
      setState(() => _duration = dur);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });

    await _audioPlayer.setSourceUrl(widget.article.audioUrl);
  }

  SubtitleLine? _getCurrentSubtitleLine() {
    for (final line in widget.article.subtitles) {
      if (_position >= line.startTime && _position <= line.endTime) {
        return line;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showWordLookup(String rawWord) {
    final cleanWord = rawWord.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
    if (cleanWord.isEmpty) return;

    final meaning = mockDictionary[cleanWord] ?? '暂未收录该词释义（v0.2.0 将接入在线词典 API）';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(cleanWord, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  FilledButton.icon(
                    onPressed: () {
                      final exists = savedWords.any((w) => w['word'] == cleanWord);
                      if (!exists) {
                        savedWords.add({'word': cleanWord, 'meaning': meaning});
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已将 "$cleanWord" 加入生词本')),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('加入生词本'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(meaning, style: const TextStyle(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClickableEnglishText(String sentence, bool isActive) {
    final words = sentence.split(' ');
    return RichText(
      text: TextSpan(
        children: words.map((word) {
          return TextSpan(
            text: '$word ',
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Theme.of(context).colorScheme.primary : Colors.black87,
            ),
            recognizer: TapGestureRecognizer()..onTap = () => _showWordLookup(word),
          );
        }).toList(),
      ),
    );
  }

  void _toggleSpeed() {
    final speeds = [0.8, 1.0, 1.25, 1.5, 2.0];
    final nextIndex = (speeds.indexOf(_playbackRate) + 1) % speeds.length;
    setState(() => _playbackRate = speeds[nextIndex]);
    _audioPlayer.setPlaybackRate(_playbackRate);
  }

  void _toggleLanguageMode() {
    setState(() {
      if (_langMode == LanguageMode.bilingual) {
        _langMode = LanguageMode.englishOnly;
      } else if (_langMode == LanguageMode.englishOnly) {
        _langMode = LanguageMode.chineseOnly;
      } else {
        _langMode = LanguageMode.bilingual;
      }
    });
  }

  String _getLangModeLabel() {
    switch (_langMode) {
      case LanguageMode.bilingual:
        return '中英';
      case LanguageMode.englishOnly:
        return '纯英';
      case LanguageMode.chineseOnly:
        return '纯中';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.title, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: _toggleLanguageMode,
            child: Text(_getLangModeLabel(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.amber.withOpacity(0.15),
            child: const Text(
              '💡 提示：直接点击字幕中的英文单词即可查词；点击整行旁的播放图标可跳转进度。',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.article.subtitles.length,
              itemBuilder: (context, index) {
                final line = widget.article.subtitles[index];
                final isActive = _position >= line.startTime && _position <= line.endTime;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.play_circle_outline,
                          size: 22,
                          color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
                        ),
                        onPressed: () {
                          _audioPlayer.seek(line.startTime);
                          _audioPlayer.resume();
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_langMode != LanguageMode.chineseOnly)
                              _buildClickableEnglishText(line.en, isActive),
                            if (_langMode != LanguageMode.englishOnly) ...[
                              const SizedBox(height: 6),
                              Text(
                                line.cn,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isActive ? Colors.black87 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                    max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                    onChanged: (val) => _audioPlayer.seek(Duration(seconds: val.toInt())),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _toggleSpeed,
                        child: Text('${_playbackRate}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.replay_5),
                        onPressed: () {
                          final target = _position - const Duration(seconds: 5);
                          _audioPlayer.seek(target < Duration.zero ? Duration.zero : target);
                        },
                      ),
                      FloatingActionButton(
                        elevation: 2,
                        onPressed: () {
                          if (_isPlaying) {
                            _audioPlayer.pause();
                          } else {
                            _audioPlayer.resume();
                          }
                        },
                        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_5),
                        onPressed: () => _audioPlayer.seek(_position + const Duration(seconds: 5)),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.repeat_one,
                          color: _isSingleLoop ? Theme.of(context).colorScheme.primary : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() => _isSingleLoop = !_isSingleLoop);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的生词本', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: savedWords.isEmpty
          ? const Center(
              child: Text('生词本还是空的，去听力字幕里点击单词添加吧！', style: TextStyle(color: Colors.grey)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: savedWords.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = savedWords[index];
                return ListTile(
                  title: Text(item['word']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(item['meaning']!),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => setState(() => savedWords.removeAt(index)),
                  ),
                );
              },
            ),
    );
  }
}
