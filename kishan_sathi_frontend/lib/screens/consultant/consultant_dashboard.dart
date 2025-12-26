import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ConsultantDashboard extends StatefulWidget {
const ConsultantDashboard({super.key});

@override
State<ConsultantDashboard> createState() => _ConsultantDashboardState();
}

class _ConsultantDashboardState extends State<ConsultantDashboard> {
int _selectedIndex = 0;

final List<Widget> _screens = [
const ConsultantHomeScreen(),
const AppointmentsScreen(),
const ChatRequestsScreen(),
const KnowledgeBaseScreen(),
const ConsultantProfileScreen(),
];

@override
Widget build(BuildContext context) {
return Scaffold(
body: _screens[_selectedIndex],
floatingActionButton: _selectedIndex == 3 // Only show on Knowledge Base screen
? FloatingActionButton.extended(
onPressed: () {
_showCreateArticleDialog(context);
},
backgroundColor: const Color(0xFFFF9800),
icon: const Icon(Icons.article, color: Colors.white),
label: const Text(
'New Article',
style: TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
),
),
elevation: 4,
)
: null,
bottomNavigationBar: Container(
decoration: BoxDecoration(
color: Colors.white,
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.1),
blurRadius: 10,
offset: const Offset(0, -5),
),
],
),
child: SafeArea(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
_buildNavItem(Icons.dashboard, 'Home', 0),
_buildNavItem(Icons.calendar_today, 'Appointments', 1),
_buildNavItem(Icons.chat_bubble, 'Chats', 2),
_buildNavItem(Icons.library_books, 'Knowledge', 3),
_buildNavItem(Icons.person, 'Profile', 4),
],
),
),
),
),
);
}

Widget _buildNavItem(IconData icon, String label, int index) {
final isSelected = _selectedIndex == index;
return GestureDetector(
onTap: () {
setState(() => _selectedIndex = index);
},
child: AnimatedContainer(
duration: const Duration(milliseconds: 200),
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
decoration: BoxDecoration(
color: isSelected ? const Color(0xFFFF9800).withOpacity(0.1) : Colors.transparent,
borderRadius: BorderRadius.circular(12),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
color: isSelected ? const Color(0xFFFF9800) : Colors.grey,
size: 24,
),
const SizedBox(height: 4),
Text(
label,
style: TextStyle(
color: isSelected ? const Color(0xFFFF9800) : Colors.grey,
fontSize: 11,
fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
),
),
],
),
),
);
}

void _showCreateArticleDialog(BuildContext context) {
showModalBottomSheet(
context: context,
isScrollControlled: true,
backgroundColor: Colors.transparent,
builder: (context) => const CreateArticleBottomSheet(),
);
}
}

// Consultant Home Screen
class ConsultantHomeScreen extends StatelessWidget {
const ConsultantHomeScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppTheme.backgroundColor,
body: SafeArea(
child: CustomScrollView(
slivers: [
// App Bar
SliverToBoxAdapter(
child: Container(
padding: const EdgeInsets.all(20),
decoration: const BoxDecoration(
gradient: LinearGradient(
colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.only(
bottomLeft: Radius.circular(30),
bottomRight: Radius.circular(30),
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Welcome Back! 👨‍⚕️',
style: TextStyle(
color: Colors.white.withOpacity(0.9),
fontSize: 16,
),
),
const SizedBox(height: 4),
const Text(
'Dr. Indira Kattel',
style: TextStyle(
color: Colors.white,
fontSize: 24,
fontWeight: FontWeight.bold,
),
),
],
),
Stack(
children: [
IconButton(
onPressed: () {},
icon: const Icon(
Icons.notifications_outlined,
color: Colors.white,
size: 28,
),
),
Positioned(
right: 8,
top: 8,
child: Container(
padding: const EdgeInsets.all(4),
decoration: const BoxDecoration(
color: Colors.red,
shape: BoxShape.circle,
),
child: const Text(
'5',
style: TextStyle(
color: Colors.white,
fontSize: 10,
fontWeight: FontWeight.bold,
),
),
),
),
],
),
],
),
const SizedBox(height: 20),
// Stats Cards
Row(
children: [
Expanded(
child: _StatCard(
icon: Icons.people,
label: 'Total Patients',
value: '248',
color: Colors.white.withOpacity(0.9),
),
),
const SizedBox(width: 12),
Expanded(
child: _StatCard(
icon: Icons.calendar_today,
label: 'Today\'s Appointments',
value: '8',
color: Colors.white.withOpacity(0.9),
),
),
],
),
],
),
),
),

