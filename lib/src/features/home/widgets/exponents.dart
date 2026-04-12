import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/features/home/widgets/widgets.dart';
import 'package:siade2/src/commons/data/models.dart';
import 'package:siade2/src/providers/data_provider.dart';
import 'package:siade2/src/theme/theme.dart';
import 'package:sizer/sizer.dart';
import 'package:siade2/l10n/app_localizations.dart';

class Exponents extends StatelessWidget {
  const Exponents({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final exponentList = dataProvider.exponents;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Pendant le chargement, on garde l'espace
    if (dataProvider.isLoading && exponentList.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(
              isLight ? Color(0xFF60438C) : AppColors.primaryRed,
            ),
          ),
        ),
      );
    }

    // Si aucune donnée, on ne rend rien
    if (exponentList.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 10.0, right: 85.0, bottom: 15.0),
          decoration: BoxDecoration(
            color: isLight ? Colors.transparent : AppColors.exponentBlue,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  AppLocalizations.of(context)!.exponents,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: isLight ? Color(0xFF180468) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              Gap(10),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: exponentList.length,
                  itemBuilder: (context, index) {
                    final exponent = exponentList[index];
                    final bool isFirst = index == 0;
                    final ImageProvider imgProvider =
                        exponent.imageUrl.startsWith('http')
                            ? NetworkImage(exponent.imageUrl)
                            : AssetImage(exponent.imageUrl) as ImageProvider;

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailsExponents(exponent: exponent),
                        ),
                      ),
                      child: Container(
                        width: 60,
                        height: 60,
                        margin: EdgeInsetsGeometry.only(left: isFirst ? 16 : 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: imgProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 10,
          top: 35,
          child: Container(
            alignment: Alignment.center,
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.w),
              color: isLight ? Color(0xFF60438C) : AppColors.primaryRed,
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AllExponents(exponents: exponentList),
                  ),
                );
              },
              child: Text(
                '+ ${exponentList.length}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
