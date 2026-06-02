import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InstallationSection extends StatefulWidget {
  const InstallationSection({
    super.key,
    required this.functionName,
    required this.importPath,
    required this.usageExample,
  });

  final String functionName;
  final String importPath;
  final String usageExample;

  @override
  State<InstallationSection> createState() => _InstallationSectionState();
}

class _InstallationSectionState extends State<InstallationSection> {
  static const _green = Color(0xFF1EBF77);
  static const _cardBg = Color(0xFF1C2333);
  static const _border = Color(0xFF30363D);
  static const _codeBg = Color(0xFF0D1117);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);

  String? _copiedKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import and use ${widget.functionName}()',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _codeSnippet(
                  language: 'dart',
                  code: widget.usageExample,
                  copyKey: 'usage',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Installation',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeSnippet({
    required String language,
    required String code,
    required String copyKey,
  }) {
    final isCopied = _copiedKey == copyKey;
    return Container(
      decoration: BoxDecoration(
        color: _codeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                Text(
                  language,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    setState(() => _copiedKey = copyKey);
                    await Future.delayed(const Duration(seconds: 2));
                    if (mounted && _copiedKey == copyKey) {
                      setState(() => _copiedKey = null);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCopied ? Icons.check : Icons.copy,
                        color: isCopied ? _green : _textSecondary,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCopied ? 'Copied!' : 'Copy',
                        style: TextStyle(
                          color: isCopied ? _green : _textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              style: const TextStyle(
                color: _textPrimary,
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
