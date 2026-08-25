import 'package:flutter/material.dart';
import 'models.dart';
import 'yahoo_finance_service.dart';
import 'formatters.dart';

class HoldingFormSheet extends StatefulWidget {
  const HoldingFormSheet({super.key, this.initialHolding});

  final Holding? initialHolding;

  @override
  State<HoldingFormSheet> createState() => _HoldingFormSheetState();
}

class _HoldingFormSheetState extends State<HoldingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _yahooService = YahooFinanceService();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final FocusNode _searchFocusNode;
  AssetType? _type;
  AccountType? _account;
  String? _currency;
  double? _originalPrice;

  final ValueNotifier<bool> _isLoadingPrice = ValueNotifier(false);
  final ValueNotifier<List<YahooFinanceSearchResult>> _searchResults =
      ValueNotifier([]);
  String _lastSearchQuery = '';
  String? _selectedSymbol;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialHolding?.name ?? '');
    _quantityController = TextEditingController(
      text: widget.initialHolding != null
          ? formatNumber(widget.initialHolding!.quantity)
          : '',
    );
    _priceController = TextEditingController(
      text: widget.initialHolding != null
          ? formatNumber(widget.initialHolding!.price)
          : '1',
    );
    _type = widget.initialHolding?.type ?? AssetType.cash;
    _selectedSymbol = widget.initialHolding?.symbol;
    _account = widget.initialHolding?.account ?? AccountType.general;
    _currency = widget.initialHolding?.currency;
    _originalPrice = widget.initialHolding?.originalPrice;

    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _searchResults.dispose();
    _isLoadingPrice.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          _searchResults.value = [];
        }
      });
    } else {
      if (_nameController.text.trim().isNotEmpty && _selectedSymbol == null) {
        _onSearchQueryChanged(_nameController.text);
      }
    }
  }

  void _onSearchQueryChanged(String query) async {
    if (query.trim().isEmpty) {
      _searchResults.value = [];
      _lastSearchQuery = query;
      setState(() {
        _selectedSymbol = null;
        _type = AssetType.cash;
        _priceController.text = '1';
        _currency = null;
        _originalPrice = null;
      });
      return;
    }
    if (query == _lastSearchQuery) return;
    _lastSearchQuery = query;

    if (_selectedSymbol != null) {
      setState(() {
        _selectedSymbol = null;
        _type = AssetType.cash;
        _priceController.text = '1';
        _currency = null;
        _originalPrice = null;
      });
    }

    final results = await _yahooService.searchStocks(query);
    if (_lastSearchQuery == query && mounted) {
      _searchResults.value = results;
    }
  }

  Future<void> _onSelectSearchResult(YahooFinanceSearchResult result) async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _nameController.text = result.shortname;
      _selectedSymbol = result.symbol;
      _searchResults.value = [];
    });
    _isLoadingPrice.value = true;

    try {
      final detailsFuture = _yahooService.fetchStockDetails(result.symbol);
      final details = await detailsFuture;
      if (details != null && details['price'] != null) {
        double price = (details['price'] as num).toDouble();
        final currency = (details['currency'] as String?)?.toUpperCase() ?? 'USD';

        if (currency != 'KRW') {
          double? exchangeRate = await _yahooService.fetchExchangeRate(currency);
          exchangeRate ??= _yahooService.getFallbackExchangeRate(currency);
          price = price * exchangeRate;
        }

        if (mounted) {
          setState(() {
            _priceController.text = formatNumber(price);
            _currency = currency;
            _originalPrice = (details['price'] as num).toDouble();

            if (currency == 'KRW') {
              _type =
                  result.quoteType == 'ETF' ? AssetType.etf : AssetType.koreanStock;
            } else {
              _type =
                  result.quoteType == 'ETF' ? AssetType.etf : AssetType.usStock;
            }
          });
        }
      }
    } finally {
      if (mounted) {
        _isLoadingPrice.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.initialHolding != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final inputFillColor = isDark ? const Color(0xFF242424) : const Color(0xFFF7F5F0);
    final borderColor = isDark ? const Color(0xFF383838) : const Color(0xFFE4DFD5);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
            top: 14,
          ),
          child: Form(
            key: _formKey,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 상단 드래그 핸들 ──
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : const Color(0xFFDDD8CE),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // ── 헤더 (아이콘 + 타이틀 + 뱃지 + 닫기버튼) ──
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEditMode ? Icons.edit_note_rounded : Icons.add_chart_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isEditMode ? '자산 수정' : '자산 추가',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (_selectedSymbol != null && _selectedSymbol!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEBE6DD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _selectedSymbol!,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          iconSize: 20,
                          color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── 1. 종목명 검색 입력창 ──
                    Text(
                      '종목명 또는 심볼 검색',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      focusNode: _searchFocusNode,
                      controller: _nameController,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                      decoration: InputDecoration(
                        hintText: '예: 삼성전자, AAPL, SCHD, 현금',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.grey[500] : const Color(0xFFA8A095),
                        ),
                        filled: true,
                        fillColor: inputFillColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                        ),
                        suffixIcon: _nameController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.cancel_rounded, size: 18),
                                color: isDark ? Colors.grey[500] : const Color(0xFFA8A095),
                                onPressed: () {
                                  _nameController.clear();
                                  _onSearchQueryChanged('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor, width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor, width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                      onChanged: _onSearchQueryChanged,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '종목명을 입력해주세요';
                        }
                        if (widget.initialHolding == null ||
                            _nameController.text.trim() != widget.initialHolding!.name) {
                          if (_selectedSymbol == null && _type != AssetType.cash) {
                            return '검색 결과 목록에서 종목을 선택해주세요';
                          }
                        }
                        return null;
                      },
                    ),

                    // 로딩 인디케이터
                    ValueListenableBuilder<bool>(
                      valueListenable: _isLoadingPrice,
                      builder: (context, isLoading, _) {
                        if (!isLoading) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '실시간 시세 및 최신 환율 조회 중...',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    // ── 2. 계좌 구분 (캡슐 버튼) ──
                    Text(
                      '보유 계좌 선택',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: inputFillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: Row(
                        children: AccountType.values.map((account) {
                          final isSelected = (_account ?? AccountType.general) == account;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                setState(() => _account = account);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF2E9E82) : primaryColor)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    account.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.grey[400] : const Color(0xFF7A7265)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── 3. 보유 수량 입력 ──
                    Text(
                      '보유 수량',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [NumberInputFormatter()],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : const Color(0xFFA8A095),
                        ),
                        suffixText: _type == AssetType.cash ? '원' : '주',
                        suffixStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                        ),
                        filled: true,
                        fillColor: inputFillColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor, width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor, width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                      validator: _numberValidator,
                    ),

                    // ── 4. 자동 연동 실시간 시세 카드 ──
                    if (_selectedSymbol != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF222222) : const Color(0xFFF9F7F3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E0D7),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '실시간 시장 데이터 연동',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.grey[300] : const Color(0xFF6E675E),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    _type?.label ?? '주식',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20, thickness: 0.7),
                            if (_currency != null && _currency != 'KRW' && _originalPrice != null) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '시장 기준가 ($_currency)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                                    ),
                                  ),
                                  Text(
                                    '${_currency == 'USD' ? '\$' : _currency == 'CAD' ? 'C\$' : _currency == 'JPY' ? '¥' : _currency == 'EUR' ? '€' : _currency == 'GBP' ? '£' : '$_currency '}${formatNumber(_originalPrice!)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _currency != null && _currency != 'KRW' ? '원화 환산 단가' : '주당 현재가',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[300] : const Color(0xFF4A443D),
                                  ),
                                ),
                                Text(
                                  '₩${_priceController.text}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? const Color(0xFF34D399) : primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // 안내 텍스트
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: isDark ? Colors.grey[500] : const Color(0xFF9E9790),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '동일 계좌에 이미 있는 종목은 수량이 자동으로 합산됩니다.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── 5. 저장 / 등록 버튼 ──
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          widget.initialHolding == null ? '자산 추가하기' : '변경사항 저장하기',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── 실시간 검색 드롭다운 플로팅 카드 ──
                Positioned(
                  top: 138,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<List<YahooFinanceSearchResult>>(
                    valueListenable: _searchResults,
                    builder: (context, results, _) {
                      if (results.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? const Color(0xFF3E3E3E) : const Color(0xFFDDD8CE),
                            width: 0.9,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: results.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: isDark ? const Color(0xFF333333) : const Color(0xFFF0EBE1),
                            ),
                            itemBuilder: (context, index) {
                              final item = results[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _onSelectSearchResult(item),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.show_chart_rounded,
                                            color: primaryColor,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.shortname,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${item.symbol} · ${item.exchange}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _numberValidator(String? value) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', ''));
    if (parsed == null || parsed < 0) {
      return '숫자를 올바르게 입력해주세요';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_type == null || _account == null) return;

    final quantity = double.parse(_quantityController.text.replaceAll(',', ''));
    final price = double.parse(_priceController.text.replaceAll(',', ''));

    Navigator.of(context).pop(
      Holding(
        name: _nameController.text.trim(),
        symbol: _selectedSymbol,
        type: _type!,
        account: _account!,
        quantity: quantity,
        price: price,
        originalPrice: _originalPrice,
        currency: _currency,
      ),
    );
  }
}