// Quick Actions
SliverToBoxAdapter(
child: Padding(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Quick Actions',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
color: AppTheme.darkGreen,
),
),
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: _QuickActionCard(
icon: Icons.chat,
label: 'Start Consultation',
color: const Color(0xFF4CAF50),
onTap: () {},
),
),
const SizedBox(width: 12),
Expanded(
child: _QuickActionCard(
icon: Icons.video_call,
label: 'Video Call',
color: const Color(0xFF2196F3),
onTap: () {},
),
),
],
),
const SizedBox(height: 12),
Row(
children: [
Expanded(
child: _QuickActionCard(
icon: Icons.article,
label: 'Write Article',
color: const Color(0xFFFF9800),
onTap: () {},
),
),
const SizedBox(width: 12),
Expanded(
child: _QuickActionCard(
icon: Icons.analytics,
label: 'My Stats',
color: const Color(0xFF9C27B0),
onTap: () {},
),
),
],
),
],
),
),
),

// Upcoming Appointments
SliverToBoxAdapter(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 20),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text(
'Today\'s Schedule',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
color: AppTheme.darkGreen,
),
),
TextButton(
onPressed: () {},
child: const Text(
'View All',
style: TextStyle(
color: Color(0xFFFF9800),
fontWeight: FontWeight.w600,
),
),
),
],
),
),
),

// Appointments List
SliverPadding(
padding: const EdgeInsets.symmetric(horizontal: 20),
sliver: SliverList(
delegate: SliverChildListDelegate([
const _AppointmentCard(
farmerName: 'Ram Sharma',
time: '10:00 AM',
issue: 'Wheat crop disease diagnosis',
status: 'upcoming',
),
const SizedBox(height: 12),

const SizedBox(height: 12),

const SizedBox(height: 20),
]),
),
),
],
),
),
);
}
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
final IconData icon;
final String label;
final String value;
final Color color;

const _StatCard({
required this.icon,
required this.label,
required this.value,
required this.color,
});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: color,
borderRadius: BorderRadius.circular(16),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(icon, color: const Color(0xFFFF9800), size: 28),
const SizedBox(height: 12),
Text(
value,
style: const TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: Color(0xFFFF9800),
),
),
const SizedBox(height: 4),
Text(
label,
style: TextStyle(
fontSize: 12,
color: Colors.grey[700],
),
),
],
),
);
}
}

// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
final IconData icon;
final String label;
final Color color;
final VoidCallback onTap;

const _QuickActionCard({
required this.icon,
required this.label,
required this.color,
required this.onTap,
});

@override
Widget build(BuildContext context) {
return GestureDetector(
onTap: onTap,
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Column(
children: [
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: color.withOpacity(0.1),
shape: BoxShape.circle,
),
child: Icon(icon, color: color, size: 28),
),
const SizedBox(height: 12),
Text(
label,
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w600,
color: Colors.grey[800],
),
),
],
),
),
);
}
}

// Appointment Card Widget
class _AppointmentCard extends StatelessWidget {
final String farmerName;
final String time;
final String issue;
final String status;

const _AppointmentCard({
required this.farmerName,
required this.time,
required this.issue,
required this.status,
});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Row(
children: [
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: const Color(0xFFFF9800).withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
),
child: const Icon(
Icons.person,
color: Color(0xFFFF9800),
size: 32,
),
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
farmerName,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: AppTheme.darkGreen,
),
),
const SizedBox(height: 4),
Text(
issue,
style: TextStyle(
fontSize: 13,
color: Colors.grey[600],
),
),
const SizedBox(height: 8),
Row(
children: [
Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
const SizedBox(width: 4),
Text(
time,
style: TextStyle(
fontSize: 12,
color: Colors.grey[600],
),
),
],
),
],
),
),
Column(
children: [
ElevatedButton(
onPressed: () {},
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF4CAF50),
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(8),
),
),
child: const Text('Start', style: TextStyle(fontSize: 12)),
),
],
),
],
),
);
}
}

