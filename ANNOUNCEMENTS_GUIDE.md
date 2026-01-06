# 📢 Announcements & Chat Permissions - Implementation Guide

## ✅ Features Implemented

### 1. **Announcements System**
- ✅ Dedicated announcements table in database
- ✅ Separate announcements screen
- ✅ Create, view, and delete announcements
- ✅ "Important" flag for critical announcements
- ✅ Only teachers can post announcements
- ✅ Beautiful UI with color-coded importance
- ✅ Author name and timestamp display
- ✅ Access via campaign icon in chat

### 2. **Chat Permissions**
- ✅ Toggle to allow/restrict student messages
- ✅ "Allow Student Messages" switch in server settings
- ✅ When OFF: Only professor can send messages
- ✅ When ON: Everyone can chat (default)
- ✅ Real-time permission enforcement via RLS
- ✅ Visual feedback in settings

### 3. **Push Notifications** (Ready for Integration)
- ⏳ Database schema ready
- ⏳ Notification infrastructure exists
- ⏳ Needs Firebase Cloud Messaging setup
- ⏳ See implementation guide below

---

## 🗄️ Database Changes

### New Tables:
1. **`announcements`**
   - `id` - UUID primary key
   - `server_id` - Reference to chat_servers
   - `author_id` - Reference to profiles
   - `title` - Announcement title
   - `content` - Announcement body
   - `is_important` - Boolean flag
   - `created_at` - Timestamp
   - `updated_at` - Timestamp

### Modified Tables:
1. **`chat_servers`**
   - Added: `allow_student_messages` (boolean, default true)

2. **`chat_messages`**
   - Added: `is_announcement` (boolean, default false)

### New RLS Policies:
- View announcements: Members and owners
- Create announcements: Only owners
- Update/Delete announcements: Only author
- Send messages: Respects `allow_student_messages` setting

---

## 🚀 How to Use

### For Professors:

#### Creating Announcements:
1. Open any class server
2. Tap the **📢 Campaign icon** in top right
3. Tap **"New Announcement"** button
4. Fill in:
   - Title (e.g., "Midterm Exam Schedule")
   - Content (announcement details)
   - Check "Mark as Important" if critical
5. Tap **"Post"**

#### Managing Chat Permissions:
1. Open any class server
2. Tap the **⚙️ Settings icon** (gear)
3. Toggle **"Allow Student Messages"**:
   - **ON** (Green): Students can send messages
   - **OFF** (Grey): Only you can send messages
4. Confirmation message appears

#### Viewing Announcements:
- Tap the **📢 Campaign icon** in any server
- See all announcements sorted by newest first
- Important announcements have red background
- Delete your own announcements with trash icon

### For Students:

#### Viewing Announcements:
1. Open any class server
2. Tap the **📢 Campaign icon**
3. View all announcements from professor
4. Important ones are highlighted in red

#### Chat Restrictions:
- If professor disabled student messages:
  - You can only view messages
  - Send button is disabled
  - Message shows "Only professor can send messages"

---

## 📱 UI/UX Features

### Announcements Screen:
```
┌────────────────────────────────────┐
│ [!] IMPORTANT                      │
│ Midterm Exam Schedule              │
│ By Prof. Smith • 2h ago            │
│                                    │
│ The midterm will be held on...    │
└────────────────────────────────────┘
```

### Server Settings:
```
┌────────────────────────────────────┐
│ ⚙️ Chat Permissions                │
├────────────────────────────────────┤
│ 💬 Allow Student Messages    [ON] │
│    Students can send messages      │
├────────────────────────────────────┤
│ 👥 Members (15)                    │
│ ...member list...                  │
└────────────────────────────────────┘
```

---

## 🔔 Push Notifications Setup (Next Step)

### Prerequisites:
1. Firebase project
2. Firebase Cloud Messaging enabled
3. Flutter Firebase packages

### Implementation Steps:

#### 1. Add Dependencies to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.3.0
```

#### 2. Firebase Configuration:
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your app
flutterfire configure
```

#### 3. Update `main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(const MyApp());
}
```

#### 4. Create Notification Service:
```dart
// lib/services/notification_service.dart
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  Future<void> initialize() async {
    // Request permission
    await _fcm.requestPermission();
    
    // Get FCM token
    String? token = await _fcm.getToken();
    print('FCM Token: $token');
    
    // Save token to Supabase profiles table
    if (token != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', Supabase.instance.client.auth.currentUser!.id);
    }
    
    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
      // Show local notification
    });
  }
}
```

#### 5. Update Database Schema:
```sql
-- Add FCM token column to profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS fcm_token text;

-- Create notifications log table
CREATE TABLE IF NOT EXISTS public.notification_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text NOT NULL,
  type text NOT NULL, -- 'announcement', 'message', 'assignment', etc.
  related_id uuid, -- ID of related entity
  sent_at timestamptz DEFAULT now(),
  read_at timestamptz
);
```

#### 6. Send Notifications (Backend/Edge Function):
```javascript
// Supabase Edge Function: send-notification
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  const { userIds, title, body, data } = await req.json()
  
  // Get FCM tokens for users
  const { data: profiles } = await supabase
    .from('profiles')
    .select('fcm_token')
    .in('id', userIds)
  
  const tokens = profiles.map(p => p.fcm_token).filter(Boolean)
  
  // Send via FCM
  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Authorization': `key=${Deno.env.get('FCM_SERVER_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      registration_ids: tokens,
      notification: { title, body },
      data,
    }),
  })
  
  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

