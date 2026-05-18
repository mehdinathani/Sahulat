import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';

class AgentBrainConsole extends StatelessWidget {
  final List<AgentTrace> trace;

  const AgentBrainConsole({super.key, required this.trace});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildConsoleBody(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(11),
          topRight: Radius.circular(11),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.memory, color: Color(0xFF38BDF8), size: 16),
          const SizedBox(width: 8),
          Text(
            'AGENT EXECUTION TRACE',
            style: GoogleFonts.sourceCodePro(
              color: const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          _buildStatusDot(),
        ],
      ),
    );
  }

  Widget _buildStatusDot() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0xFF10B981),
                blurRadius: 4,
              )
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'SUCCESS',
          style: GoogleFonts.sourceCodePro(
            color: const Color(0xFF10B981),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConsoleBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: trace.asMap().entries.map((entry) {
          final index = entry.key;
          final t = entry.value;
          return _buildTraceItem(t, index, index == trace.length - 1);
        }).toList(),
      ),
    );
  }

  Widget _buildTraceItem(AgentTrace t, int index, bool isLast) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Timeline line (only if not last)
          if (!isLast)
            Positioned(
              top: 12,
              bottom: -20, // spans the bottom padding to bridge items
              left: 3, // center line on the 8px dot (8/2 - 2/2 = 3)
              child: Container(
                width: 2,
                color: const Color(0xFF334155),
              ),
            ),
          // Timeline dot
          Positioned(
            top: 4,
            left: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF38BDF8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '> [STEP] ${t.step}',
                  style: GoogleFonts.sourceCodePro(
                    color: const Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '  Thought: ${t.thought}',
                  style: GoogleFonts.sourceCodePro(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 11,
                  ),
                ),
                if (t.observation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '  Observation: ${t.observation}',
                      style: GoogleFonts.sourceCodePro(
                        color: const Color(0xFFF472B6),
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (t.action != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '  Action: ${t.action}()',
                      style: GoogleFonts.sourceCodePro(
                        color: const Color(0xFFFCD34D),
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
