import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../models/inventory_item.dart';
import '../../../providers/inventory_provider.dart';

class ScanBarcodeScreen extends StatefulWidget {
  final bool isPosMode;

  const ScanBarcodeScreen({super.key, this.isPosMode = false});

  @override
  State<ScanBarcodeScreen> createState() => _ScanBarcodeScreenState();
}

class _ScanBarcodeScreenState extends State<ScanBarcodeScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  bool _isSearching = false;
  bool _isCameraMode = true; // Mặc định mở camera
  bool _isScanning = true;
  InventoryItem? _foundItem;
  String? _errorMessage;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode != null && barcode.rawValue != null) {
      setState(() => _isScanning = false);
      _barcodeController.text = barcode.rawValue!;
      _searchByBarcode();
    }
  }

  void _toggleCameraMode() {
    setState(() {
      _isCameraMode = !_isCameraMode;
      if (_isCameraMode) {
        _isScanning = true;
      }
    });
  }

  Future<void> _searchByBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mã barcode');
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundItem = null;
    });

    final provider = context.read<InventoryProvider>();
    final item = await provider.findByLinearCode(barcode);

    setState(() {
      _isSearching = false;
      _foundItem = item;
      if (item == null) {
        _errorMessage = 'Không tìm thấy sản phẩm với mã: $barcode';
      }
    });
  }

  Future<void> _onAction() async {
    if (_foundItem == null) return;

    // Nếu là POS Mode -> Trả về barcode cho PosScreen xử lý
    if (widget.isPosMode) {
      Navigator.pop(context, _barcodeController.text);
      return;
    }

    // Nếu là Inventory Mode -> Nhập kho
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số lượng hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<InventoryProvider>();
    final success = await provider.importStock(_foundItem!.productId, quantity);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã nhập $quantity ${_foundItem!.productName} vào kho',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Cập nhật item đã tìm thấy
        setState(() {
          _foundItem = provider.scannedItem;
        });
        // Reset số lượng
        _quantityController.text = '1';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi nhập kho'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCameraScanner() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Camera view
            MobileScanner(
              controller: _scannerController,
              onDetect: _onBarcodeDetected,
            ),
            // Overlay with scan area
            CustomPaint(
              painter: ScanOverlayPainter(),
              child: const SizedBox.expand(),
            ),
            // Instruction text
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isScanning
                      ? 'Đưa mã barcode vào khung hình'
                      : 'Đã quét thành công!',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Flash toggle
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => _scannerController?.toggleTorch(),
                icon: const Icon(Icons.flash_on, color: Color(0xFFD4AF37)),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
            // Rescan button when not scanning
            if (!_isScanning)
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _isScanning = true;
                      _barcodeController.clear();
                      _foundItem = null;
                      _errorMessage = null;
                    });
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(widget.isPosMode ? 'Quét mã sản phẩm' : 'Quét mã nhập kho'),
        backgroundColor: const Color(0xFF16213E),
        actions: [
          // Toggle camera/manual mode
          IconButton(
            onPressed: _toggleCameraMode,
            icon: Icon(
              _isCameraMode ? Icons.keyboard : Icons.camera_alt,
              color: const Color(0xFFD4AF37),
            ),
            tooltip: _isCameraMode ? 'Nhập thủ công' : 'Quét bằng camera',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera Scanner Section
            if (_isCameraMode) ...[
              _buildCameraScanner(),
              const SizedBox(height: 16),
            ],

            // Barcode input section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  if (!_isCameraMode) ...[
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: Color(0xFFD4AF37),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    _isCameraMode
                        ? 'Hoặc nhập mã thủ công'
                        : 'Nhập mã Linear (Barcode)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhập mã 12 số của sản phẩm',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _barcodeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '000000000000',
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        letterSpacing: 4,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD4AF37),
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _searchByBarcode(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSearching ? null : _searchByBarcode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.search, color: Colors.black),
                      label: Text(
                        _isSearching ? 'Đang tìm...' : 'Tìm sản phẩm',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Found item section
            if (_foundItem != null) ...[
              const SizedBox(height: 24),
              _buildFoundItemCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFoundItemCard() {
    final item = _foundItem!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Sản phẩm tìm thấy',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.fullImageUrl != null
                    ? Image.network(
                        item.fullImageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: const Color(0xFF2D2D44),
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: const Color(0xFF2D2D44),
                        child: const Icon(Icons.inventory, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.categoryName,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Tồn kho: ${item.quantity}',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.grey),
          const SizedBox(height: 16),

          // Chỉ hiển thị nhập số lượng nếu KHÔNG phải POS Mode
          if (!widget.isPosMode) ...[
            const Text(
              'Nhập số lượng cần nhập kho:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    final current = int.tryParse(_quantityController.text) ?? 1;
                    if (current > 1) {
                      _quantityController.text = (current - 1).toString();
                    }
                  },
                  icon: const Icon(
                    Icons.remove_circle,
                    color: Color(0xFFD4AF37),
                    size: 32,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final current = int.tryParse(_quantityController.text) ?? 0;
                    _quantityController.text = (current + 1).toString();
                  },
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xFFD4AF37),
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isPosMode
                    ? const Color(0xFFD4AF37)
                    : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                widget.isPosMode ? Icons.add_shopping_cart : Icons.inventory,
                color: widget.isPosMode ? Colors.black : Colors.white,
              ),
              label: Text(
                widget.isPosMode ? 'Thêm vào giỏ' : 'Nhập kho',
                style: TextStyle(
                  color: widget.isPosMode ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for scan overlay
class ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final scanAreaWidth = size.width * 0.8;
    final scanAreaHeight = 80.0;
    final left = (size.width - scanAreaWidth) / 2;
    final top = (size.height - scanAreaHeight) / 2;

    // Draw semi-transparent overlay
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTWH(left, top, scanAreaWidth, scanAreaHeight))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Draw scan area border
    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(
      Rect.fromLTWH(left, top, scanAreaWidth, scanAreaHeight),
      borderPaint,
    );

    // Draw corner accents
    final cornerLength = 20.0;
    final cornerPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLength),
      cornerPaint,
    );
    // Top-right
    canvas.drawLine(
      Offset(left + scanAreaWidth, top),
      Offset(left + scanAreaWidth - cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaWidth, top),
      Offset(left + scanAreaWidth, top + cornerLength),
      cornerPaint,
    );
    // Bottom-left
    canvas.drawLine(
      Offset(left, top + scanAreaHeight),
      Offset(left + cornerLength, top + scanAreaHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaHeight),
      Offset(left, top + scanAreaHeight - cornerLength),
      cornerPaint,
    );
    // Bottom-right
    canvas.drawLine(
      Offset(left + scanAreaWidth, top + scanAreaHeight),
      Offset(left + scanAreaWidth - cornerLength, top + scanAreaHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaWidth, top + scanAreaHeight),
      Offset(left + scanAreaWidth, top + scanAreaHeight - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