// Appointments Screen
class AppointmentsScreen extends StatelessWidget {
const AppointmentsScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppTheme.backgroundColor,
appBar: AppBar(
title: const Text('Appointments'),
backgroundColor: const Color(0xFFFF9800),
foregroundColor: Colors.white,
),
body: DefaultTabController(
length: 3,
child: Column(
children: [
Container(
color: Colors.white,
child: const TabBar(
labelColor: Color(0xFFFF9800),
unselectedLabelColor: Colors.grey,
indicatorColor: Color(0xFFFF9800),
tabs: [
Tab(text: 'Upcoming'),
Tab(text: 'Completed'),
Tab(text: 'Cancelled'),
],
),
),
Expanded(
child: TabBarView(
children: [
_buildAppointmentsList('upcoming'),
_buildAppointmentsList('completed'),
_buildAppointmentsList('cancelled'),
],
),
),
],
),
),
);
}

Widget _buildAppointmentsList(String type) {
return ListView(
padding: const EdgeInsets.all(16),
children: const [
_AppointmentCard(
farmerName: 'Ram Sharma',
time: '10:00 AM',
issue: 'Wheat crop disease diagnosis',
status: 'upcoming',
),
SizedBox(height: 12),
_AppointmentCard(
farmerName: 'Sita Devi',
time: '11:30 AM',
issue: 'Soil fertility consultation',
status: 'upcoming',
),
],
);
}
}

// Chat Requests Screen
class ChatRequestsScreen extends StatelessWidget {
const ChatRequestsScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppTheme.backgroundColor,
appBar: AppBar(
title: const Text('Messages'),
backgroundColor: const Color(0xFFFF9800),
foregroundColor: Colors.white,
),
body: ListView(
padding: const EdgeInsets.all(16),
children: [
_ChatRequestCard(
farmerName: 'Krishna Kumar',
message: 'I need help with tomato pest control...',
time: '5 min ago',
isNew: true,
onTap: () {
// TODO: Navigate to chat screen
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Opening chat with Krishna Kumar...'),
duration: Duration(seconds: 1),
),
);
},
),
const SizedBox(height: 12),
_ChatRequestCard(
farmerName: 'Gita Sharma',
message: 'Can you guide me on organic fertilizers?',
time: '15 min ago',
isNew: true,
onTap: () {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Opening chat with Gita Sharma...'),
duration: Duration(seconds: 1),
),
);
},
),
const SizedBox(height: 12),
_ChatRequestCard(
farmerName: 'Ram Sharma',
message: 'Thank you for the advice!',
time: '2 hours ago',
isNew: false,
onTap: () {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Opening chat with Ram Sharma...'),
duration: Duration(seconds: 1),
),
);
},
),
const SizedBox(height: 12),
_ChatRequestCard(
farmerName: 'Sita Devi',
message: 'The crops are doing much better now',
time: '1 day ago',
isNew: false,
onTap: () {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Opening chat with Sita Devi...'),
duration: Duration(seconds: 1),
),
);
},
),
],
),
);
}
}

// Chat Request Card Widget
class _ChatRequestCard extends StatelessWidget {
final String farmerName;
final String message;
final String time;
final bool isNew;
final VoidCallback onTap;

const _ChatRequestCard({
required this.farmerName,
required this.message,
required this.time,
required this.isNew,
required this.onTap,
});

@override
Widget build(BuildContext context) {
return InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(16),
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: isNew ? const Color(0xFFFF9800).withOpacity(0.05) : Colors.white,
borderRadius: BorderRadius.circular(16),
border: isNew ? Border.all(color: const Color(0xFFFF9800).withOpacity(0.3), width: 1) : null,
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Row(
children: [
Stack(
children: [
CircleAvatar(
radius: 28,
backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
child: const Icon(
Icons.person,
color: Color(0xFFFF9800),
size: 28,
),
),
if (isNew)
Positioned(
right: 0,
top: 0,
child: Container(
width: 12,
height: 12,
decoration: BoxDecoration(
color: Colors.red,
shape: BoxShape.circle,
border: Border.all(color: Colors.white, width: 2),
),
),
),
],
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
farmerName,
style: TextStyle(
fontWeight: isNew ? FontWeight.bold : FontWeight.w600,
fontSize: 16,
color: AppTheme.darkGreen,
),
),
Text(
time,
style: TextStyle(
fontSize: 12,
color: Colors.grey[600],
),
),
],
),
const SizedBox(height: 6),
Text(
message,
style: TextStyle(
fontSize: 14,
color: isNew ? Colors.grey[800] : Colors.grey[600],
fontWeight: isNew ? FontWeight.w500 : FontWeight.normal,
),
maxLines: 2,
overflow: TextOverflow.ellipsis,
),
],
),
),
const SizedBox(width: 8),
Icon(
Icons.chevron_right,
color: Colors.grey[400],
size: 20,
),
],
),
),
);
}
}

