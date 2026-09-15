import 'package:flutter/material.dart';
import 'formatters.dart';

class DividendTaxSafetyCard extends StatelessWidget {
  const DividendTaxSafetyCard({
    super.key,
    required this.taxableGrossAnnualTotal,
    required this.taxFreeGrossAnnualTotal,
  });

  final double taxableGrossAnnualTotal;
  final double taxFreeGrossAnnualTotal;

  static const double comprehensiveTaxLimit = 20000000.0; // 2,000만 원

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double ratio = (taxableGrossAnnualTotal / comprehensiveTaxLimit).clamp(0.0, 1.0);
    final double percent = (taxableGrossAnnualTotal / comprehensiveTaxLimit) * 100.0;
    final double remaining = (comprehensiveTaxLimit - taxableGrossAnnualTotal).clamp(0.0, comprehensiveTaxLimit);
    final bool isExceeded = taxableGrossAnnualTotal > comprehensiveTaxLimit;

    // 상태별 컬러 및 라벨
    final Color statusColor;
    final String statusLabel;

    if (isExceeded) {
      statusColor = const Color(0xFFE11D48); // 레드
      statusLabel = '종합과세 대상';
    } else if (percent >= 85) {
      statusColor = const Color(0xFFEA580C); // 주황
      statusLabel = '한도 임박';
    } else if (percent >= 50) {
      statusColor = const Color(0xFFD97706); // 앰버
      statusLabel = '점검 권장';
    } else {
      statusColor = isDark ? const Color(0xFF34D399) : const Color(0xFF176B5B); // 그린/민트
      statusLabel = '안전';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E0D7),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 카드 헤더 (슬림 & 미니멀) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 15,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '금융소득종합과세',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF2C2A28),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4.5),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 핵심 금액: 남은 안전 한도 ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isExceeded ? '한도 초과' : '한도까지 ${formatCurrency(remaining)} 남음',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isExceeded 
                      ? const Color(0xFFE11D48) 
                      : (isDark ? Colors.white : const Color(0xFF1E1E1E)),
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '연 2,000만 원 중 ${formatCurrency(taxableGrossAnnualTotal)} (${percent.toStringAsFixed(1)}%) 사용',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          // ── 슬림 게이지 바 (6px) ──
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEDE9E2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── 바 하단 양끝 라벨 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0원',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[600] : const Color(0xFFA8A196),
                ),
              ),
              Text(
                '기준 2,000만 원',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[600] : const Color(0xFFA8A196),
                ),
              ),
            ],
          ),

          // ── 절세계좌 제외 안내 (있는 경우에만 간결한 1줄 뱃지 형태) ──
          if (taxFreeGrossAnnualTotal > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242424) : const Color(0xFFF9F7F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 13,
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF176B5B),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '연금·ISA 배당(${formatCurrency(taxFreeGrossAnnualTotal)})은 비과세로 자동 제외',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : const Color(0xFF5C5449),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