#### 7. Trigger Notifications:

**When Announcement is Posted:**
```dart
Future<void> _createAnnouncement(...) async {
  // Create announcement
  await _supabase.from('announcements').insert({...});
  
  // Get all server members
  final members = await _supabase
      .from('server_members')
      .select('user_id')
      .eq('server_id', serverId);
  
  final userIds = members.map((m) => m['user_id']).toList();
  
  // Send notification via Edge Function
  await _supabase.functions.invoke('send-notification', body: {
    'userIds': userIds,
    'title': 'New Announcement in $serverName',
    'body': title,
    'data': {
      'type': 'announcement',
      'serverId': serverId,
    },
  });
}
```

---

## 📊 Notification Types to Implement

### High Priority:
1. **New Announcement** ✅ (Ready to implement)
   - Trigger: Professor posts announcement
   - Recipients: All server members
   - Action: Open announcements screen

2. **New Message in Chat**
   - Trigger: New message in server
   - Recipients: All members (except sender)
   - Action: Open chat screen

3. **Important Announcement**
   - Trigger: Professor marks announcement as important
   - Recipients: All server members
   - Action: Open announcement with highlight

### Medium Priority:
4. **Assignment Posted** (Future)
5. **Grade Published** (Future)
6. **Deadline Reminder** (Future)

---

## 🎨 UI Improvements Made

### Chat Screen:
- Added **📢 Announcements** button
- Added **📁 Content Library** button
- Added **⚙️ Settings** button (teachers only)

### Server Settings:
- Permission toggle with visual feedback
- Member count display
- Organized layout with sections

### Announcements Screen:
- Important announcements highlighted in red
- Author and timestamp display
- Delete option for own announcements
- Empty state with icon
- Floating action button for teachers

---

## 🔒 Security Features

### RLS Policies:
- ✅ Only teachers can create announcements
- ✅ Only authors can delete their announcements
- ✅ Only server owners can change chat permissions
- ✅ Message sending respects permission settings
- ✅ All queries are protected by row-level security

### Permission Enforcement:
- Database-level enforcement (can't bypass from app)
- Real-time updates when permissions change
- Clear error messages for unauthorized actions

---

## 📝 Required Actions

### Immediate (To Use Current Features):
1. **Run SQL Script**: `backend/03_announcements.sql`
   - Creates announcements table
   - Adds permission column
   - Sets up RLS policies

2. **Restart App**: Hot restart to load new code

3. **Test Features**:
   - Create an announcement as teacher
   - Toggle chat permissions
   - View announcements as student

### Next Steps (For Push Notifications):
1. Set up Firebase project
2. Add Firebase dependencies
3. Configure Firebase in app
4. Create notification service
5. Deploy Edge Function for sending notifications
6. Test notification flow

---

## 🎯 Success Metrics

Track these to measure feature adoption:
- Number of announcements posted per week
- Percentage of servers using restricted chat
- Notification open rate
- Time to view announcement after posting
- Student engagement with announcements

---

## 💡 Future Enhancements

### Announcements:
- [ ] Pin announcements to top of chat
- [ ] Announcement categories (Exam, Assignment, General)
- [ ] Scheduled announcements
- [ ] Announcement templates
- [ ] Rich text formatting
- [ ] Attach files to announcements

### Permissions:
- [ ] Time-based restrictions (e.g., only during class hours)
- [ ] Role-based permissions (TAs can moderate)
- [ ] Mute specific students
- [ ] Slow mode (rate limiting)

### Notifications:
- [ ] Notification preferences per server
- [ ] Quiet hours
- [ ] Notification grouping
- [ ] In-app notification center
- [ ] Email notifications (optional)

---

## 🐛 Troubleshooting

### "Permission denied" when creating announcement:
- Ensure you're logged in as a teacher
- Check if you're the server owner
- Verify RLS policies are applied

### Students can't send messages even when enabled:
- Check `allow_student_messages` in database
- Verify student is a server member
- Check RLS policies on `chat_messages`

### Announcements not showing:
- Refresh the screen
- Check if announcements exist in database
- Verify RLS SELECT policy

---

## 📚 Code Files Modified/Created

### New Files:
- `lib/models/announcement.dart` - Announcement model
- `lib/screens/server/announcements_screen.dart` - Announcements UI
- `backend/03_announcements.sql` - Database schema

### Modified Files:
- `lib/models/chat_server.dart` - Added permission field
- `lib/providers/server_provider.dart` - Added permission toggle
- `lib/screens/server/server_settings_screen.dart` - Added permission UI
- `lib/screens/server/chat_screen.dart` - Added announcements button
- `lib/routes/app_router.dart` - Added announcements route

---

## ✨ Summary

You now have:
1. ✅ **Full announcements system** - Post, view, delete
2. ✅ **Chat permission control** - Restrict student messages
3. ✅ **Beautiful UI** - Professional, intuitive interface
4. ⏳ **Push notification infrastructure** - Ready for Firebase integration

**Next recommended action**: Set up Firebase Cloud Messaging to enable real-time push notifications!
