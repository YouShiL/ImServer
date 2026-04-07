import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/theme/search_ux_strings.dart';

void main() {
  test('keywordHintForUserSearch distinguishes phone vs userId', () {
    expect(SearchUxStrings.keywordHintForUserSearch('phone'), '输入手机号');
    expect(SearchUxStrings.keywordHintForUserSearch('userId'), '输入用户号');
  });

  test('shared empty and error copy for search UX', () {
    expect(SearchUxStrings.emptyNoResults, '未找到相关结果');
    expect(SearchUxStrings.emptyNoFilterMatch, '当前筛选下暂无内容');
    expect(SearchUxStrings.emptyNoFilterMatchDetail, '试试切换筛选条件');
    expect(SearchUxStrings.errorSearchFailed, '搜索失败，请稍后重试');
    expect(SearchUxStrings.errorGroupIdRequired, '请输入群号');
  });

  test('messageWhenSearchRequestFailed uses fallback when server message empty', () {
    expect(
      SearchUxStrings.messageWhenSearchRequestFailed(''),
      SearchUxStrings.errorSearchFailed,
    );
    expect(
      SearchUxStrings.messageWhenSearchRequestFailed('   '),
      SearchUxStrings.errorSearchFailed,
    );
  });

  test('messageWhenSearchRequestFailed keeps non-empty server message', () {
    expect(
      SearchUxStrings.messageWhenSearchRequestFailed('用户不存在'),
      '用户不存在',
    );
    expect(
      SearchUxStrings.messageWhenSearchRequestFailed('  无权限  '),
      '无权限',
    );
  });
}