// Knowledge Base Screen
class KnowledgeBaseScreen extends StatelessWidget {
const KnowledgeBaseScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppTheme.backgroundColor,
appBar: AppBar(
title: const Text('Knowledge Base'),
backgroundColor: const Color(0xFFFF9800),
foregroundColor: Colors.white,
actions: [
IconButton(
onPressed: () {},
icon: const Icon(Icons.search),
),
],
),
body: ListView(
padding: const EdgeInsets.all(16),
children: const [
_ArticleCard(
title: 'Best Practices for Organic Farming',
author: 'Dr. Agricultural Expert',
views: '1.2k',
likes: '234',
publishedDate: '2 days ago',
),
SizedBox(height: 12),
_ArticleCard(
title: 'How to Identify and Treat Common Crop Diseases',
author: 'Dr. Agricultural Expert',
views: '2.5k',
likes: '456',
publishedDate: '1 week ago',
),
],
),
);
}
}

// Article Card Widget
class _ArticleCard extends StatelessWidget {
final String title;
final String author;
final String views;
final String likes;
final String publishedDate;

const _ArticleCard({
required this.title,
required this.author,
required this.views,
required this.likes,
required this.publishedDate,
});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: AppTheme.darkGreen,
),
),
const SizedBox(height: 8),
Text(
'By $author',
style: TextStyle(
fontSize: 12,
color: Colors.grey[600],
),
),
const SizedBox(height: 12),
Row(
children: [
Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
const SizedBox(width: 4),
Text(views, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
const SizedBox(width: 16),
Icon(Icons.thumb_up, size: 16, color: Colors.grey[600]),
const SizedBox(width: 4),
Text(likes, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
const Spacer(),
Text(
publishedDate,
style: TextStyle(fontSize: 12, color: Colors.grey[600]),
),
],
),
],
),
);
}
}

// Create Article Bottom Sheet
class CreateArticleBottomSheet extends StatefulWidget {
const CreateArticleBottomSheet({super.key});

@override
State<CreateArticleBottomSheet> createState() => _CreateArticleBottomSheetState();
}

class _CreateArticleBottomSheetState extends State<CreateArticleBottomSheet> {
final _titleController = TextEditingController();
final _contentController = TextEditingController();
String? _selectedCategory;

final List<String> _categories = [
'Crop Management',
'Pest Control',
'Soil Health',
'Irrigation',
'Organic Farming',
'Market Trends',
];

@override
void dispose() {
_titleController.dispose();
_contentController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Container(
decoration: const BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
),
padding: EdgeInsets.only(
bottom: MediaQuery.of(context).viewInsets.bottom,
),
child: DraggableScrollableSheet(
initialChildSize: 0.8,
minChildSize: 0.5,
maxChildSize: 0.9,
expand: false,
builder: (context, scrollController) {
return SingleChildScrollView(
controller: scrollController,
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text(
'Write Article',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: AppTheme.darkGreen,
),
),
IconButton(
onPressed: () => Navigator.pop(context),
icon: const Icon(Icons.close),
style: IconButton.styleFrom(
backgroundColor: Colors.grey[100],
),
),
],
),
const SizedBox(height: 20),
TextField(
controller: _titleController,
decoration: InputDecoration(
labelText: 'Article Title',
hintText: 'Enter article title',
filled: true,
fillColor: AppTheme.backgroundColor,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
),
),
const SizedBox(height: 16),
DropdownButtonFormField<String>(
value: _selectedCategory,
decoration: InputDecoration(
labelText: 'Category',
filled: true,
fillColor: AppTheme.backgroundColor,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
),
items: _categories.map((category) {
return DropdownMenuItem(
value: category,
child: Text(category),
);
}).toList(),
onChanged: (value) {
setState(() => _selectedCategory = value);
},
),
const SizedBox(height: 16),
TextField(
controller: _contentController,
maxLines: 8,
decoration: InputDecoration(
labelText: 'Content',
hintText: 'Write your article content...',
filled: true,
fillColor: AppTheme.backgroundColor,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
),
),
const SizedBox(height: 24),
SizedBox(
width: double.infinity,
height: 56,
child: ElevatedButton(
onPressed: () {
Navigator.pop(context);
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Article published successfully!'),
backgroundColor: Color(0xFFFF9800),
),
);
},
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFFFF9800),
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
child: const Text(
'Publish Article',
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
),
),
],
),
);
},
),
);
}
}

