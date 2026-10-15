class Connector {
  const Connector(
    this.id,
    this.name,
    this.description,
    this.category, {
    this.beta = false,
    this.color = 0xFF171717,
    this.website = '',
    this.documentation = '',
  });
  final String id;
  final String name;
  final String description;
  final String category;
  final bool beta;
  final int color;
  final String website;
  final String documentation;

  String get asset => 'assets/connectors/$id.svg';
  static const all = [
    Connector(
      'computer',
      'Computer Use',
      'Let Manus control your computer',
      'Productivity',
    ),
    Connector(
      'video',
      'Video Editor',
      'Create and refine videos in an editable timeline.',
      'Productivity',
    ),
    Connector(
      'skill',
      'Skill Recorder',
      'Record a workflow and turn it into a reusable skill',
      'Productivity',
    ),
    Connector(
      'shopify',
      'Shopify',
      'Streamline operations, unlock insights, and grow your Shopify store',
      'Finance',
      beta: true,
      color: 0xFF95BF47,
      website: 'https://www.shopify.com',
      documentation: 'https://shopify.dev/docs',
    ),
    Connector(
      'outlookcalendar',
      'Outlook Calendar',
      'Schedule, view, and manage your Outlook events just with a prompt',
      'Productivity',
      website: 'https://outlook.live.com/calendar',
      documentation: 'https://learn.microsoft.com/graph/api/resources/calendar',
    ),
    Connector(
      'instagram',
      'Instagram Creator Marketplace',
      'Discover creators that fit your brand’s reach, topics, and style',
      'Productivity',
      beta: true,
      website: 'https://www.instagram.com',
      documentation: 'https://developers.facebook.com/docs/instagram-platform/',
    ),
    Connector(
      'github',
      'GitHub',
      'Explore repositories, review issues, and work with your code',
      'Productivity',
      website: 'https://github.com',
      documentation: 'https://docs.github.com/rest',
    ),
    Connector(
      'meta',
      'Meta Ads Manager',
      'Manage campaigns and understand advertising performance',
      'Finance',
      beta: true,
      color: 0xFF0081FB,
      website: 'https://adsmanager.facebook.com',
      documentation: 'https://developers.facebook.com/docs/marketing-apis/',
    ),
    Connector(
      'googleworkspace',
      'Google Workspace',
      'Work with your Google Drive files, Docs, and Sheets',
      'Productivity',
      website: 'https://workspace.google.com',
      documentation: 'https://developers.google.com/workspace',
    ),
    Connector(
      'outlookmail',
      'Outlook Mail',
      'Search, read, and organize your Outlook messages',
      'Productivity',
      website: 'https://outlook.live.com',
      documentation: 'https://learn.microsoft.com/graph/api/resources/message',
    ),
    Connector(
      'instagram',
      'Instagram',
      'Understand your Instagram content and audience',
      'Productivity',
      beta: true,
      website: 'https://www.instagram.com',
      documentation: 'https://developers.facebook.com/docs/instagram-platform/',
    ),
    Connector(
      'googlecalendar',
      'Google Calendar',
      'Find events and plan your schedule',
      'Productivity',
      color: 0xFF4285F4,
      website: 'https://calendar.google.com',
      documentation: 'https://developers.google.com/calendar',
    ),
    Connector(
      'notion',
      'Notion',
      'Find pages and organize your workspace',
      'Productivity',
      website: 'https://www.notion.so',
      documentation: 'https://developers.notion.com',
    ),
    Connector(
      'gmail',
      'Gmail',
      'Search and read your email',
      'Productivity',
      color: 0xFFEA4335,
      website: 'https://mail.google.com',
      documentation: 'https://developers.google.com/gmail',
    ),
  ];

  static Connector find(String id) =>
      all.firstWhere((item) => item.id == id, orElse: () => all.first);
}
