// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:smart_gebere/Home/created_task.dart';
import 'package:smart_gebere/Home/expected_event.dart';
import 'package:smart_gebere/Home/task_creation.dart';

class Home_Screen extends StatelessWidget {
  const Home_Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agriculture Innovation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.lightGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 5,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Body
              Expanded(
                child: Column(
                  children: [
                    // Create Task Section
                    Flexible(
                      flex: 1,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(10),
                        color: Colors.deepPurple.shade50,
                        child: Column(
                          children: [
                            SectionHeader(title: 'Create Task', bgColor: Colors.deepPurple.shade100),
                            const TaskCreationSection(),
                          ],
                        ),
                      ),
                    ),
                    // Created Tasks Section
                    
                    const SizedBox(height: 10),
                    Flexible(
                      flex: 1,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(10), 
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1), 
                                    offset: const Offset(0, 4), 
                                    blurRadius: 6, 
                                    spreadRadius: 1, 
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  SectionHeader(title: 'Created Tasks', bgColor: Colors.teal.shade100),
                                  const SizedBox(height: 10,),
                                  Expanded(child: SlideableCreatedTasks()),
                                ],
                              ),
                            ),
                                                ),
                    const SizedBox(height: 10),
                    Flexible(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10), 
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1), 
                                    offset: const Offset(0, 4), 
                                    blurRadius: 6, 
                                    spreadRadius: 1, 
                                  ),
                                ],
                              ),
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(10),
                        
                        child: Column(
                          children: [
                            SectionHeader(title: 'Expected Events', bgColor: Colors.amber.shade100),
                            const SizedBox(height: 10,),

                            const Expanded(child: SlideableExpectedEvents()),
                          ],
                        ),
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
  }
}

// Section Header
class SectionHeader extends StatelessWidget {
  final String title;
  final Color bgColor;

  const SectionHeader({super.key, required this.title, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: bgColor,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
