import 'package:flutter/material.dart';
import '../constants/colors.dart';

class MisAcciones extends StatelessWidget {
  const MisAcciones({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Center(
              child: Text(
                'Mis Medallas',
                style: TextStyle(
                  fontFamily: 'YesevaOne',
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: 100,
                itemBuilder: (context, index) {
                  final bool isLocked = index > 9; // Primeras 10 medallas desbloqueadas
                  return _buildMedalCard(
                    title: '¡No estás solo!',
                    description: 'Consigue más de 10 amigos.',
                    icon: Icons.emoji_events_rounded,
                    isLocked: isLocked,
                    progress: isLocked ? 0 : 1.0,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedalCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isLocked,
    required double progress,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLocked 
                  ? Colors.white.withOpacity(0.05)
                  : Color(AppColors.primaryGreen).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isLocked 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(isLocked ? 0.5 : 1),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'YesevaOne',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(isLocked ? 0.3 : 0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (!isLocked) ...[
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(AppColors.primaryGreen),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


} 