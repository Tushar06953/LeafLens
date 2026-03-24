import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/router/app_router.dart';

// ─── Local providers ──────────────────────────────────────────────────────────

final _scanModeProvider = StateProvider<String>((ref) => 'leaf');
final _multiAngleProvider = StateProvider<bool>((ref) => false);
final _capturedImagesProvider = StateProvider<List<File>>((ref) => []);
final _flashOnProvider = StateProvider<bool>((ref) => false);

// ─── Screen ───────────────────────────────────────────────────────────────────

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isInitialized = false;
  bool _permissionDenied = false;
  bool _isCapturing = false;

  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _permissionDenied = true);
        return;
      }
      await _startCamera(_cameras[_cameraIndex]);
    } catch (_) {
      setState(() => _permissionDenied = true);
    }
  }

  Future<void> _startCamera(CameraDescription cam) async {
    final ctrl = CameraController(cam, ResolutionPreset.high, enableAudio: false);
    try {
      await ctrl.initialize();
      if (!mounted) return;
      await _controller?.dispose();
      setState(() {
        _controller = ctrl;
        _isInitialized = true;
      });
    } catch (_) {
      setState(() => _permissionDenied = true);
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    setState(() => _isInitialized = false);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera(_cameras[_cameraIndex]);
  }

  Future<void> _toggleFlash() async {
    final on = ref.read(_flashOnProvider);
    try {
      await _controller?.setFlashMode(on ? FlashMode.off : FlashMode.torch);
      ref.read(_flashOnProvider.notifier).state = !on;
    } catch (_) {}
  }

  Future<void> _capture() async {
    if (_isCapturing || _controller == null || !_isInitialized) return;
    setState(() => _isCapturing = true);
    try {
      final xFile = await _controller!.takePicture();
      final file = File(xFile.path);
      final mode = ref.read(_scanModeProvider);
      final isMulti = ref.read(_multiAngleProvider);

      if (isMulti) {
        final captured = [...ref.read(_capturedImagesProvider), file];
        ref.read(_capturedImagesProvider.notifier).state = captured;
        if (captured.length >= 3) {
          ref.read(_capturedImagesProvider.notifier).state = [];
          if (mounted) {
            context.go(AppRoutes.analyzing, extra: {
              'images': captured.map((f) => f.path).toList(),
              'mode': mode,
            });
          }
        }
      } else {
        if (mounted) {
          context.go(AppRoutes.analyzing, extra: {
            'images': [file.path],
            'mode': mode,
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    final mode = ref.read(_scanModeProvider);
    context.go(AppRoutes.analyzing, extra: {
      'images': [picked.path],
      'mode': mode,
    });
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(_scanModeProvider);
    final isMulti = ref.watch(_multiAngleProvider);
    final captured = ref.watch(_capturedImagesProvider);
    final flashOn = ref.watch(_flashOnProvider);

    if (_permissionDenied) {
      return _PermissionDeniedScreen(onBack: () => context.go(AppRoutes.home));
    }

    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gc),
        ),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          CameraPreview(_controller!),

          // Animated scan line
          AnimatedBuilder(
            animation: _scanLineAnim,
            builder: (_, __) {
              final topOffset = size.height * 0.22 +
                  (size.height * 0.38) * _scanLineAnim.value;
              return Positioned(
                top: topOffset,
                left: size.width * 0.1,
                right: size.width * 0.1,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      AppColors.gc.withOpacity(0.85),
                      Colors.transparent,
                    ]),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gc.withOpacity(0.4),
                        blurRadius: 6,
                      )
                    ],
                  ),
                ),
              );
            },
          ),

          // Corner brackets overlay
          Positioned.fill(
            child: CustomPaint(painter: _BracketsPainter()),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleBtn(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.go(AppRoutes.home),
                    ),
                    Text(
                      isMulti && captured.isNotEmpty
                          ? '${captured.length} / 3 captured'
                          : 'Scan Plant',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _CircleBtn(
                      icon: flashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      onTap: _toggleFlash,
                      highlighted: flashOn,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Mode chips
          Positioned(
            bottom: 148,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['leaf', 'flower', 'bark', 'full'].map((m) {
                  final active = mode == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(_scanModeProvider.notifier).state = m,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.gb
                              : Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? AppColors.gc : Colors.white30,
                          ),
                        ),
                        child: Text(
                          m == 'full'
                              ? 'Full Plant'
                              : m[0].toUpperCase() + m.substring(1),
                          style: TextStyle(
                            color:
                                active ? Colors.white : Colors.white70,
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Multi-angle toggle
          Positioned(
            bottom: 108,
            right: 24,
            child: GestureDetector(
              onTap: () {
                ref.read(_multiAngleProvider.notifier).state = !isMulti;
                ref.read(_capturedImagesProvider.notifier).state = [];
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isMulti
                      ? AppColors.gb.withOpacity(0.85)
                      : Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color:
                          isMulti ? AppColors.gc : Colors.white30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.layers_rounded,
                        size: 14,
                        color: isMulti ? Colors.white : Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      isMulti
                          ? '${captured.length}/3 angles'
                          : 'Multi-angle',
                      style: TextStyle(
                        color: isMulti ? Colors.white : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                top: 20,
                left: 32,
                right: 32,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _CircleBtn(
                    icon: Icons.photo_library_rounded,
                    onTap: _pickFromGallery,
                    size: 48,
                  ),
                  GestureDetector(
                    onTap: _isCapturing ? null : _capture,
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        color: _isCapturing
                            ? AppColors.gb
                            : Colors.white,
                      ),
                      child: _isCapturing
                          ? const Padding(
                              padding: EdgeInsets.all(18),
                              child: CircularProgressIndicator(
                                color: AppColors.gb,
                                strokeWidth: 2,
                              ),
                            )
                          : null,
                    ),
                  ),
                  _CircleBtn(
                    icon: Icons.flip_camera_ios_rounded,
                    onTap: _flipCamera,
                    size: 48,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool highlighted;

  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.size = 42,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: highlighted
              ? AppColors.gb.withOpacity(0.85)
              : Colors.black54,
          border: Border.all(
              color: highlighted ? AppColors.gc : Colors.white30),
        ),
        child: Icon(icon,
            color: Colors.white, size: size * 0.48),
      ),
    );
  }
}

class _BracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gc
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const b = 26.0;
    final l = size.width * 0.1;
    final r = size.width * 0.9;
    final t = size.height * 0.2;
    final bot = size.height * 0.62;

    // top-left
    canvas.drawLine(Offset(l, t + b), Offset(l, t), paint);
    canvas.drawLine(Offset(l, t), Offset(l + b, t), paint);
    // top-right
    canvas.drawLine(Offset(r - b, t), Offset(r, t), paint);
    canvas.drawLine(Offset(r, t), Offset(r, t + b), paint);
    // bottom-left
    canvas.drawLine(Offset(l, bot - b), Offset(l, bot), paint);
    canvas.drawLine(Offset(l, bot), Offset(l + b, bot), paint);
    // bottom-right
    canvas.drawLine(Offset(r - b, bot), Offset(r, bot), paint);
    canvas.drawLine(Offset(r, bot), Offset(r, bot - b), paint);
  }

  @override
  bool shouldRepaint(_BracketsPainter old) => false;
}

class _PermissionDeniedScreen extends StatelessWidget {
  final VoidCallback onBack;
  const _PermissionDeniedScreen({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.g1,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📷', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text('Camera Access Required',
                  style: AppTextStyles.heading2,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Please enable camera access in your device settings to scan plants.',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.text2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gb,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: onBack,
                  child: Text('Go Back', style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
