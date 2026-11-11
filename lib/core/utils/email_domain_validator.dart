/// Validates email domains against recognized public providers, regional ISPs,
/// and institutional/business domain suffixes while rejecting typos and disposable domains.
class EmailDomainValidator {
  static const Set<String> publicEmailProviders = {
    'gmail.com',
    'googlemail.com',
    'outlook.com',
    'hotmail.com',
    'live.com',
    'msn.com',
    'yahoo.com',
    'ymail.com',
    'rocketmail.com',
    'aol.com',
    'icloud.com',
    'me.com',
    'mac.com',
    'proton.me',
    'protonmail.com',
    'pm.me',
    'tuta.com',
    'tutanota.com',
    'gmx.com',
    'gmx.net',
    'zoho.com',
    'zohomail.com',
    'mail.com',
    'yandex.com',
    'yandex.ru',
    'fastmail.com',
    'hushmail.com',
  };

  static const Set<String> regionalAndIspProviders = {
    'qq.com',
    '163.com',
    '126.com',
    'sina.com',
    'naver.com',
    'daum.net',
    'hanmail.net',
    'mail.ru',
    'list.ru',
    'bk.ru',
    'inbox.ru',
    'web.de',
    't-online.de',
    'orange.fr',
    'free.fr',
    'comcast.net',
    'verizon.net',
    'att.net',
    'btinternet.com',
    'yahoo.com.ph',
  };

  static const List<String> organizationDomainSuffixes = [
    // Education
    '.edu', '.edu.ph', '.ac.uk', '.edu.au', '.edu.my', '.edu.sg', '.edu.id',
    '.edu.vn', '.edu.in', '.edu.cn', '.edu.tw', '.ac.kr', '.ac.jp', '.edu.us',
    '.edu.ca', '.edu.mx', '.edu.br', '.ac.nz', '.ac.za', '.edu.pk', '.edu.bd',
    // Government
    '.gov', '.gov.ph', '.gov.uk', '.gov.au', '.gov.in', '.gov.sg', '.gov.my',
    '.gov.id', '.gc.ca', '.gov.ca', '.gov.cn', '.gov.hk', '.gov.tw', '.go.jp',
    '.go.kr', '.gov.br', '.gob.mx', '.gov.za', '.gov.nz',
    // Military
    '.mil', '.mil.ph', '.mil.br',
    // Organizations & Nonprofits
    '.org', '.org.ph', '.org.uk', '.org.au', '.org.nz', '.ngo',
    // Business / Custom Domains
    '.com', '.com.ph', '.co.uk', '.com.au', '.co.nz', '.co.jp', '.co.kr',
    '.co.in', '.com.sg', '.com.my', '.com.br', '.co.za', '.net', '.net.ph',
    '.biz', '.io', '.co', '.tech', '.company',
    // Other Institutional
    '.int', '.health', '.hospital', '.foundation', '.museum',
  ];

  static const Set<String> _blockedDomains = {
    'mailinator.com',
    'tempmail.com',
    'temp-mail.org',
    'guerrillamail.com',
    '10minutemail.com',
    'yopmail.com',
    'trashmail.com',
    'sharklasers.com',
    'getnada.com',
    'dispostable.com',
    'fakeinbox.com',
    'maildrop.cc',
    'throwawaymail.com',
    'gmai.com',
    'gmil.com',
    'gmaill.com',
    'gmial.com',
    'gnail.com',
    'yaho.com',
    'yahooo.com',
    'hotmal.com',
    'outlok.com',
    'example.com',
    'example.org',
    'example.net',
  };

  static const List<String> _blockedSuffixes = [
    '.con',
    '.cmo',
    '.invalid',
    '.local',
    '.localhost',
    '.test',
  ];

  static final RegExp _domainLabelRegex = RegExp(r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$');

  /// Returns null when recognized & valid, or an English error message otherwise.
  static String? validateDomain(String email) {
    final trimmed = email.trim().toLowerCase();
    final atIndex = trimmed.lastIndexOf('@');
    if (atIndex <= 0 || atIndex == trimmed.length - 1) {
      return 'Please enter a valid Email Address.';
    }

    final domain = trimmed.substring(atIndex + 1);
    if (domain.contains('*') || domain.contains('..') || domain.startsWith('.') || domain.endsWith('.')) {
      return 'Invalid email domain format.';
    }

    for (final blockedSuffix in _blockedSuffixes) {
      if (domain.endsWith(blockedSuffix)) {
        return 'Unrecognized or typo email domain ("$domain"). Please check spelling.';
      }
    }

    if (_blockedDomains.contains(domain)) {
      return 'Disposable or misspelled email domain ("$domain") is not allowed.';
    }

    final labels = domain.split('.');
    if (labels.length < 2 || labels.any((label) => !_domainLabelRegex.hasMatch(label))) {
      return 'Invalid email domain ("$domain").';
    }

    if (publicEmailProviders.contains(domain) || regionalAndIspProviders.contains(domain)) {
      return null;
    }

    // Sort longest suffix first so multi-part suffixes like .edu.ph match cleanly
    final sortedSuffixes = [...organizationDomainSuffixes]
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final suffix in sortedSuffixes) {
      if (domain.endsWith(suffix) && domain.length > suffix.length) {
        return null;
      }
    }

    return 'Email domain "$domain" is not a recognized provider or organization domain.';
  }
}
