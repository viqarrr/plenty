import 'dart:io';
import 'dart:convert';

void main() async {
  final workspaceDir = Directory.current.path;
  final outputDocxPath = '$workspaceDir\\Privacy_and_Confidentiality_Policy_Guideline_PLENTY.docx';
  
  final tempDir = Directory.systemTemp.createTempSync('plenty_guideline_');
  final wordDir = Directory('${tempDir.path}\\word')..createSync(recursive: true);
  final relsDir = Directory('${tempDir.path}\\_rels')..createSync(recursive: true);
  final wordRelsDir = Directory('${wordDir.path}\\_rels')..createSync(recursive: true);
  final docPropsDir = Directory('${tempDir.path}\\docProps')..createSync(recursive: true);

  // 1. [Content_Types].xml
  File('${tempDir.path}\\[Content_Types].xml').writeAsStringSync('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>
  <Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''');

  // 2. _rels/.rels
  File('${relsDir.path}\\.rels').writeAsStringSync('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''');

  // 3. word/_rels/document.xml.rels
  File('${wordRelsDir.path}\\document.xml.rels').writeAsStringSync('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/>
  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>
</Relationships>''');

  // 4. docProps/core.xml
  File('${docPropsDir.path}\\core.xml').writeAsStringSync('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Privacy &amp; Confidentiality Policy Guideline</dc:title>
  <dc:subject>PLENTY Houseplant Care Companion &amp; Gamified Tracking</dc:subject>
  <dc:creator>Plenty Architecture Board</dc:creator>
  <cp:keywords>Privacy, Confidentiality, Policy Guideline, Plenty</cp:keywords>
  <dc:description>Privacy and Confidentiality Policy Guideline for PLENTY Application</dc:description>
  <cp:lastModifiedBy>Plenty Architecture Board</cp:lastModifiedBy>
  <cp:revision>27.0</cp:revision>
  <dcterms:created xsi:type="dcterms:W3CDTF">2026-08-31T00:00:00Z</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">2026-08-31T00:00:00Z</dcterms:modified>
</cp:coreProperties>''');

  // 5. docProps/app.xml
  File('${docPropsDir.path}\\app.xml').writeAsStringSync('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Microsoft Office Word</Application>
  <DocSecurity>0</DocSecurity>
  <Lines>350</Lines>
  <Paragraphs>220</Paragraphs>
  <Company>PLENTY App Team</Company>
</Properties>''');

  // 6. word/settings.xml
  File('${wordDir.path}\\settings.xml').writeAsStringSync('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:defaultTabStop w:val="720"/>
  <w:characterSpacingControl w:val="doNotCompress"/>
</w:settings>''');

  // 7. word/styles.xml
  File('${wordDir.path}\\styles.xml').writeAsStringSync('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
        <w:sz w:val="21"/>
        <w:szCs w:val="21"/>
        <w:color w:val="1E293B"/>
        <w:lang w:val="en-US"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:after="100" w:line="260" w:lineRule="auto"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>

  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
  </w:style>

  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:keepNext/>
      <w:spacing w:before="240" w:after="90"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:color w:val="357A38"/>
      <w:sz w:val="28"/>
      <w:szCs w:val="28"/>
    </w:rPr>
  </w:style>

  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:keepNext/>
      <w:spacing w:before="180" w:after="70"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:color w:val="357A38"/>
      <w:sz w:val="24"/>
      <w:szCs w:val="24"/>
    </w:rPr>
  </w:style>
</w:styles>''');

  // 8. word/header1.xml (Left: Logo in green, Right: Privacy & Confidentiality Policy Guideline)
  File('${wordDir.path}\\header1.xml').writeAsStringSync('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:tbl>
    <w:tblPr>
      <w:tblW w:w="9200" w:type="dxa"/>
      <w:tblBorders>
        <w:top w:val="none"/>
        <w:left w:val="none"/>
        <w:bottom w:val="none"/>
        <w:right w:val="none"/>
        <w:insideH w:val="none"/>
        <w:insideV w:val="none"/>
      </w:tblBorders>
      <w:tblCellMar>
        <w:top w:w="0" w:type="dxa"/>
        <w:left w:w="0" w:type="dxa"/>
        <w:bottom w:w="60" w:type="dxa"/>
        <w:right w:w="0" w:type="dxa"/>
      </w:tblCellMar>
    </w:tblPr>
    <w:tr>
      <w:tc>
        <w:tcPr>
          <w:tcW w:w="4000" w:type="dxa"/>
          <w:vAlign w:val="center"/>
        </w:tcPr>
        <w:p>
          <w:pPr><w:spacing w:before="0" w:after="0"/></w:pPr>
          <w:r>
            <w:rPr>
              <w:b/>
              <w:color w:val="357A38"/>
              <w:sz w:val="28"/>
              <w:szCs w:val="28"/>
            </w:rPr>
            <w:t>PLENTY</w:t>
          </w:r>
        </w:p>
        <w:p>
          <w:pPr><w:spacing w:before="0" w:after="0"/></w:pPr>
          <w:r>
            <w:rPr>
              <w:b/>
              <w:color w:val="2D6A4F"/>
              <w:sz w:val="18"/>
              <w:szCs w:val="18"/>
            </w:rPr>
            <w:t>CARE COMPANION</w:t>
          </w:r>
        </w:p>
      </w:tc>
      <w:tc>
        <w:tcPr>
          <w:tcW w:w="5200" w:type="dxa"/>
          <w:vAlign w:val="center"/>
        </w:tcPr>
        <w:p>
          <w:pPr><w:jc w:val="left"/><w:spacing w:before="0" w:after="0"/></w:pPr>
          <w:r>
            <w:rPr>
              <w:b/>
              <w:color w:val="357A38"/>
              <w:sz w:val="32"/>
              <w:szCs w:val="32"/>
            </w:rPr>
            <w:t>Privacy &amp; Confidentiality</w:t>
          </w:r>
        </w:p>
        <w:p>
          <w:pPr><w:jc w:val="left"/><w:spacing w:before="0" w:after="0"/></w:pPr>
          <w:r>
            <w:rPr>
              <w:color w:val="334155"/>
              <w:sz w:val="22"/>
              <w:szCs w:val="22"/>
            </w:rPr>
            <w:t>Policy Guideline</w:t>
          </w:r>
        </w:p>
      </w:tc>
    </w:tr>
  </w:tbl>
  <w:p><w:pPr><w:spacing w:before="0" w:after="140"/></w:pPr></w:p>
</w:hdr>''');

  // 9. word/footer1.xml (Left: Filename/Code, Center: Version/Page, Right: Approved info)
  File('${wordDir.path}\\footer1.xml').writeAsStringSync('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:tbl>
    <w:tblPr>
      <w:tblW w:w="9200" w:type="dxa"/>
      <w:tblBorders>
        <w:top w:val="none"/>
        <w:left w:val="none"/>
        <w:bottom w:val="none"/>
        <w:right w:val="none"/>
        <w:insideH w:val="none"/>
        <w:insideV w:val="none"/>
      </w:tblBorders>
      <w:tblCellMar>
        <w:top w:w="60" w:type="dxa"/>
        <w:left w:w="0" w:type="dxa"/>
        <w:bottom w:w="0" w:type="dxa"/>
        <w:right w:w="0" w:type="dxa"/>
      </w:tblCellMar>
    </w:tblPr>
    <w:tr>
      <w:tc>
        <w:tcPr>
          <w:tcW w:w="3800" w:type="dxa"/>
          <w:vAlign w:val="top"/>
        </w:tcPr>
        <w:p>
          <w:pPr><w:spacing w:before="0" w:after="20"/></w:pPr>
          <w:r>
            <w:rPr><w:sz w:val="17"/><w:color w:val="1E293B"/></w:rPr>
            <w:t>Privacy and Confidentiality Policy Guideline.docx</w:t>
          </w:r>
        </w:p>
        <w:p>
          <w:pPr><w:spacing w:before="0" w:after="0"/></w:pPr>
          <w:r>
            <w:rPr><w:sz w:val="17"/><w:color w:val="1E293B"/></w:rPr>
            <w:t>POLICY-PLENTY-4-2026</w:t>
          </w:r>
        </w:p>
      </w:tc>
      <w:tc>
        <w:tcPr>
          <w:tcW w:w="2400" w:type="dxa"/>
          <w:vAlign w:val="top"/>
        </w:tcPr>
        <w:p>
          <w:pPr><w:jc w:val="center"/><w:spacing w:before="0" w:after="20"/></w:pPr>
          <w:r>
            <w:rPr><w:sz w:val="17"/><w:color w:val="1E293B"/></w:rPr>
            <w:t>Version: 27.0</w:t>
          </w:r>
        </w:p>
        <w:p>
          <w:pPr><w:jc w:val="center"/><w:spacing w:before="0" w:after="0"/></w:pPr>
          <w:r>
            <w:rPr><w:sz w:val="17"/><w:color w:val="1E293B"/></w:rPr>
            <w:t>Page </w:t>
          </w:r>
          <w:fldSimple w:instr="PAGE"/>
          <w:r>
            <w:rPr><w:sz w:val="17"/><w:color w:val="1E293B"/></w:rPr>
            <w:t> of </w:t>
          </w:r>
          <w:fldSimple w:instr="NUMPAGES"/>
        </w:p>
      </w:tc>
      <w:tc>
        <w:tcPr>
          <w:tcW w:w="3000" w:type="dxa"/>
          <w:vAlign w:val="top"/>
        </w:tcPr>
        <w:p>
          <w:pPr><w:jc w:val="right"/><w:spacing w:before="0" w:after="20"/></w:pPr>
          <w:r>
            <w:rPr><w:sz w:val="17"/><w:color w:val="1E293B"/></w:rPr>
            <w:t>Approved By: Plenty Architecture Board</w:t>
          </w:r>
        </w:p>
        <w:p>
          <w:pPr><w:jc w:val="right"/><w:spacing w:before="0" w:after="0"/></w:pPr>
          <w:r>
            <w:rPr><w:sz w:val="17"/><w:color w:val="1E293B"/></w:rPr>
            <w:t>Approved: 31/08/2026</w:t>
          </w:r>
        </w:p>
      </w:tc>
    </w:tr>
  </w:tbl>
</w:ftr>''');

  // Helper builder for Document XML
  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
  buffer.writeln('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">');
  buffer.writeln('<w:body>');

  String escape(String text) {
    return const HtmlEscape(HtmlEscapeMode.element).convert(text);
  }

  void heading1(String title) {
    buffer.writeln('''<w:p>
  <w:pPr>
    <w:pStyle w:val="Heading1"/>
    <w:spacing w:before="260" w:after="90"/>
  </w:pPr>
  <w:r>
    <w:rPr><w:b/><w:color w:val="357A38"/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr>
    <w:t>${escape(title)}</w:t>
  </w:r>
</w:p>''');
  }

  void heading2(String title) {
    buffer.writeln('''<w:p>
  <w:pPr>
    <w:pStyle w:val="Heading2"/>
    <w:spacing w:before="180" w:after="70"/>
  </w:pPr>
  <w:r>
    <w:rPr><w:b/><w:color w:val="357A38"/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr>
    <w:t>${escape(title)}</w:t>
  </w:r>
</w:p>''');
  }

  void paragraph(String text, {String? boldPrefix}) {
    buffer.writeln('<w:p>');
    buffer.writeln('  <w:pPr><w:spacing w:after="110" w:line="260" w:lineRule="auto"/></w:pPr>');
    if (boldPrefix != null && boldPrefix.isNotEmpty) {
      buffer.writeln('  <w:r><w:rPr><w:b/><w:color w:val="1E293B"/></w:rPr><w:t>${escape(boldPrefix)} </w:t></w:r>');
    }
    buffer.writeln('  <w:r><w:rPr><w:color w:val="1E293B"/><w:sz w:val="21"/><w:szCs w:val="21"/></w:rPr><w:t>${escape(text)}</w:t></w:r>');
    buffer.writeln('</w:p>');
  }

  void bullet(String text, {String? boldPrefix, int level = 1}) {
    final leftIndent = level == 2 ? 720 : 360;
    final bulletChar = level == 2 ? '– ' : '• ';
    buffer.writeln('<w:p>');
    buffer.writeln('  <w:pPr><w:ind w:left="$leftIndent" w:hanging="240"/><w:spacing w:after="70" w:line="250" w:lineRule="auto"/></w:pPr>');
    buffer.writeln('  <w:r><w:rPr><w:color w:val="1E293B"/></w:rPr><w:t>$bulletChar</w:t></w:r>');
    if (boldPrefix != null && boldPrefix.isNotEmpty) {
      buffer.writeln('  <w:r><w:rPr><w:b/><w:color w:val="1E293B"/></w:rPr><w:t>${escape(boldPrefix)} </w:t></w:r>');
    }
    buffer.writeln('  <w:r><w:rPr><w:color w:val="1E293B"/><w:sz w:val="21"/><w:szCs w:val="21"/></w:rPr><w:t>${escape(text)}</w:t></w:r>');
    buffer.writeln('</w:p>');
  }

  // --- CONTENT MIRRORING PDF STRUCTURE ---

  heading1('Summary');
  paragraph('PLENTY (Houseplant Care Companion & Gamified Tracking) is committed to safeguarding the confidentiality of any personal, health, botanical, or sensitive information of individuals by:');
  bullet('Maintaining procedures that protect privacy during the collection, use, retention, and disclosure of personal information; and,');
  bullet('Complying with the Indonesian Personal Data Protection Act (UU No. 27 Tahun 2022 tentang Pelindungan Data Pribadi / UU PDP), the Australian Privacy Principles (APPs), and the General Data Protection Regulation (GDPR).');
  bullet('Complying with legislation and standards that are specific to mobile applications, local data persistence, working arrangements, and jurisdictions.');

  heading1('Who should read this document?');
  paragraph('This Policy applies to the Personal Information of all PLENTY users, members, volunteers, employees, clients, authorized representatives, partners, plant care contributors, and Online Users collected or held by PLENTY.');

  heading1('The meaning of terms and words used in this document');
  paragraph('means information or an opinion (including information or an opinion forming part of a database), whether true or not, and whether recorded in a material form or not, about an individual whose identity is reasonably identifiable from the information or opinion. Personal Information includes Account Information, Botanical Care Logs, and Sensitive Device Permissions.', boldPrefix: 'Personal Information');
  paragraph('Common examples include an individual\'s:');
  bullet('name / display name');
  bullet('username');
  bullet('email address');
  bullet('encrypted password credentials (salted bcrypt hash)');
  bullet('profile avatar image and biography');
  bullet('household safety preferences (pet-friendly and child-safe tags)');
  bullet('gardening experience levels and daily available care duration');
  bullet('commentary, tips, or opinion shared on community forums.');

  paragraph('is information or recorded observations about:', boldPrefix: 'Plant & Care Information');
  bullet('the botanical species, common nickname, and scientific classification of a houseplant');
  bullet('custom room placement (e.g. Living Room, Balcony), pot dimensions, and sunlight conditions');
  bullet('measurements of plant height in centimeters (cm) and foliage leaf count over time');
  bullet('historical logs of watering, foliage misting/cleaning, fertilizing, and pruning actions');
  bullet('photographic time-series documenting plant growth milestones and time capsule entries.');

  paragraph('means data generated through user interaction to cultivate consistent care habits:', boldPrefix: 'Gamification Data');
  bullet('Experience Points (XP) earned from completing scheduled tasks (+10 XP watering, +10 XP cleaning, +15 XP measuring)');
  bullet('global user level and individual plant gamified levels');
  bullet('daily streak metrics (active streak and all-time longest streak records)');
  bullet('unlocked Master Badges and progress milestones (First Plant, Water Streak, Time Capsule, Plant Collector, Doctor Green, Sun Master).');

  paragraph('means device authorizations required for interactive features:', boldPrefix: 'Sensitive Information & Permissions');
  bullet('camera hardware access for capturing plant photos, height measurement logs, time capsules, and avatar pictures');
  bullet('photo gallery and media storage access for selecting existing plant images');
  bullet('local device notifications for timely watering and plant care reminders.');

  paragraph('refers to anyone who accesses the PLENTY application or the repository: https://github.com/viqarrr/plenty', boldPrefix: 'Online Users');
  paragraph('means the official PLENTY open repository and web presence: https://github.com/viqarrr/plenty.', boldPrefix: 'The website');

  paragraph('is a local relational database engine engineered specifically for PLENTY as a client-side information reporting and tracking system. It allows us to securely store important care routines locally on the device, operate seamlessly offline, and ensure privacy by design without unsolicited server tracking.', boldPrefix: 'PLENTY SQLite Engine (plenty.db)');

  heading1('What is our aim?');
  paragraph('We develop and maintain PLENTY to turn houseplant care into a joyful, consistent habit. In providing these services, we comply with the UU PDP, GDPR, Privacy Act, and Australian Privacy Principles (APPs). We adhere strictly to a Local-First data architecture where user information remains under user control.');

  heading1('Policy Guideline');
  paragraph('This Privacy and Confidentiality Policy Guideline sets out how we comply with our legal and architectural obligations. We are bound by data protection principles that regulate how organizations may collect, use, disclose, and store personal and botanical information, and how individuals may access and correct personal information held by them.');

  heading1('Objectives');
  bullet('To ensure information is received, recorded, accessed, and stored appropriately to maintain confidentiality.');
  bullet('To remain compliant with:');
  bullet('Undang-Undang No. 27 Tahun 2022 tentang Pelindungan Data Pribadi (UU PDP)', level: 2);
  bullet('the Privacy Act 1988 (Cth) and Australian Privacy Principles (APPs)', level: 2);
  bullet('General Data Protection Regulation (GDPR) standards', level: 2);
  bullet('Google Play Developer Policies and Apple App Store Review Guidelines', level: 2);
  bullet('all PLENTY SQLite engine schema rules, relational integrity, and cascade deletions', level: 2);
  bullet('any other PLENTY policies and procedures related to the collection, storage, or use of Personal and Botanical Information.', level: 2);
  bullet('To ensure that all individuals are aware of their privacy and confidentiality rights and know how to access or amend private information held about them.');
  bullet('To ensure that any Personal information collected is directly related to PLENTY companion functions or activities.');

  heading1('Guiding Principles');
  bullet('We acknowledge that individuals and communities have a right to privacy, dignity, and confidentiality. This right will be always upheld through practices of sharing and discretely providing information, on a need-to-know basis and with consent, as required.');
  bullet('We will be guided by data minimization and Local-First storage principles at all times.');
  bullet('Where we operate databases or information systems (e.g. plenty.db SQLite database or SharedPreferences), the relevant policies and procedures must be followed to ensure the appropriate use and protection of Personal and Sensitive Information within these systems.');
  bullet('We aim to create an ecosystem that is respectful, ethical, and professional when managing confidential or private information held about an individual.');

  heading1('Policy Commitments');
  bullet('We will make available to individuals information about privacy rights and how to access or amend their Personal Information.');
  bullet('We will ensure there is a central contact point for any individual requiring information or wanting to contact PLENTY about a privacy matter.');
  bullet('We will take steps to ensure that this privacy policy is easily and freely accessible, in an appropriate format.');
  bullet('We guarantee that PLENTY will NEVER sell, rent, lease, or monetize personal information, plant photographs, or user activity logs to third parties or commercial advertisers.');

  heading1('Performance Indicators');
  bullet('Zero instances of a breach of confidentiality relating to Personal Information, Account Credentials, or Sensitive Plant Media.');
  bullet('100% password protection using salted bcrypt cryptographic hashing prior to storage.');
  bullet('Data Privacy Breach Response Plan activated for all instances of possible or actual data privacy breaches.');

  heading1('Collection of Personal and Sensitive Information');
  paragraph('This policy applies to any personal or sensitive information PLENTY collects from app users, community members, contributors, and online users.');
  paragraph('Our services can be accessed locally and using custom nicknames/pseudonyms if requested. If this is possible and lawful, we will take all reasonable steps to comply with your request. However, certain online features (such as community forum participation or cloud botanical lookups) may require minimum identification details.');
  paragraph('The PLENTY website and app may from time to time contain links to third-party botanical databases or external websites, which may have a different privacy policy.');

  heading1('How we collect information');
  paragraph('Where possible, we collect your Personal Information and Plant Care Information directly from you. We collect information through various means. We will not collect information unless it is reasonably necessary for the functions or activities of PLENTY.');
  paragraph('Primary points of collection include:');
  bullet('Account setup: display name, username, email, and password.');
  bullet('Onboarding wizard: plant care experience level, time availability, and pet/child safety constraints.');
  bullet('Virtual garden entries: plant adoption date, species name, placement location, pot specs, and initial height.');
  bullet('Daily care logs: watering checklists, foliage cleaning, height measurements in cm, and observation notes.');
  bullet('Community contributions: posts, tips, photos, and kudos.');
  paragraph('If you do not want to disclose information that we have requested, you can choose to skip optional fields or use offline guest mode.');

  heading1('Botanical Catalog and Third-Party API Integration');
  paragraph('To provide botanical data and watering recommendations, PLENTY interfaces with external catalog services (Perenual Botanical API):');
  bullet('Quota-Safe Debouncing: all search queries implement a 400ms Debouncer to conserve network traffic and prevent unnecessary requests.');
  bullet('Local Cache-First Strategy: botanical species records fetched from external APIs are cached in the local SQLite engine (plenty.db) on initial fetch.');
  bullet('Zero PII Transmission: queries dispatched to external botanical APIs contain only plant species names. No personal identity, user email, device ID, user photo, or garden record is ever transmitted.');

  heading1('Use and disclosure of Personal Information');
  paragraph('We only use Personal Information for the purposes for which it is given to us, or for purposes related to one of our functions or activities. Personal Information will NOT be disclosed for marketing purposes.');
  paragraph('Except for technical operational providers (e.g. Google Fonts for typography rendering) operating under strict non-disclosure obligations, we will not disclose an individual\'s Personal Information to a third party unless one of the following applies:');
  bullet('the individual has consented');
  bullet('the individual would reasonably expect us to use that information for another purpose related to the purpose for which it was collected');
  bullet('it is otherwise required or authorised by law');
  bullet('it will prevent or lessen a serious threat to somebody\'s life, health or safety, or to the public health or safety');
  bullet('it is reasonably necessary for the enforcement of a law conducted by an enforcement body, in which case a written record will be maintained.');

  heading1('Collection and retention of sensitive information');
  paragraph('We collect and retain personal and device information if it is reasonably necessary for, or directly related to, our companion services and gamified tracking. We only request and access device permissions (Camera, Gallery, Notifications) if the individual explicitly consents through the operating system dialog.');

  heading1('Security of Personal Information and Sensitive Information');
  paragraph('We take comprehensive technical and architectural steps to protect the Personal and Sensitive Information we hold against misuse, interference, loss, unauthorised access, modification, and disclosure.');
  paragraph('These steps include:');
  bullet('Local-First relational database architecture (plenty.db) keeping data locally isolated on the user\'s device.');
  bullet('Password encryption using the industry-proven bcrypt one-way cryptographic hashing algorithm.');
  bullet('Database foreign key constraints (PRAGMA foreign_keys = ON) and cascade deletions ensuring no orphaned private records.');
  bullet('HTTPS/TLS 1.3 encryption for all external API network requests.');
  paragraph('When Personal or Sensitive Information is no longer required (such as when an account is deleted or the app is uninstalled), all local database tables, cache files, and preferences are destroyed in a secure manner.');

  heading1('Access to and correction of Personal Information');
  paragraph('If an individual requests access to the Personal Information we hold about them, or seeks to change or delete that Personal Information, we will give the individual access, unless:');
  bullet('the request does not relate to the Personal Information of the person making the request');
  bullet('the request would have an unreasonable impact on the privacy of other individuals');
  bullet('providing access would pose a serious threat to the life, health or safety of a person or to public safety');
  bullet('the request is frivolous and vexatious');
  bullet('access would be unlawful or denied by law.');
  paragraph('Requests for formal data extracts or manual corrections should be made to the Privacy Officer in writing with proof of identity. We will take all reasonable steps to provide access within 30 days without charging administrative fees.');
  paragraph('Users can also update their profile, modify plant records, or delete their entire account and local database directly within the PLENTY app settings at any time.');

  heading1('PLENTY Privacy Data Breach Response Plan');
  paragraph('If we become aware of a privacy breach affecting someone covered by this policy, we will follow the PLENTY Privacy Data Breach Response Plan. Where the breach is likely to cause serious harm, we will notify the affected individual and relevant data protection authorities (such as the Indonesian Ministry of Communication and Informatics / Kominfo or the Office of the Australian Information Commissioner) within 72 hours. When we notify an individual about a data breach, we will explain what they can do to protect themselves and what steps we\'ve taken to fix the issue.');

  heading1('Complaints Procedure');
  paragraph('If you have a complaint about our privacy practices or our handling of your Personal Information or Plant Data, you may notify our Privacy Officer.');
  paragraph('We aim to resolve complaints within 30 days. If the matter is more complex, it may take longer, but we will keep you updated throughout the process. All complaints and outcomes will be recorded.');
  paragraph('If an anonymous complaint is received, we will note the issues raised and, where appropriate, investigate and resolve them appropriately.');

  heading1('Changes to this Privacy Policy');
  paragraph('PLENTY will review, amend and/or update this policy from time to time as appropriate.');

  heading1('How to contact us:');
  paragraph('Individuals can obtain further information in relation to this Privacy Policy, or provide any comments, by contacting:');
  paragraph('The Privacy Officer');
  paragraph('PLENTY Plant Care Development Team');
  paragraph('Email: privacyofficer@plentyapp.com');
  paragraph('Support: support@plentyapp.com');
  paragraph('Website & Repository: https://github.com/viqarrr/plenty');

  // Section Properties with Header and Footer links
  buffer.writeln('''<w:sectPr>
  <w:headerReference w:type="default" r:id="rId3"/>
  <w:footerReference w:type="default" r:id="rId4"/>
  <w:pgSz w:w="11906" w:h="16838"/>
  <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
</w:sectPr>
</w:body>
</w:document>''');

  File('${wordDir.path}\\document.xml').writeAsStringSync(buffer.toString());

  // Use PowerShell to zip the folder into .docx
  final zipProcess = await Process.run('powershell', [
    '-Command',
    '''
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if (Test-Path "$outputDocxPath") { Remove-Item -Force "$outputDocxPath" }
    [System.IO.Compression.ZipFile]::CreateFromDirectory("${tempDir.path}", "$outputDocxPath")
    '''
  ]);

  if (zipProcess.exitCode != 0) {
    print('Zip failed: ${zipProcess.stderr}');
    exit(1);
  }

  tempDir.deleteSync(recursive: true);
  print('SUCCESS: Created $outputDocxPath');
  final length = File(outputDocxPath).lengthSync();
  print('Size: $length bytes');
}
