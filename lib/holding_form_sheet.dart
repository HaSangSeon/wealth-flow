import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // 포커스를 잃었을 때 (다른 입력창 클릭 등) 검색 결과를 닫음 (터치 이벤트 처리를 위해 150ms 지연)
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          _searchResults.value = [];
        }
      });
    } else {
      // 다시 포커스를 얻었을 때 검색어가 입력되어 있다면 결과창 다시 켬
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
    FocusScope.of(context).unfocus(); // 종목 선택 완료 시 키보드를 선제적으로 닫음
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
          // KRW가 아닌 외화인 경우 (USD, CAD, JPY 등), 각 통화에 맞는 환율을 동적으로 가져와 원화로 변환
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
              // 미국, 캐나다, 유럽, 일본 등 모든 해외 자산은 해외주식 또는 ETF로 분류
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

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        isEditMode ? '자산 수정' : '자산 추가',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      if (_selectedSymbol != null && _selectedSymbol!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          _selectedSymbol!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : const Color(0xFF8E867C),
                          ),
                        ),
                      ],
                    ],
                  ),
            const SizedBox(height: 16),
            TextFormField(
              focusNode: _searchFocusNode,
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '종목명 (검색하여 자동 입력 가능)',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchQueryChanged,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '종목명을 입력하세요';
                }
                if (widget.initialHolding == null || _nameController.text.trim() != widget.initialHolding!.name) {
                  if (_selectedSymbol == null) {
                    return '검색 결과 목록에서 종목을 선택해주세요';
                  }
                }
                return null;
              },
            ),
              // 검색 결과창은 Stack의 두 번째 자식(Positioned)으로 띄워줍니다. (아래쪽 코드 참고)
            ValueListenableBuilder<bool>(
              valueListenable: _isLoadingPrice,
              builder: (context, isLoading, _) {
                if (!isLoading) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('실시간 시세 및 환율 적용 중...',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              '계좌 구분',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<AccountType>(
                showSelectedIcon: false,
                segments: AccountType.values
                    .map(
                      (account) => ButtonSegment<AccountType>(
                        value: account,
                        label: Text(
                          account.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                selected: {_account ?? AccountType.general},
                onSelectionChanged: (Set<AccountType> newSelection) {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _account = newSelection.first;
                  });
                },
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                  selectedForegroundColor: Colors.white,
                  side: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFE5E0D7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [NumberInputFormatter()],
              decoration: const InputDecoration(
                labelText: '수량',
                border: OutlineInputBorder(),
              ),
              validator: _numberValidator,
            ),
            if (_selectedSymbol != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F8F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEBE6DD),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '자동 연동 정보',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('분류', style: TextStyle(fontSize: 14)),
                        Text(
                          _type?.label ?? '-',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 1),
                    if (_currency != null && _currency != 'KRW' && _originalPrice != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('주당 현재가 ($_currency)', style: const TextStyle(fontSize: 14)),
                          Text(
                            '${_currency == 'USD' ? '\$' : _currency == 'CAD' ? 'C\$' : _currency == 'JPY' ? '¥' : _currency == 'EUR' ? '€' : _currency == 'GBP' ? '£' : '$_currency '}${formatNumber(_originalPrice!)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_currency != null && _currency != 'KRW' ? '원화 환산가 (주당)' : '실시간 현재가 (주당)', style: const TextStyle(fontSize: 14)),
                        Text(
                          '₩${_priceController.text}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '이미 동일 계좌에 존재하는 자산은 추가 시 기존 수량과 합산됩니다.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[400] 
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.initialHolding == null ? '자산 추가하기' : '저장하기',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        // 공중에 띄워질 검색 결과 목록 창 (Positioned)
        Positioned(
              top: 104, // 타이틀(약 32) + 간격(16) + 입력창(약 56) = 104 주변
              left: 0,
              right: 0,
              child: ValueListenableBuilder<List<YahooFinanceSearchResult>>(
                valueListenable: _searchResults,
                builder: (context, results, _) {
                  if (results.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    height: 180,
                    margin: const EdgeInsets.only(top: 4, bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262C2A) : const Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                          blurRadius: 24,
                          spreadRadius: 4,
                          offset: const Offset(0, 12),
                        ),
                      ],
                      border: Border.all(
                          color: isDark ? const Color(0xFF38403D) : const Color(0xFFDDE3E0), 
                          width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.separated(
                        shrinkWrap: false,
                        itemCount: results.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0EBE1)),
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _onSelectSearchResult(item),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.show_chart,
                                          color: Theme.of(context).colorScheme.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.shortname,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: isDark ? Colors.white : const Color(0xFF2C2A28)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.symbol}  •  ${item.exchange}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.grey[400] : const Color(0xFF8C847A)),
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
    );
  }

  String? _numberValidator(String? value) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', ''));
    if (parsed == null || parsed < 0) {
      return '숫자를 입력하세요';
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

// ─── 연금 & 절세 매니저 탭 ───────────────────────────────────

