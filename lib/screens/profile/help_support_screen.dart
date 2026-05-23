import 'package:app1/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Static FAQ + contact info. No backend.
///
/// We don't have `url_launcher`, so the contact email is copy-to-clipboard
/// instead of opening the mail app. Add `url_launcher` later for the real flow.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _supportEmail = 'support@example.com';

  static const List<_Faq> _faqs = [
    _Faq(
      q: 'ฉันจะบันทึกมื้ออาหารได้อย่างไร?',
      a: 'ที่หน้าแรก ให้ค้นหาอาหารแล้วแตะไอคอน + เพื่อเพิ่มลงในบันทึกของวันนี้ '
          'คุณสามารถเปลี่ยนประเภทมื้ออาหาร (มื้อเช้า/มื้อกลางวัน/มื้อเย็น) '
          'ได้ก่อนบันทึก',
    ),
    _Faq(
      q: 'แคลอรีคำนวณอย่างไร?',
      a: 'สำหรับอาหารแต่ละชนิด เราจะค้นหาข้อมูลโภชนาการจากแคตตาล็อกของเรา '
          'หากยังไม่มีในแคช AI ของเราจะประเมินค่าในครั้งแรกที่ค้นหา '
          'แล้วเก็บผลลัพธ์ไว้ใช้ในครั้งต่อไป',
    ),
    _Faq(
      q: 'ทำไมข้อมูลร่างกายของฉันถึงกลับมาแสดงอีก?',
      a: 'แอปจะเก็บข้อมูลร่างกายไว้บนเซิร์ฟเวอร์ของเรา การแก้ไขจะสร้างรายการใหม่ '
          '— ระบบจะแสดงรายการล่าสุดเสมอ ส่วนรายการเก่าจะถูกเก็บไว้เป็นประวัติ',
    ),
    _Faq(
      q: 'ฉันจะรีเซ็ตรหัสผ่านได้อย่างไร?',
      a: 'ที่หน้าเข้าสู่ระบบ ให้แตะ "ลืมรหัสผ่าน" แล้วกรอกอีเมลของคุณ '
          'คุณจะได้รับลิงก์รีเซ็ตจาก Firebase',
    ),
    _Faq(
      q: 'ข้อมูลของฉันเป็นส่วนตัวหรือไม่?',
      a: 'บัญชีของคุณได้รับการยืนยันตัวตนโดย Firebase ข้อมูลร่างกายและมื้ออาหาร '
          'จะเชื่อมโยงกับรหัสผู้ใช้ของคุณ และมองเห็นได้เฉพาะคุณเท่านั้น',
    ),
  ];

  void _copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _supportEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('คัดลอกอีเมลไปยังคลิปบอร์ดแล้ว')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('ช่วยเหลือและสนับสนุน', style: GoogleFonts.mali()),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('คำถามที่พบบ่อย',
              style: GoogleFonts.mali(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            elevation: 0,
            child: Column(
              children: _faqs
                  .map((f) => ExpansionTile(
                        title: Text(f.q,
                            style: GoogleFonts.mali(
                                fontWeight: FontWeight.w500)),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(f.a,
                                style: GoogleFonts.mali(color: Colors.grey[800])),
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Text('ยังต้องการความช่วยเหลือ?',
              style: GoogleFonts.mali(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('อีเมลฝ่ายสนับสนุน'),
              subtitle: const Text(_supportEmail),
              trailing: const Icon(Icons.copy),
              onTap: () => _copyEmail(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});
}
