import fs from 'fs';
const path = 'lib/screens/chat_screen.dart';
const lines = fs.readFileSync(path, 'utf8').split(/\r?\n/);
let start = -1;
let end = -1;
for (let i = 0; i < lines.length; i++) {
  if (lines[i].startsWith('  Future<List<MessageDTO>> _searchMessages(String keyword) async {')) {
    start = i;
  }
  if (start !== -1 && lines[i].startsWith('  Future<void> _showForwardTargets(')) {
    end = i;
    break;
  }
}
if (start < 0 || end < 0) throw new Error(`markers not found: ${start} ${end}`);
const replacement = `  Future<void> _openSearchPage() async {
    final int? tid = _targetId;
    final int? tp = _type;
    if (tid == null || tp == null) {
      return;
    }
    final ChatMessageSearchPop? pop =
        await Navigator.of(context).push<ChatMessageSearchPop>(
      MaterialPageRoute<ChatMessageSearchPop>(
        builder: (_) => ChatMessageSearchScreen(
          targetId: tid,
          type: tp,
          selectedMessageIds: _selectedMessageIds,
        ),
      ),
    );
    if (!mounted || pop == null) {
      return;
    }
    if (pop.scrollToLatest) {
      _scrollToLatest();
    }
    final int? fid = pop.focusId;
    if (fid != null) {
      await _focusMessage(fid);
    }
    final MessageDTO? fwd = pop.forward;
    if (fwd != null) {
      await _showForwardTargets(fwd);
    }
  }
`;
const out = [...lines.slice(0, start), replacement, ...lines.slice(end)].join('\n') + '\n';
fs.writeFileSync(path, out, 'utf8');
console.log('removed lines', end - start, 'from', start);