// Consultant Profile Screen
class ConsultantProfileScreen extends StatelessWidget {
const ConsultantProfileScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppTheme.backgroundColor,
appBar: AppBar(
title: const Text('Profile'),
backgroundColor: const Color(0xFFFF9800),
foregroundColor: Colors.white,
elevation: 0,
),
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
children: [
Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Column(
children: [
CircleAvatar(
radius: 50,
backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
child: const Icon(
Icons.person,
size: 50,
color: Color(0xFFFF9800),
),
),
const SizedBox(height: 16),
const Text(
'Dr. Indira Kattel',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: AppTheme.darkGreen,
),
),
const SizedBox(height: 4),
Text(
'Agricultural Consultant',
style: TextStyle(
fontSize: 16,
color: Colors.grey[600],
),
),
const SizedBox(height: 8),
Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
decoration: BoxDecoration(
color: const Color(0xFFFF9800).withOpacity(0.1),
borderRadius: BorderRadius.circular(20),
),
child: const Text(
'expert@kishanstathi.com',
style: TextStyle(
color: Color(0xFFFF9800),
fontSize: 14,
),
),
),
const SizedBox(height: 16),
Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
_ProfileStat(label: 'Consultations', value: '248'),
_ProfileStat(label: 'Articles', value: '45'),
_ProfileStat(label: 'Rating', value: '4.9'),
],
),
],
),
),
const SizedBox(height: 24),
_buildProfileOption(
context,
icon: Icons.person_outline,
title: 'Edit Profile',
onTap: () {},
),

_buildProfileOption(
context,
icon: Icons.notifications_outlined,
title: 'Notifications',
onTap: () {},
),
_buildProfileOption(
context,
icon: Icons.help_outline,
title: 'Help & Support',
onTap: () {},
),
_buildProfileOption(
context,
icon: Icons.info_outline,
title: 'About',
onTap: () {},
),
const SizedBox(height: 16),
SizedBox(
width: double.infinity,
child: ElevatedButton.icon(
onPressed: () {
Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
},
icon: const Icon(Icons.logout),
label: const Text('Logout'),
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.errorRed,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(vertical: 16),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
),
),
],
),
),
),
);
}

Widget _buildProfileOption(
BuildContext context, {
required IconData icon,
required String title,
required VoidCallback onTap,
}) {
return Container(
margin: const EdgeInsets.only(bottom: 12),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(12),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.03),
blurRadius: 8,
offset: const Offset(0, 2),
),
],
),
child: ListTile(
leading: Icon(icon, color: const Color(0xFFFF9800)),
title: Text(
title,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.w500,
),
),
trailing: const Icon(Icons.chevron_right, color: Colors.grey),
onTap: onTap,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
);
}
}

// Profile Stat Widget
class _ProfileStat extends StatelessWidget {
final String label;
final String value;

const _ProfileStat({
required this.label,
required this.value,
});

@override
Widget build(BuildContext context) {
return Column(
children: [
Text(
value,
style: const TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: Color(0xFFFF9800),
),
),
Text(
label,
style: TextStyle(
fontSize: 12,
color: Colors.grey[600],
),
),
],
);
}
}
