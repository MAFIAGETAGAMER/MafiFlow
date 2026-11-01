/// Keep the newest question when applying the provider's history limit.
List<Map<String, dynamic>> recentAdvisorMessages(
    List<Map<String, dynamic>> history) =>
    history.skip(history.length > 20 ? history.length - 20 : 0)
        .map((entry) => <String, dynamic>{
          'role': entry['role'], 'content': entry['content'],
        }).toList();
