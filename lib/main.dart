import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  final int startSec;
  final int endSec;
  final String en;
  final String cn;

  const SubtitleLine({
    required this.startSec,
    required this.endSec,
    required this.en,
    required this.cn,
  });
}

class Article {
  final String id;
  final String title;
  final String cnTitle;
  final String category;
  final String level;
  final String durationStr;
  final int totalSeconds;
  final List<SubtitleLine> subtitles;

  const Article({
    required this.id,
    required this.title,
    required this.cnTitle,
    required this.category,
    required this.level,
    required this.durationStr,
    required this.totalSeconds,
    required this.subtitles,
  });
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

// ==================== 内置课程与完整词典数据（与预览版 100% 同步） ====================
const List<Article> mockArticles = [
  Article(
    id: '1',
    title: 'The Power of Habit',
    cnTitle: '习惯的力量：微小改变如何塑造人生',
    category: 'VOA 慢速英语',
    level: '四级 / 进阶',
    durationStr: '00:28',
    totalSeconds: 28,
    subtitles: [
      SubtitleLine(
        startSec: 0,
        endSec: 6,
        en: 'Welcome to Daily English Listening practice.',
        cn: '欢迎来到每日英语听力练习。',
      ),
      SubtitleLine(
        startSec: 6,
        endSec: 13,
        en: 'Building a small habit every day leads to massive success.',
        cn: '每天培养一个小习惯，终将带来巨大的成功。',
      ),
      SubtitleLine(
        startSec: 13,
        endSec: 21,
        en: 'Persistence and patience are the keys to mastering a language.',
        cn: '坚持与耐心是掌握一门语言的关键。',
      ),
      SubtitleLine(
        startSec: 21,
        endSec: 28,
        en: 'Try clicking any word in this sentence to look it up.',
        cn: '试着点击这句话里的任意单词来查询它的释义。',
      ),
    ],
  ),
  Article(
    id: '2',
    title: 'Morning Coffee Conversation',
    cnTitle: '早间咖啡馆：实用点单与日常寒暄',
    category: '日常实用口语',
    level: '初级 / 必备',
    durationStr: '00:22',
    totalSeconds: 22,
    subtitles: [
      SubtitleLine(
        startSec: 0,
        endSec: 7,
        en: 'Good morning! Could I get a large iced latte, please?',
        cn: '早上好！请给我来一杯大杯冰拿铁好吗？',
      ),
      SubtitleLine(
        startSec: 7,
        endSec: 15,
        en: 'Sure! Would you like regular milk or oat milk today?',
        cn: '当然可以！今天您想要普通牛奶还是燕麦奶？',
      ),
      SubtitleLine(
        startSec: 15,
        endSec: 22,
        en: 'Oat milk sounds great. Thank you so much!',
        cn: '燕麦奶听起来很棒。非常感谢！',
      ),
    ],
  ),
  Article(
    id: '3',
    title: 'Overcoming Procrastination',
    cnTitle: '告别拖延症：如何立刻采取行动',
    category: 'TED 精选演讲',
    level: '六级 / 雅思',
    durationStr: '00:24',
    totalSeconds: 24,
    subtitles: [
      SubtitleLine(
        startSec: 0,
        endSec: 8,
        en: 'Procrastination is the thief of time and productivity.',
        cn: '拖延是窃取时间与生产力的真正小偷。',
      ),
      SubtitleLine(
        startSec: 8,
        endSec: 16,
        en: 'Break your complex goals into tiny actionable steps.',
        cn: '把你复杂的目标拆解成微小的、可立即执行的步骤。',
      ),
      SubtitleLine(
        startSec: 16,
        endSec: 24,
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

// ==================== 全局语音服务与本地生词本管理 ====================
class SpeechService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage("en-US");
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.48);
      _initialized = true;
    } catch (_) {}
  }

  static Future<void> speak(String text, {double rate = 1.0}) async {
    await init();
    try {
      await _tts.stop();
      // FlutterTts 在 Android 上默认 0.5 左右为正常语速
      final mappedRate = (0.48 * rate).clamp(0.25, 1.0);
      await _tts.setSpeechRate(mappedRate);
      await _tts.speak(text);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

// ==================== 主界面框架 ====================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTab = 0; // 0: 听力列表, 1: 生词本
  Article? _activeArticle;
  List<WordEntry> _savedWords = [
    dictionaryMap['persistence']!,
    dictionaryMap['habit']!,
  ];

  @override
  void initState() {
    super.initState();
    SpeechService.init();
    _loadSavedWords();
  }

  Future<void> _loadSavedWords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('saved_words_v1');
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      setState(() {
        _savedWords = decoded.map((e) => WordEntry.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveWordsToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_savedWords.map((e) => e.toJson()).toList());
    await prefs.setString('saved_words_v1', encoded);
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

  @override
  Widget build(BuildContext context) {
    // 如果进入了播放器页，展示与预览版完全一致的全屏精听界面
    if (_activeArticle != null) {
      return PlayerView(
        article: _activeArticle!,
        savedWords: _savedWords,
        onToggleSaveWord: _toggleSaveWord,
        onBack: () {
          SpeechService.stop();
          setState(() => _activeArticle = null);
        },
      );
    }

    return Scaffold(
      body: _currentTab == 0
          ? ArticleListView(
              savedCount: _savedWords.length,
              onSelectArticle: (article) => setState(() => _activeArticle = article),
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 1. 首页课程列表（1:1 复刻预览版渐变头与卡片） ====================
class ArticleListView extends StatelessWidget {
  final int savedCount;
  final ValueChanged<Article> onSelectArticle;

  const ArticleListView({
    super.key,
    required this.savedCount,
    required this.onSelectArticle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部深蓝渐变 Header
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
            bottom: 20,
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '坚持精听 · 每天进步一点点',
                        style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '已打卡 3 天',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // 顶部统计磨砂栏
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildStatColumn('18m', '今日精听'),
                    Container(width: 1, height: 24, color: Colors.white24),
                    _buildStatColumn('$savedCount', '已收生词'),
                    Container(width: 1, height: 24, color: Colors.white24),
                    _buildStatColumn('3篇', '推荐课程'),
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '精选双语精听',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  Text(
                    '包含真人发音与点词翻译',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...mockArticles.map((article) => _buildArticleCard(article)),
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
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
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

  Widget _buildArticleCard(Article article) {
    return GestureDetector(
      onTap: () => onSelectArticle(article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9)),
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
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
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
                          article.level,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Text(
                            article.durationStr,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 2. 精听播放器视图（1:1 还原预览版 + TTS 原声朗读） ====================
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
  bool _isPlaying = false;
  double _currentTime = 0.0;
  double _playbackRate = 1.0;
  bool _isSingleLoop = false;
  LangMode _langMode = LangMode.bilingual;
  Timer? _timer;
  int _lastSpokenIndex = -1;

  @override
  void initState() {
    super.initState();
    // 进入播放器自动开始播放第一句
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _startPlay();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    SpeechService.stop();
    super.dispose();
  }

  int _getActiveLineIndex(double sec) {
    for (int i = 0; i < widget.article.subtitles.length; i++) {
      final s = widget.article.subtitles[i];
      if (sec >= s.startSec && sec < s.endSec) {
        return i;
      }
    }
    if (sec >= widget.article.totalSeconds) {
      return widget.article.subtitles.length - 1;
    }
    return 0;
  }

  void _speakLineAt(int index) {
    if (index < 0 || index >= widget.article.subtitles.length) return;
    _lastSpokenIndex = index;
    SpeechService.speak(widget.article.subtitles[index].en, rate: _playbackRate);
  }

  void _startPlay() {
    setState(() => _isPlaying = true);
    final idx = _getActiveLineIndex(_currentTime);
    _speakLineAt(idx);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!mounted || !_isPlaying) return;

      final step = 0.25 * _playbackRate;
      final currentIdx = _getActiveLineIndex(_currentTime);
      final currentLine = widget.article.subtitles[currentIdx];
      double nextTime = _currentTime + step;

      // 单句循环检测
      if (_isSingleLoop && nextTime >= currentLine.endSec - 0.15) {
        setState(() => _currentTime = currentLine.startSec.toDouble());
        _speakLineAt(currentIdx);
        return;
      }

      // 整篇播放结束
      if (nextTime >= widget.article.totalSeconds) {
        _timer?.cancel();
        SpeechService.stop();
        setState(() {
          _isPlaying = false;
          _currentTime = 0.0;
          _lastSpokenIndex = -1;
        });
        return;
      }

      final nextIdx = _getActiveLineIndex(nextTime);
      if (nextIdx != _lastSpokenIndex) {
        _speakLineAt(nextIdx);
      }

      setState(() => _currentTime = nextTime);
    });
  }

  void _pausePlay() {
    _timer?.cancel();
    SpeechService.stop();
    setState(() => _isPlaying = false);
  }

  void _seekToLine(SubtitleLine line, int index) {
    setState(() => _currentTime = line.startSec.toDouble());
    if (_isPlaying) {
      _speakLineAt(index);
    } else {
      _startPlay();
    }
  }

  void _cycleSpeed() {
    const speeds = [0.8, 1.0, 1.25, 1.5, 2.0];
    final next = speeds[(speeds.indexOf(_playbackRate) + 1) % speeds.length];
    setState(() => _playbackRate = next);
    if (_isPlaying) {
      _speakLineAt(_getActiveLineIndex(_currentTime));
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

  String _formatSec(double s) {
    final sec = s.floor().clamp(0, 3599);
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final rem = (sec % 60).toString().padLeft(2, '0');
    return '$m:$rem';
  }

  // 点击单词弹出底部查词卡片并立即朗读该单词
  void _onWordTap(String rawWord) {
    final clean = rawWord.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
    if (clean.isEmpty) return;

    // 暂停文章朗读并单独朗读所点击的单词
    _pausePlay();
    SpeechService.speak(clean, rate: 0.9);

    final entry = dictionaryMap[clean] ??
        WordEntry(
          word: clean,
          phonetic: '/$clean/',
          pos: 'n. / v.',
          meaning: '点击发音已激活（更多词汇释义将在后续版本接入在线词典）',
        );

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
                                  onPressed: () => SpeechService.speak(entry.word, rate: 0.9),
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
    final activeIdx = _getActiveLineIndex(_currentTime);

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
                  onPressed: widget.onBack,
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
                        widget.article.category,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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

          // 琥珀色操作提示栏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBEB),
              border: Border(bottom: BorderSide(color: Color(0xFFFEF3C7))),
            ),
            child: const Row(
              children: [
                Icon(Icons.volume_up_rounded, size: 15, color: Color(0xFFD97706)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '点击任意英文单词即可听发音与查词；点击行首图标可单句复读',
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
              itemCount: widget.article.subtitles.length,
              itemBuilder: (context, index) {
                final line = widget.article.subtitles[index];
                final isActive = index == activeIdx;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isActive ? const Color(0xFFBFDBFE) : Colors.transparent,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _seekToLine(line, index),
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(top: 2, right: 10),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: isActive ? Colors.white : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_langMode != LangMode.cn)
                              _buildClickableSentence(line.en, isActive),
                            if (_langMode != LangMode.en) ...[
                              const SizedBox(height: 6),
                              Text(
                                line.cn,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: isActive ? const Color(0xFF334155) : const Color(0xFF64748B),
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

          // 底部专业音频控制面板（与预览版一致）
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
                  Row(
                    children: [
                      Text(
                        _formatSec(_currentTime),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: _currentTime.clamp(0.0, widget.article.totalSeconds.toDouble()),
                            max: widget.article.totalSeconds.toDouble(),
                            activeColor: const Color(0xFF2563EB),
                            inactiveColor: const Color(0xFFE2E8F0),
                            onChanged: (val) {
                              setState(() => _currentTime = val);
                              if (_isPlaying) {
                                _speakLineAt(_getActiveLineIndex(val));
                              }
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatSec(widget.article.totalSeconds.toDouble()),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 倍速按钮
                      GestureDetector(
                        onTap: _cycleSpeed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_playbackRate}x',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                        ),
                      ),
                      // 上一句
                      IconButton(
                        onPressed: () {
                          final prevIdx = (activeIdx - 1).clamp(0, widget.article.subtitles.length - 1);
                          _seekToLine(widget.article.subtitles[prevIdx], prevIdx);
                        },
                        icon: const Icon(Icons.skip_previous_rounded, size: 28, color: Color(0xFF475569)),
                      ),
                      // 播放/暂停主按钮
                      GestureDetector(
                        onTap: () => _isPlaying ? _pausePlay() : _startPlay(),
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
                          final nextIdx = (activeIdx + 1).clamp(0, widget.article.subtitles.length - 1);
                          _seekToLine(widget.article.subtitles[nextIdx], nextIdx);
                        },
                        icon: const Icon(Icons.skip_next_rounded, size: 28, color: Color(0xFF475569)),
                      ),
                      // 单句循环
                      GestureDetector(
                        onTap: () {
                          setState(() => _isSingleLoop = !_isSingleLoop);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isSingleLoop ? '已开启单句循环精听' : '已关闭单句循环'),
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

  Widget _buildClickableSentence(String sentence, bool isActive) {
    final words = sentence.split(' ');
    return RichText(
      text: TextSpan(
        children: words.map((word) {
          return TextSpan(
            text: '$word ',
            style: TextStyle(
              fontSize: 16.5,
              height: 1.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
            ),
            recognizer: TapGestureRecognizer()..onTap = () => _onWordTap(word),
          );
        }).toList(),
      ),
    );
  }
}

// ==================== 3. 生词本视图（支持点击单词发音） ====================
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
                                      onTap: () => SpeechService.speak(item.word, rate: 0.9),
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
