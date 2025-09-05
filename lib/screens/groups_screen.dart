import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:settle_up/screens/group_detail_screen.dart";

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  int amountOwed = 5;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("Groups").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No groups available"));
        }

        final groups = snapshot.data!.docs;

        return Column(
          children: [
            SizedBox(
              height: 45,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Overall, you are owed "),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final groupName = group["name"] ?? "Untitled Group";
                  final imageUrl = group["imageUrl"] ?? ""; // Group image URL

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.group,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    title: Text(
                      groupName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      amountOwed > 0
                          ? "Owed to you: \$${amountOwed.toStringAsFixed(2)}"
                          : "No money owed",
                      style: TextStyle(
                        color: amountOwed > 0 ? Colors.green : Colors.grey,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GroupDetailScreen(groupId: group.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
