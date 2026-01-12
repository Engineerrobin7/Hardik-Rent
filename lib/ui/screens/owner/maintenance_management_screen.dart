// Sprint 3: Maintenance Management Screen (For Owners)
// File: lib/ui/screens/owner/maintenance_management_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../data/models/maintenance_models.dart';

class MaintenanceManagementScreen extends StatefulWidget {
  final String ownerId;

  const MaintenanceManagementScreen({Key? key, required this.ownerId}) : super(key: key);

  @override
  State<MaintenanceManagementScreen> createState() => _MaintenanceManagementScreenState();
}

class _MaintenanceManagementScreenState extends State<MaintenanceManagementScreen> with SingleTickerProviderStateMixin {
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Maintenance Requests'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue[700],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue[700],
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'In Progress'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTicketList([TicketStatus.open]),
          _buildTicketList([TicketStatus.inProgress]),
          _buildTicketList([TicketStatus.resolved, TicketStatus.closed]),
        ],
      ),
    );
  }

  Widget _buildTicketList(List<TicketStatus> statuses) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maintenanceTickets')
          .where('ownerId', isEqualTo: widget.ownerId)
          .where('status', whereIn: statuses.map((e) => e.name).toList())
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No tickets found',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final ticket = MaintenanceTicket.fromFirestore(docs[index]);
            return _buildTicketCard(ticket);
          },
        );
      },
    );
  }

  Widget _buildTicketCard(MaintenanceTicket ticket) {
    Color priorityColor;
    switch (ticket.priority) {
      case TicketPriority.low: priorityColor = Colors.green; break;
      case TicketPriority.medium: priorityColor = Colors.blue; break;
      case TicketPriority.high: priorityColor = Colors.orange; break;
      case TicketPriority.urgent: priorityColor = Colors.red; break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTicketDetails(ticket),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ticket.priorityText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(ticket.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ticket.propertyAddress,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    ticket.tenantName,
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (ticket.photoUrls.isNotEmpty) ...[
                    const Spacer(),
                    Icon(Icons.photo, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      '${ticket.photoUrls.length}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTicketDetails(MaintenanceTicket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _TicketDetailsSheet(ticket: ticket),
      ),
    );
  }
}

class _TicketDetailsSheet extends StatefulWidget {
  final MaintenanceTicket ticket;

  const _TicketDetailsSheet({Key? key, required this.ticket}) : super(key: key);

  @override
  State<_TicketDetailsSheet> createState() => _TicketDetailsSheetState();
}

class _TicketDetailsSheetState extends State<_TicketDetailsSheet> {
  late TicketStatus _status;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.ticket.status;
  }

  Future<void> _updateStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('maintenanceTickets')
          .doc(widget.ticket.id)
          .update({
        'status': _status.name,
        'resolutionNotes': _notesController.text.isNotEmpty ? _notesController.text : null,
        if (_status == TicketStatus.resolved) 'resolvedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating ticket: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ticket Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                _buildInfoRow('Issue', widget.ticket.title),
                _buildInfoRow('Description', widget.ticket.description),
                _buildInfoRow('Property', widget.ticket.propertyAddress),
                _buildInfoRow('Tenant', widget.ticket.tenantName),
                
                const SizedBox(height: 20),
                
                const Text('Status Update', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<TicketStatus>(
                  value: _status,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: TicketStatus.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _status = val!),
                ),

                const SizedBox(height: 20),
                
                if (_status == TicketStatus.resolved || _status == TicketStatus.closed) ...[
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Resolution Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],

                const SizedBox(height: 20),
                
                if (widget.ticket.photoUrls.isNotEmpty) ...[
                  const Text('Attached Photos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.ticket.photoUrls.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(widget.ticket.photoUrls[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _updateStatus,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue[700],
              ),
              child: const Text('Update Ticket', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
