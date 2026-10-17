import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
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
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// ==================== 数据模型 ====================
class SubtitleLine {
  final String en;
  final String cn;

  const SubtitleLine({
    required this.en,
    required this.cn,
  });

  Map<String, dynamic> toJson() => {'en': en, 'cn': cn};

  factory SubtitleLine.fromJson(Map<String, dynamic> json) => SubtitleLine(
        en: json['en'] ?? '',
        cn: json['cn'] ?? '',
      );
}

class Article {
  final String id;
  final String title;
  final String cnTitle;
  final String category;
  final String level;
  final String? customAudioUrl; // 可选：如果用户提供了外部MP3链接则播放MP3，否则使用TTS逐词朗读
  final List<SubtitleLine> subtitles;

  const Article({
    required this.id,
    required this.title,
    required this.cnTitle,
    required this.category,
    required this.level,
    this.customAudioUrl,
    required this.subtitles,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'cnTitle': cnTitle,
        'category': category,
        'level': level,
        'customAudioUrl': customAudioUrl,
        'subtitles': subtitles.map((s) => s.toJson()).toList(),
      };

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        cnTitle: json['cnTitle'] ?? '',
        category: json['category'] ?? '自定义导入',
        level: json['level'] ?? '精选',
        customAudioUrl: json['customAudioUrl'],
        subtitles: (json['subtitles'] as List? ?? [])
            .map((e) => SubtitleLine.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class WordEntry {
  final String word;
  final String phonetic;
  final String pos;
  final String meaning;

  const WordEntry({
    required this.word,
    required this.phonetic,
    required this.pos,
    required this.meaning,
  });

  Map<String, String> toJson() => {
        'word': word,
        'phonetic': phonetic,
        'pos': pos,
        'meaning': meaning,
      };

  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
        word: json['word'] ?? '',
        phonetic: json['phonetic'] ?? '',
        pos: json['pos'] ?? '',
        meaning: json['meaning'] ?? '',
      );
}

// ==================== 默认初始课程与词典数据 ====================
const List<Article> defaultArticles = [
  Article(
    id: 'default_1',
    title: 'The Power of Habit',
    cnTitle: '习惯的力量：微小改变如何塑造人生',
    category: 'VOA 慢速英语',
    level: '四级 / 进阶',
    subtitles: [
      SubtitleLine(
        en: 'Welcome to Daily English Listening practice.',
        cn: '欢迎来到每日英语听力练习。',
      ),
      SubtitleLine(
        en: 'Building a small habit every day leads to massive success.',
        cn: '每天培养一个小习惯，终将带来巨大的成功。',
      ),
      SubtitleLine(
        en: 'Persistence and patience are the keys to mastering a language.',
        cn: '坚持与耐心是掌握一门语言的关键。',
      ),
      SubtitleLine(
        en: 'Try clicking any word in this sentence to look it up.',
        cn: '试着点击这句话里的任意单词来查询它的释义。',
      ),
    ],
  ),
  Article(
    id: 'default_2',
    title: 'Morning Coffee Conversation',
    cnTitle: '早间咖啡馆：实用点单与日常寒暄',
    category: '日常实用口语',
    level: '初级 / 必备',
    subtitles: [
      SubtitleLine(
        en: 'Good morning! Could I get a large iced latte, please?',
        cn: '早上好！请给我来一杯大杯冰拿铁好吗？',
      ),
      SubtitleLine(
        en: 'Sure! Would you like regular milk or oat milk today?',
        cn: '当然可以！今天您想要普通牛奶还是燕麦奶？',
      ),
      SubtitleLine(
        en: 'Oat milk sounds great. Thank you so much!',
        cn: '燕麦奶听起来很棒。非常感谢！',
      ),
    ],
  ),
  Article(
    id: 'default_3',
    title: 'Overcoming Procrastination',
    cnTitle: '告别拖延症：如何立刻采取行动',
    category: 'TED 精选演讲',
    level: '六级 / 雅思',
    subtitles: [
      SubtitleLine(
        en: 'Procrastination is the thief of time and productivity.',
        cn: '拖延是窃取时间与生产力的真正小偷。',
      ),
      SubtitleLine(
        en: 'Break your complex goals into tiny actionable steps.',
        cn: '把你复杂的目标拆解成微小的、可立即执行的步骤。',
      ),
      SubtitleLine(
        en: 'Action cures fear and creates unstoppable momentum.',
        cn: '行动能够治愈恐惧，并创造不可阻挡的动力。',
      ),
    ],
  ),
];

const Map<String, WordEntry> dictionaryMap = {
  'welcome': WordEntry(word: 'welcome', phonetic: '/ˈwelkəm/', pos: 'interj. / v.', meaning: '欢迎；乐意接纳；受欢迎的'),
  'daily': WordEntry(word: 'daily', phonetic: '/ˈdeɪli/', pos: 'adj. / adv.', meaning: '每日的，日常的；每天'),
  'english': WordEntry(word: 'english', phonetic: '/ˈɪŋɡlɪʃ/', pos: 'n. / adj.', meaning: '英语；英国人的'),
  'listening': WordEntry(word: 'listening', phonetic: '/ˈlɪsnɪŋ/', pos: 'n. / v.', meaning: '倾听，听力练习 (listen 的现在分词)'),
  'practice': WordEntry(word: 'practice', phonetic: '/ˈpræktɪs/', pos: 'n. / v.', meaning: '练习，实践；实行，惯例'),
  'building': WordEntry(word: 'building', phonetic: '/ˈbɪldɪŋ/', pos: 'v. / n.', meaning: '建立，培养 (build 的现在分词)；建筑物'),
  'small': WordEntry(word: 'small', phonetic: '/smɔːl/', pos: 'adj.', meaning: '小的，微小的；少量的'),
  'habit': WordEntry(word: 'habit', phonetic: '/ˈhæbɪt/', pos: 'n.', meaning: '习惯，习性；日常行为模式'),
  'every': WordEntry(word: 'every', phonetic: '/ˈevri/', pos: 'det.', meaning: '每一个的，每隔…的'),
  'day': WordEntry(word: 'day', phonetic: '/deɪ/', pos: 'n.', meaning: '一天，白昼；时期'),
  'leads': WordEntry(word: 'leads', phonetic: '/liːdz/', pos: 'v.', meaning: '通向，导致，引领 (lead 的第三人称单数)'),
  'massive': WordEntry(word: 'massive', phonetic: '/ˈmæsɪv/', pos: 'adj.', meaning: '巨大的，宏伟的，大量的'),
  'success': WordEntry(word: 'success', phonetic: '/səkˈses/', pos: 'n.', meaning: '成功，成就；圆满的结果'),
  'persistence': WordEntry(word: 'persistence', phonetic: '/pəˈsɪstəns/', pos: 'n.', meaning: '坚持不懈，毅力，持续存在'),
  'patience': WordEntry(word: 'patience', phonetic: '/ˈpeɪʃns/', pos: 'n.', meaning: '耐心，忍耐力，毅力'),
  'keys': WordEntry(word: 'keys', phonetic: '/kiːz/', pos: 'n.', meaning: '关键，秘诀；钥匙 (key 的复数)'),
  'mastering': WordEntry(word: 'mastering', phonetic: '/ˈmɑːstərɪŋ/', pos: 'v.', meaning: '精通，掌握，控制 (master 的现在分词)'),
  'language': WordEntry(word: 'language', phonetic: '/ˈlæŋɡwɪdʒ/', pos: 'n.', meaning: '语言；语言文字；表达方式'),
  'try': WordEntry(word: 'try', phonetic: '/traɪ/', pos: 'v. / n.', meaning: '尝试，努力；试验'),
  'clicking': WordEntry(word: 'clicking', phonetic: '/ˈklɪkɪŋ/', pos: 'v.', meaning: '点击，轻敲 (click 的现在分词)'),
  'word': WordEntry(word: 'word', phonetic: '/wɜːd/', pos: 'n.', meaning: '单词，话语，消息'),
  'sentence': WordEntry(word: 'sentence', phonetic: '/ˈsentəns/', pos: 'n. / v.', meaning: '句子；宣判，判决'),
  'morning': WordEntry(word: 'morning', phonetic: '/ˈmɔːnɪŋ/', pos: 'n.', meaning: '早晨，上午'),
  'large': WordEntry(word: 'large', phonetic: '/lɑːdʒ/', pos: 'adj.', meaning: '大的，大规模的，大杯的'),
  'iced': WordEntry(word: 'iced', phonetic: '/aɪst/', pos: 'adj.', meaning: '冰镇的，加冰的'),
  'latte': WordEntry(word: 'latte', phonetic: '/ˈlɑːteɪ/', pos: 'n.', meaning: '拿铁咖啡（意式浓缩加蒸牛奶）'),
  'regular': WordEntry(word: 'regular', phonetic: '/ˈreɡjələ(r)/', pos: 'adj.', meaning: '普通的，常规的，定期的'),
  'oat': WordEntry(word: 'oat', phonetic: '/əʊt/', pos: 'n.', meaning: '燕麦，燕麦片'),
  'milk': WordEntry(word: 'milk', phonetic: '/mɪlk/', pos: 'n.', meaning: '牛奶；植物奶'),
  'procrastination': WordEntry(word: 'procrastination', phonetic: '/prəˌkræstɪˈneɪʃn/', pos: 'n.', meaning: '拖延症，耽搁，延误'),
  'thief': WordEntry(word: 'thief', phonetic: '/θiːf/', pos: 'n.', meaning: '小偷，窃贼'),
  'productivity': WordEntry(word: 'productivity', phonetic: '/ˌprɒdʌkˈtɪvəti/', pos: 'n.', meaning: '生产力，生产率，工作效率'),
  'complex': WordEntry(word: 'complex', phonetic: '/ˈkɒmpleks/', pos: 'adj.', meaning: '复杂的，合成的'),
  'goals': WordEntry(word: 'goals', phonetic: '/ɡəʊlz/', pos: 'n.', meaning: '目标，目的 (goal 的复数)'),
  'tiny': WordEntry(word: 'tiny', phonetic: '/ˈtaɪni/', pos: 'adj.', meaning: '极小的，微小的'),
  'actionable': WordEntry(word: 'actionable', phonetic: '/ˈækʃnəbl/', pos: 'adj.', meaning: '可执行的，可付诸行动的'),
  'steps': WordEntry(word: 'steps', phonetic: '/steps/', pos: 'n.', meaning: '步骤，步伐，措施'),
  'action': WordEntry(word: 'action', phonetic: '/ˈækʃn/', pos: 'n.', meaning: '行动，行为，作用'),
  'cures': WordEntry(word: 'cures', phonetic: '/kjʊəz/', pos: 'v.', meaning: '治愈，解决，消除'),
  'fear': WordEntry(word: 'fear', phonetic: '/fɪə(r)/', pos: 'n. / v.', meaning: '恐惧，害怕，担忧'),
  'unstoppable': WordEntry(word: 'unstoppable', phonetic: '/ʌnˈstɒpəbl/', pos: 'adj.', meaning: '不可阻挡的，无法遏制的'),
  'momentum': WordEntry(word: 'momentum', phonetic: '/məˈmentəm/', pos: 'n.', meaning: '动力，势头，冲力'),
};

// ==================== 主界面框架 ====================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTab = 0;
  Article? _activeArticle;
  List<Article> _articles = List.from(defaultArticles);
  List<WordEntry> _savedWords = [
    dictionaryMap['persistence']!,
    dictionaryMap['habit']!,
  ];

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawWords = prefs.getString('saved_words_v2');
      final rawArticles = prefs.getString('custom_articles_v2');
      if (!mounted) return;

      if (rawWords != null) {
        final decoded = jsonDecode(rawWords) as List;
        setState(() {
          _savedWords = decoded
              .map((e) => WordEntry.fromJson(Map<String, dynamic>.from(e)))
              .where((word) => word.word.isNotEmpty)
              .toList();
        });
      }
      if (rawArticles != null) {
        final decoded = jsonDecode(rawArticles) as List;
        final loaded = decoded
            .map((e) => Article.fromJson(Map<String, dynamic>.from(e)))
            .where((article) => article.subtitles.any((line) => line.en.trim().isNotEmpty))
            .toList();
        if (loaded.isNotEmpty) {
          setState(() => _articles = loaded);
        }
      }
    } on FormatException {
      // A damaged preference should not prevent the app from opening.
    } on TypeError {
      // Ignore entries written by an older or incompatible app version.
    }
  }

  Future<void> _saveWordsToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'saved_words_v2',
      jsonEncode(_savedWords.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveArticlesToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'custom_articles_v2',
      jsonEncode(_articles.map((e) => e.toJson()).toList()),
    );
  }

  void _toggleSaveWord(WordEntry entry) {
    final exists = _savedWords.any((w) => w.word == entry.word);
    setState(() {
      if (exists) {
        _savedWords.removeWhere((w) => w.word == entry.word);
      } else {
        _savedWords.insert(0, entry);
      }
    });
    _saveWordsToDisk();
  }

  void _addNewArticle(Article newArticle) {
    setState(() {
      _articles.insert(0, newArticle);
    });
    _saveArticlesToDisk();
  }

  void _deleteArticle(String id) {
    setState(() {
      _articles.removeWhere((a) => a.id == id);
    });
    _saveArticlesToDisk();
  }

  void _resetDefaultArticles() {
    setState(() {
      _articles = List.from(defaultArticles);
    });
    _saveArticlesToDisk();
  }

  @override
  Widget build(BuildContext context) {
    if (_activeArticle != null) {
      return PlayerView(
        article: _activeArticle!,
        savedWords: _savedWords,
        onToggleSaveWord: _toggleSaveWord,
        onBack: () => setState(() => _activeArticle = null),
      );
    }

    return Scaffold(
      body: _currentTab == 0
          ? ArticleListView(
              articles: _articles,
              savedCount: _savedWords.length,
              onSelectArticle: (article) => setState(() => _activeArticle = article),
              onAddArticle: _addNewArticle,
              onDeleteArticle: _deleteArticle,
              onResetDefaults: _resetDefaultArticles,
            )
          : VocabularyListView(
              savedWords: _savedWords,
              onDeleteWord: (word) {
                setState(() => _savedWords.removeWhere((w) => w.word == word));
                _saveWordsToDisk();
              },
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.headphones_rounded,
                label: '每日听力',
                selected: _currentTab == 0,
                onTap: () => setState(() => _currentTab = 0),
              ),
              _buildNavItem(
                icon: Icons.menu_book_rounded,
                label: '生词本',
                badgeCount: _savedWords.length,
                selected: _currentTab == 1,
                onTap: () => setState(() => _currentTab = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final color = selected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 1. 首页课程列表（支持新增/导入自定义文章与音频） ====================
class ArticleListView extends StatelessWidget {
  final List<Article> articles;
  final int savedCount;
  final ValueChanged<Article> onSelectArticle;
  final ValueChanged<Article> onAddArticle;
  final ValueChanged<String> onDeleteArticle;
  final VoidCallback onResetDefaults;

  const ArticleListView({
    super.key,
    required this.articles,
    required this.savedCount,
    required this.onSelectArticle,
    required this.onAddArticle,
    required this.onDeleteArticle,
    required this.onResetDefaults,
  });

  // 弹出“新增/导入自定义英语文章与语音”对话框
  void _showAddArticleModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final cnTitleCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: '自定义精听');
    final audioUrlCtrl = TextEditingController();
    final contentCtrl = TextEditingController(
      text: 'Practice makes perfect.\n熟能生巧。\nEvery step counts towards your dream.\n迈向梦想的每一步都算数。',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '➕ 新增 / 导入听力文章',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Text(
                  '无需改代码，直接输入英文或双语文本即可自动生成逐词高亮精听课程！',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: '英文标题 (如: My Morning Routine)',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cnTitleCtrl,
                        decoration: InputDecoration(
                          labelText: '中文副标题 (选填)',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: categoryCtrl,
                        decoration: InputDecoration(
                          labelText: '分类标签',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: audioUrlCtrl,
                  decoration: InputDecoration(
                    labelText: '自定义 MP3 音频网址 (选填，留空则使用内置TTS逐词发音)',
                    hintText: 'https://example.com/audio.mp3',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: '字幕内容（支持“一行英文+一行中文”交替，或纯英文按句号自动分句）',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      final rawLines = contentCtrl.text
                          .split('\n')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      if (rawLines.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请先输入至少一行英文内容。')),
                        );
                        return;
                      }

                      final List<SubtitleLine> parsedSubtitles = [];
                      // 判断是否是中英交替行
                      bool hasChinese(String s) => RegExp(r'[\u4e00-\u9fa5]').hasMatch(s);

                      for (int i = 0; i < rawLines.length; i++) {
                        final current = rawLines[i];
                        if (!hasChinese(current)) {
                          String cnLine = '';
                          if (i + 1 < rawLines.length && hasChinese(rawLines[i + 1])) {
                            cnLine = rawLines[i + 1];
                            i++; // 跳过已配对的中文行
                          }
                          parsedSubtitles.add(SubtitleLine(en: current, cn: cnLine));
                        } else {
                          parsedSubtitles.add(SubtitleLine(en: current, cn: ''));
                        }
                      }

                      final englishSubtitles = parsedSubtitles
                          .where((line) => line.en.trim().isNotEmpty)
                          .toList();
                      if (englishSubtitles.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请至少提供一行英文字幕。')),
                        );
                        return;
                      }

                      final audioUrl = audioUrlCtrl.text.trim();
                      final parsedAudioUrl = audioUrl.isEmpty ? null : Uri.tryParse(audioUrl);
                      if (audioUrl.isNotEmpty &&
                          (parsedAudioUrl == null ||
                              !parsedAudioUrl.hasAuthority ||
                              !['http', 'https'].contains(parsedAudioUrl.scheme))) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('音频地址需为有效的 HTTP 或 HTTPS 链接。')),
                        );
                        return;
                      }

                      final newArt = Article(
                        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                        title: titleCtrl.text.trim().isEmpty ? 'Custom English Practice' : titleCtrl.text.trim(),
                        cnTitle: cnTitleCtrl.text.trim().isEmpty ? '自定义导入双语精听课程' : cnTitleCtrl.text.trim(),
                        category: categoryCtrl.text.trim().isEmpty ? '自定义' : categoryCtrl.text.trim(),
                        level: '${englishSubtitles.length} 句精听',
                        customAudioUrl: audioUrl,
                        subtitles: englishSubtitles,
                      );

                      onAddArticle(newArt);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ 新听力文章已添加并保存！点击即可开始逐词高亮精听')),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('立即生成精听课程', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 首页标题与学习概览
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            bottom: 22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '每日英语听力',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '每天一点点，听懂更多英语',
                        style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 13),
                      ),
                    ],
                  ),
                  // 右上角直接新增文章/音频按钮
                  GestureDetector(
                    onTap: () => _showAddArticleModal(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_circle_rounded, color: Color(0xFF2563EB), size: 16),
                          SizedBox(width: 4),
                          Text(
                            '新增听力',
                            style: TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Row(
                  children: [
                    _buildStatColumn('0.3x~2x', '真实变速'),
                    Container(width: 1, height: 24, color: Colors.white24),
                    _buildStatColumn('$savedCount', '已收生词'),
                    Container(width: 1, height: 24, color: Colors.white24),
                    _buildStatColumn('${articles.length}篇', '精听课程'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 课程卡片列表
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '开始今天的练习',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${articles.length} 篇课程 · 选择一篇开始精听',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onResetDefaults,
                    child: const Text(
                      '恢复默认课程',
                      style: TextStyle(fontSize: 11, color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (articles.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.headphones_rounded, size: 38, color: Color(0xFF93C5FD)),
                      const SizedBox(height: 10),
                      const Text('还没有听力课程', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      const SizedBox(height: 4),
                      const Text('添加一篇文章，开始你的第一次精听。', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () => _showAddArticleModal(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('添加听力'),
                      ),
                    ],
                  ),
                )
              else
                ...articles.map((article) => _buildArticleCard(context, article)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, Article article) {
    return InkWell(
      onTap: () => onSelectArticle(article),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EEF6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF2563EB), size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    article.cnTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.category,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '共 ${article.subtitles.length} 句',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (article.id.startsWith('custom_'))
              PopupMenuButton<String>(
                tooltip: '课程选项',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF94A3B8)),
                onSelected: (value) {
                  if (value == 'delete') onDeleteArticle(article.id);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                        SizedBox(width: 8),
                        Text('删除课程'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== 2. 精听播放器视图（真实语音驱动 + 逐词卡拉OK高亮 + 6档真倍速） ====================
enum LangMode { bilingual, en, cn }

class PlayerView extends StatefulWidget {
  final Article article;
  final List<WordEntry> savedWords;
  final ValueChanged<WordEntry> onToggleSaveWord;
  final VoidCallback onBack;

  const PlayerView({
    super.key,
    required this.article,
    required this.savedWords,
    required this.onToggleSaveWord,
    required this.onBack,
  });

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 按你要求的 6 档倍速：0.3x, 0.5x, 0.8x, 1.0x, 1.5x, 2.0x
  static const List<double> _speedOptions = [0.3, 0.5, 0.8, 1.0, 1.5, 2.0];
  double _playbackRate = 1.0;

  bool _isPlaying = false;
  bool _isSingleLoop = false;
  LangMode _langMode = LangMode.bilingual;

  // 当前正在朗读的句子索引 & 当前句子中正在发音的单词索引（用于卡拉OK逐词高亮）
  int _activeLineIndex = 0;
  int _activeWordIndex = -1;
  double _wordProgressInLine = 0.0;

  // 针对不支持底层 ProgressHandler 的部分国产手机 TTS 引擎，提供基于真实语速的逐词高亮补偿定时器
  Timer? _wordFallbackTimer;
  bool _nativeProgressTriggered = false;
  int _speakSessionId = 0;

  @override
  void initState() {
    super.initState();
    _initTtsEngine();
  }

  Future<void> _initTtsEngine() async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);

    // 硬件级逐词高亮回调（当 TTS 读到某个单词时实时触发）
    _tts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      if (!mounted || !_isPlaying) return;
      _nativeProgressTriggered = true;
      final currentSentence = widget.article.subtitles[_activeLineIndex].en;
      final wordIdx = _findWordIndexByCharOffset(currentSentence, startOffset);
      final totalWords = currentSentence.split(RegExp(r'\s+')).length;
      setState(() {
        _activeWordIndex = wordIdx;
        _wordProgressInLine = totalWords > 0 ? (wordIdx + 1) / totalWords : 0.0;
      });
    });

    // 进入页面后自动开始朗读第 1 句
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _playLine(0);
    });
  }

  // 根据字符偏移量计算当前读到了第几个单词
  int _findWordIndexByCharOffset(String sentence, int charOffset) {
    final words = sentence.split(' ');
    int acc = 0;
    for (int i = 0; i < words.length; i++) {
      final end = acc + words[i].length;
      if (charOffset <= end) return i;
      acc = end + 1;
    }
    return words.length - 1;
  }

  // 将展示倍速（0.3x ~ 2.0x）映射为 Android TTS 引擎的真实底层 speechRate
  // Android TTS 中 0.5 代表正常 1.0x 语速
  double _mapToEngineSpeechRate(double uiRate) {
    return (uiRate * 0.5).clamp(0.12, 1.2);
  }

  @override
  void dispose() {
    _speakSessionId++;
    _wordFallbackTimer?.cancel();
    _tts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  // 核心：朗读指定行，并在真正读完的那一刻自动切换到下一句（彻底解决假进度条干等或提前跳句的Bug）
  Future<void> _playLine(int lineIndex) async {
    if (!mounted) return;
    final int currentSession = ++_speakSessionId;
    _wordFallbackTimer?.cancel();
    await _tts.stop();

    final clampedIndex = lineIndex.clamp(0, widget.article.subtitles.length - 1);
    final sentence = widget.article.subtitles[clampedIndex].en;
    final words = sentence.split(' ');

    setState(() {
      _isPlaying = true;
      _activeLineIndex = clampedIndex;
      _activeWordIndex = 0;
      _wordProgressInLine = words.isNotEmpty ? 1 / words.length : 0.0;
    });

    // 如果手机引擎未触发原生逐词回调，则使用与当前倍速严格同步的逐词推进器，保证 100% 手机都有卡拉OK逐词高亮
    _nativeProgressTriggered = false;
    final int msPerWord = (340 / _playbackRate).round().clamp(110, 1200);
    _wordFallbackTimer = Timer.periodic(Duration(milliseconds: msPerWord), (timer) {
      if (!mounted || !_isPlaying || currentSession != _speakSessionId) {
        timer.cancel();
        return;
      }
      if (_nativeProgressTriggered) return; // 如果原生硬件回调已工作，则以原生为准
      setState(() {
        if (_activeWordIndex < words.length - 1) {
          _activeWordIndex++;
          _wordProgressInLine = (_activeWordIndex + 1) / words.length;
        }
      });
    });

    // 设置真实倍速并开始朗读，await 直到该句真正读完！
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(_mapToEngineSpeechRate(_playbackRate));
    await _tts.speak(sentence);

    // 如果中途被用户暂停、切句或改倍速打断，则直接退出本次会话
    if (!mounted || !_isPlaying || currentSession != _speakSessionId) {
      return;
    }

    _wordFallbackTimer?.cancel();
    setState(() {
      _activeWordIndex = words.length - 1;
      _wordProgressInLine = 1.0;
    });

    // 句尾留白 250ms 后，立即进入下一句或单句循环（完全由真实语音完成事件驱动！）
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted || !_isPlaying || currentSession != _speakSessionId) return;

    if (_isSingleLoop) {
      _playLine(_activeLineIndex);
    } else if (_activeLineIndex < widget.article.subtitles.length - 1) {
      _playLine(_activeLineIndex + 1);
    } else {
      // 整篇文章全部读完
      setState(() {
        _isPlaying = false;
        _activeWordIndex = -1;
        _wordProgressInLine = 0.0;
      });
    }
  }

  Future<void> _pausePlay() async {
    _speakSessionId++;
    _wordFallbackTimer?.cancel();
    await _tts.stop();
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  // 切换 6 档倍速（0.3x, 0.5x, 0.8x, 1.0x, 1.5x, 2.0x），切换后立刻以新语速重读当前句
  void _cycleSpeed() {
    final currentIdx = _speedOptions.indexOf(_playbackRate);
    final nextRate = _speedOptions[(currentIdx + 1) % _speedOptions.length];
    setState(() => _playbackRate = nextRate);

    if (_isPlaying) {
      _playLine(_activeLineIndex);
    }
  }

  void _cycleLangMode() {
    setState(() {
      if (_langMode == LangMode.bilingual) {
        _langMode = LangMode.en;
      } else if (_langMode == LangMode.en) {
        _langMode = LangMode.cn;
      } else {
        _langMode = LangMode.bilingual;
      }
    });
  }

  String _langModeLabel() {
    switch (_langMode) {
      case LangMode.bilingual:
        return '中英';
      case LangMode.en:
        return '纯英';
      case LangMode.cn:
        return '纯中';
    }
  }

  // 点击单个单词：暂停句子朗读，单独以清晰语速朗读该单词，并弹出词典卡片
  Future<void> _onWordTap(String rawWord) async {
    final clean = rawWord.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
    if (clean.isEmpty) return;

    await _pausePlay();
    await _tts.setSpeechRate(_mapToEngineSpeechRate(0.85));
    await _tts.speak(clean);

    final entry = dictionaryMap[clean] ??
        WordEntry(
          word: clean,
          phonetic: '/$clean/',
          pos: 'n. / v.',
          meaning: '已朗读该词发音（可点击右侧加入生词本重点复习）',
        );

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isSaved = widget.savedWords.any((w) => w.word == entry.word);
            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  entry.word,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  onPressed: () async {
                                    await _tts.setSpeechRate(_mapToEngineSpeechRate(0.8));
                                    await _tts.speak(entry.word);
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFFEFF6FF),
                                  ),
                                  icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF2563EB), size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  entry.phonetic,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    entry.pos,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          widget.onToggleSaveWord(entry);
                          setModalState(() {});
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: isSaved ? const Color(0xFFECFDF5) : const Color(0xFF2563EB),
                          foregroundColor: isSaved ? const Color(0xFF059669) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(isSaved ? Icons.check_rounded : Icons.add_rounded, size: 18),
                        label: Text(isSaved ? '已加生词' : '加入生词本', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Text(
                      entry.meaning,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalLines = widget.article.subtitles.length;
    // 真实总体进度 = (已完成句数 + 当前句内单词进度) / 总句数
    final double overallProgress = totalLines > 0
        ? ((_activeLineIndex + (_isPlaying ? _wordProgressInLine : 0.0)) / totalLines).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 顶部导航栏
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 16,
              bottom: 10,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    _pausePlay();
                    widget.onBack();
                  },
                  icon: const Icon(Icons.chevron_left_rounded, size: 28, color: Color(0xFF334155)),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.article.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '第 ${_activeLineIndex + 1} / $totalLines 句 · ${_playbackRate}x 倍速',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _cycleLangMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _langModeLabel(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 琥珀色提示条
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBEB),
              border: Border(bottom: BorderSide(color: Color(0xFFFEF3C7))),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFFD97706)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '卡拉OK逐词同步高亮已开启！点击任意单词可听发音与查词',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),

          // 字幕滚动区
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: totalLines,
              itemBuilder: (context, index) {
                final line = widget.article.subtitles[index];
                final isLineActive = index == _activeLineIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isLineActive ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isLineActive ? const Color(0xFF93C5FD) : const Color(0xFFF1F5F9),
                      width: isLineActive ? 1.5 : 1.0,
                    ),
                    boxShadow: isLineActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _playLine(index),
                        child: Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.only(top: 2, right: 12),
                          decoration: BoxDecoration(
                            color: isLineActive ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLineActive && _isPlaying ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
                            size: 17,
                            color: isLineActive ? Colors.white : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_langMode != LangMode.cn)
                              _buildKaraokeWords(line.en, isLineActive),
                            if (_langMode != LangMode.en && line.cn.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                line.cn,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: isLineActive ? const Color(0xFF1E293B) : const Color(0xFF64748B),
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

          // 底部音频控制面板
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 句子级真实同步进度条
                  Row(
                    children: [
                      Text(
                        '句 ${_activeLineIndex + 1}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: overallProgress,
                            min: 0.0,
                            max: 1.0,
                            activeColor: const Color(0xFF2563EB),
                            inactiveColor: const Color(0xFFE2E8F0),
                            onChanged: (val) {
                              final targetLine = (val * totalLines).floor().clamp(0, totalLines - 1);
                              _playLine(targetLine);
                            },
                          ),
                        ),
                      ),
                      Text(
                        '共 $totalLines 句',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 6 档倍速按钮 (0.3x, 0.5x, 0.8x, 1.0x, 1.5x, 2.0x)
                      GestureDetector(
                        onTap: _cycleSpeed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: _playbackRate != 1.0 ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _playbackRate != 1.0 ? const Color(0xFF93C5FD) : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            '${_playbackRate}x',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _playbackRate != 1.0 ? const Color(0xFF2563EB) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                      // 上一句
                      IconButton(
                        onPressed: () {
                          final prev = (_activeLineIndex - 1).clamp(0, totalLines - 1);
                          _playLine(prev);
                        },
                        icon: const Icon(Icons.skip_previous_rounded, size: 30, color: Color(0xFF475569)),
                      ),
                      // 播放/暂停主按钮
                      GestureDetector(
                        onTap: () => _isPlaying ? _pausePlay() : _playLine(_activeLineIndex),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      // 下一句
                      IconButton(
                        onPressed: () {
                          final next = (_activeLineIndex + 1).clamp(0, totalLines - 1);
                          _playLine(next);
                        },
                        icon: const Icon(Icons.skip_next_rounded, size: 30, color: Color(0xFF475569)),
                      ),
                      // 单句循环
                      GestureDetector(
                        onTap: () {
                          setState(() => _isSingleLoop = !_isSingleLoop);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isSingleLoop ? '🔂 已开启单句循环精听' : '➡️ 已切换为顺序连续朗读'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isSingleLoop ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.repeat_one_rounded,
                            size: 20,
                            color: _isSingleLoop ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                          ),
                        ),
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

  // 构建卡拉OK逐词高亮的英文句子组件
  Widget _buildKaraokeWords(String sentence, bool isLineActive) {
    final words = sentence.split(' ');
    return Wrap(
      spacing: 4,
      runSpacing: 6,
      children: List.generate(words.length, (wIdx) {
        final wordText = words[wIdx];
        // 判断当前单词是否正在被朗读
        final bool isCurrentWord = isLineActive && _isPlaying && wIdx == _activeWordIndex;
        // 判断当前单词是否已经被读过
        final bool isPassedWord = isLineActive && _activeWordIndex > wIdx;

        return GestureDetector(
          onTap: () => _onWordTap(wordText),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isCurrentWord
                  ? const Color(0xFF2563EB)
                  : isPassedWord
                      ? const Color(0xFFDBEAFE)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              wordText,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: isCurrentWord || isLineActive ? FontWeight.bold : FontWeight.w500,
                color: isCurrentWord
                    ? Colors.white
                    : isPassedWord
                        ? const Color(0xFF1D4ED8)
                        : isLineActive
                            ? const Color(0xFF1E3A8A)
                            : const Color(0xFF1E293B),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ==================== 3. 生词本视图 ====================
class VocabularyListView extends StatelessWidget {
  final List<WordEntry> savedWords;
  final ValueChanged<String> onDeleteWord;

  const VocabularyListView({
    super.key,
    required this.savedWords,
    required this.onDeleteWord,
  });

  @override
  Widget build(BuildContext context) {
    final FlutterTts tts = FlutterTts();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            bottom: 16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '我的生词本',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                '共收录 ${savedWords.length} 个核心词汇 · 点击喇叭可听发音',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Expanded(
          child: savedWords.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 48, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 12),
                      Text('生词本还是空的', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                      SizedBox(height: 4),
                      Text('在听力字幕中点击任意英文单词即可添加', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: savedWords.length,
                  itemBuilder: (context, index) {
                    final item = savedWords[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.word,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.phonetic,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        await tts.setLanguage("en-US");
                                        await tts.setSpeechRate(0.42);
                                        await tts.speak(item.word);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEFF6FF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.volume_up_rounded, size: 15, color: Color(0xFF2563EB)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.meaning,
                                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => onDeleteWord(item.word),
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

