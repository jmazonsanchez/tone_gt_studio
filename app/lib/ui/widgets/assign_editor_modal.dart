import 'package:flutter/material.dart';
import '../../services/patch_service.dart';
import 'assign_ctl_tab.dart';
import 'assign_footswitch_tab.dart';
import 'assign_matrix_tab.dart';

/// Modal dialog for Boss GT-1B Control (CTL1..3), Expression Pedals (EXP1..2, EXP1 SW),
/// Footswitches (Down, Up), Levels (In/Out), and Assign Matrices A1–A6.
class AssignEditorModal extends StatefulWidget {
  final PatchService patchService;

  const AssignEditorModal({super.key, required this.patchService});

  static Future<void> show(BuildContext context, PatchService patchService) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AssignEditorModal(patchService: patchService),
    );
  }

  @override
  State<AssignEditorModal> createState() => _AssignEditorModalState();
}

class _AssignEditorModalState extends State<AssignEditorModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.patchService,
      builder: (context, _) {
        return Dialog(
          backgroundColor: const Color(0xFF14141E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF00ADB5), width: 1.5),
          ),
          child: Container(
            width: 760,
            height: 560,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF00ADB5),
                  labelColor: const Color(0xFF00ADB5),
                  unselectedLabelColor: Colors.white54,
                  tabs: const [
                    Tab(icon: Icon(Icons.settings_remote, size: 16), text: 'CTL & EXP'),
                    Tab(icon: Icon(Icons.swap_vert, size: 16), text: 'DOWN / UP & NIVELES'),
                    Tab(icon: Icon(Icons.hub, size: 16), text: 'ASIGNACIONES (A1–A6)'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      AssignCtlTab(patchService: widget.patchService),
                      AssignFootswitchTab(patchService: widget.patchService),
                      AssignMatrixTab(patchService: widget.patchService),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Row(
            children: [
              Icon(Icons.tune, color: Color(0xFF00ADB5), size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'CONFIGURACIÓN GT-1B (CTL / EXP / A1–A6 / I-O)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white38, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
