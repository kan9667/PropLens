//users enter query

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/llm_service.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController controller = 
      TextEditingController(); //manages and retreives text entered in text field

  @override
  void dispose() { //used to release resources and prevent memory leaks when a widget is removed from widget tree
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
  padding: const EdgeInsets.all(12),
  child: Column(
    children: [
      TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText:
              'Try: 2 BHK under 80 lakh near DPS',
          prefixIcon:
              const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      ),

      const SizedBox(height: 12),

      ElevatedButton(
        onPressed: () async {
          final result =
              await LlmService.ask(
            controller.text,
          );

          debugPrint(result);
        },
        child: const Text(
          'Test OpenRouter',
        ),
      ),
    ],
  ),
);
    // return Padding(
    //   padding: const EdgeInsets.all(12),
    //   child: TextField( //input widget
    //     controller: controller,

    //     decoration: InputDecoration(
    //       hintText:
    //           'Try: 2 BHK under 80 lakh near DPS',

    //       prefixIcon:
    //           const Icon(Icons.search),

    //       border: OutlineInputBorder(
    //         borderRadius:
    //             BorderRadius.circular(12),
    //       ),
    //     ),

       
    //     onChanged: (value) { //triggers with every keystroke
    //       context.read<AppProvider>() //search bar only wants to send data, doesnt need to rebuild when query changes(watch not used u=instead of read)
    //         .updateQuery(value);
    //     },
    //   ),
    // );
  }
}