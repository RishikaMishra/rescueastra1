import 'package:flutter/material.dart';

class SakhiChatbot extends StatefulWidget {
  const SakhiChatbot({super.key});

  @override
  State<SakhiChatbot> createState() => _SakhiChatbotState();
}

class _SakhiChatbotState extends State<SakhiChatbot> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Welcome message
    _addMessage(ChatMessage(
      text: "👋 Namaste! I'm Sakhi, your personal safety assistant.\n\n"
          "I'm here to help you with:\n"
          "🛡️ RescueAstra app features\n"
          "🚨 Emergency procedures\n"
          "💪 Women safety tips\n"
          "🔒 Privacy & security info\n"
          "🥋 Self-defense guidance\n\n"
          "How can I assist you today? Feel free to ask me anything! 😊",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    _addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _messageController.clear();
    _showTypingIndicator();

    // Simulate response delay
    Future.delayed(Duration(milliseconds: 1500), () {
      _hideTypingIndicator();
      _addMessage(ChatMessage(
        text: _generateResponse(text),
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _showTypingIndicator() {
    setState(() {
      _isTyping = true;
    });
  }

  void _hideTypingIndicator() {
    setState(() {
      _isTyping = false;
    });
  }

  String _generateResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    // Greet back if user greets
    if (message.contains('hello') || message.contains('hi') || message.contains('namaste') || message.contains('hey') || message.contains('good morning') || message.contains('good evening') || message.contains('good afternoon')) {
      return "🌸 Namaste, friend!\n\nIt's always a joy to hear from you. I'm Sakhi—think of me as your caring, feminist buddy who's always here to listen, support, and empower you. 💜\n\nHow can I help or cheer you on today?";
    }

    // App Information
    if (message.contains('app') || message.contains('rescueastra') || message.contains('about')) {
      return "🛡️ RescueAstra - Your Complete Safety Companion\n\n"
          "🚨 **Emergency Features:**\n"
          "• One-tap SOS with instant alerts\n"
          "• Auto-location sharing to emergency contacts\n"
          "• Audio/video evidence recording\n"
          "• Direct emergency service calls\n\n"
          "📱 **Smart Features:**\n"
          "• AI-powered Sakhi assistant (that's me—your digital friend!)\n"
          "• Gender detection for enhanced security\n"
          "• Hotspot area mapping\n"
          "• Live monitoring capabilities\n"
          "• Gesture-based SOS activation\n\n"
          "🗺️ **Services:**\n"
          "• Emergency services locator\n"
          "• Hospital & police station finder\n"
          "• Safe route suggestions\n\n"
          "Built with ❤️ for women's safety in India! And remember, I'm always here to chat, support, and cheer you on.";
    }

    // SOS Information
    if (message.contains('sos') || message.contains('emergency') || message.contains('help')) {
      return "🚨 **SOS Emergency System - Your Lifeline**\n\n"
          "🔴 **How to Activate:**\n"
          "• Press & hold the red SOS button for 3 seconds\n"
          "• Use gesture activation (shake phone 3 times)\n"
          "• Voice command: 'Hey Sakhi, Emergency!'\n\n"
          "⚡ **Instant Actions:**\n"
          "• GPS location shared immediately\n"
          "• SMS alerts to all emergency contacts\n"
          "• Auto-call to 112 (emergency services)\n"
          "• Audio recording starts automatically\n"
          "• Video recording (if camera available)\n"
          "• Live location tracking activated\n\n"
          "☁️ **Secure Backup:**\n"
          "• All evidence uploaded to encrypted cloud\n"
          "• Accessible by authorities if needed\n"
          "• Cannot be deleted by unauthorized users\n\n"
          "🌟 **Available 24/7 on every screen!**";
    }

    // Safety Tips
    if (message.contains('safety') || message.contains('tips') || message.contains('secure')) {
      return "🛡️ **Essential Women Safety Tips**\n\n"
          "🏠 **At Home:**\n"
          "• Install good locks & security systems\n"
          "• Don't open doors to strangers\n"
          "• Keep emergency numbers handy\n"
          "• Inform neighbors about your routine\n\n"
          "🚶‍♀️ **While Walking:**\n"
          "• Stay alert, avoid distractions\n"
          "• Walk confidently in well-lit areas\n"
          "• Trust your instincts about people/places\n"
          "• Carry a whistle or personal alarm\n"
          "• Share live location with trusted contacts\n\n"
          "🚗 **Transportation:**\n"
          "• Verify driver details before boarding\n"
          "• Sit behind the driver in cabs\n"
          "• Share trip details with family\n"
          "• Keep RescueAstra SOS ready\n\n"
          "📱 **Digital Safety:**\n"
          "• Keep phone charged (carry power bank)\n"
          "• Enable location services\n"
          "• Don't share personal info online\n"
          "• Use RescueAstra's safety features\n\n"
          "💪 **Remember: Prevention is better than cure!**";
    }

    // Features
    if (message.contains('feature') || message.contains('what can') || message.contains('services')) {
      return "✨ RescueAstra Features:\n\n"
          "🚨 Emergency SOS - Instant help activation\n"
          "📍 Location Services - Real-time tracking\n"
          "👥 Trusted Contacts - Emergency contact management\n"
          "🎥 Evidence Recording - Audio/video capture\n"
          "🗺️ Safety Map - Find nearby help centers\n"
          "☁️ Cloud Backup - Secure data storage\n"
          "🔔 Smart Alerts - Automatic notifications\n\n"
          "All designed for your safety! 🛡️";
    }

    // How to use
    if (message.contains('how') || message.contains('use') || message.contains('start')) {
      return "📱 How to use RescueAstra:\n\n"
          "1️⃣ Set up emergency contacts in Settings\n"
          "2️⃣ Allow location permissions\n"
          "3️⃣ Add trusted contacts\n"
          "4️⃣ Familiarize with SOS button location\n"
          "5️⃣ Test the system once\n\n"
          "🚨 In emergency: Press SOS button\n"
          "📍 For services: Use the Services tab\n"
          "👥 For contacts: Use Contacts tab\n\n"
          "Need help with any specific feature?";
    }

    // Emergency numbers
    if (message.contains('number') || message.contains('call') || message.contains('police')) {
      return "📞 **Emergency Numbers - Save These Now!**\n\n"
          "🚨 **Primary Emergency:**\n"
          "• 112 - National Emergency (24/7)\n"
          "• 100 - Police Control Room\n"
          "• 108 - Ambulance Services\n"
          "• 101 - Fire Department\n\n"
          "👩 **Women-Specific Helplines:**\n"
          "• 1091 - Women Helpline (24/7)\n"
          "• 181 - Women in Distress\n"
          "• 1098 - Child Helpline\n"
          "• 7827170170 - Women Safety (Delhi)\n\n"
          "🏥 **Medical Emergency:**\n"
          "• 102 - Medical Emergency\n"
          "• 1075 - Disaster Management\n\n"
          "🚗 **Travel & Transport:**\n"
          "• 1073 - Road Accident Emergency\n"
          "• 139 - Railway Enquiry\n"
          "• 1512 - Railway Security\n\n"
          "💡 **Pro Tip:** RescueAstra auto-dials these numbers during SOS!\n"
          "You can also add custom emergency contacts in settings.";
    }

    // Location and tracking
    if (message.contains('location') || message.contains('track') || message.contains('gps')) {
      return "📍 Location & Tracking:\n\n"
          "• Real-time GPS tracking\n"
          "• Automatic location sharing during SOS\n"
          "• Google Maps integration\n"
          "• Location history (emergency only)\n"
          "• Offline location caching\n\n"
          "🔒 Privacy: Location is only shared during emergencies or when you choose to share it.";
    }

    // Privacy and security
    if (message.contains('privacy') || message.contains('secure') || message.contains('data')) {
      return "🔒 Privacy & Security:\n\n"
          "• End-to-end encryption\n"
          "• Secure cloud storage\n"
          "• No data sharing with third parties\n"
          "• Location shared only during emergencies\n"
          "• Audio/video stored securely\n"
          "• You control your data\n\n"
          "Your privacy and safety are our top priorities! 🛡️";
    }

    // Self-defense
    if (message.contains('defense') || message.contains('protect') || message.contains('fight') || message.contains('martial arts')) {
      return "🥋 **Self-Defense & Personal Protection**\n\n"
          "🧠 **Mental Preparation:**\n"
          "• Stay alert and confident\n"
          "• Trust your instincts always\n"
          "• Practice situational awareness\n"
          "• Avoid isolated areas\n\n"
          "👊 **Basic Self-Defense Moves:**\n"
          "• Palm strike to nose/chin\n"
          "• Knee kick to groin area\n"
          "• Elbow strike to ribs/face\n"
          "• Stomp on attacker's foot\n"
          "• Eye poke with fingers\n\n"
          "🎯 **Target Vulnerable Areas:**\n"
          "• Eyes, nose, throat\n"
          "• Solar plexus, ribs\n"
          "• Groin, knees, shins\n"
          "• Instep of foot\n\n"
          "🔊 **Make Noise:**\n"
          "• Scream 'FIRE!' (gets more attention)\n"
          "• Use whistle or personal alarm\n"
          "• Activate RescueAstra SOS\n\n"
          "🏃‍♀️ **Escape Strategy:**\n"
          "• Run to crowded, well-lit areas\n"
          "• Don't fight if you can escape\n"
          "• Your life is more valuable than possessions\n\n"
          "📚 **Learn More:**\n"
          "• Join self-defense classes\n"
          "• Practice with friends/family\n"
          "• Watch online tutorials\n\n"
          "💪 **Remember: The best self-defense is prevention!**";
    }

    // Dating and relationship safety
    if (message.contains('dating') || message.contains('relationship') || message.contains('boyfriend') || message.contains('partner')) {
      return "💕 **Dating & Relationship Safety**\n\n"
          "🔍 **Before Meeting:**\n"
          "• Meet in public places first\n"
          "• Tell friends about your plans\n"
          "• Share location with trusted contacts\n"
          "• Research the person online\n"
          "• Video call before meeting\n\n"
          "📍 **During Dates:**\n"
          "• Choose public venues\n"
          "• Arrange your own transportation\n"
          "• Don't leave drinks unattended\n"
          "• Keep RescueAstra SOS ready\n"
          "• Trust your gut feelings\n\n"
          "🚩 **Red Flags to Watch:**\n"
          "• Pressures you for personal info\n"
          "• Wants to meet in private immediately\n"
          "• Gets angry when you set boundaries\n"
          "• Controls or monitors your activities\n"
          "• Isolates you from friends/family\n\n"
          "💔 **Relationship Violence:**\n"
          "• Physical, emotional, or sexual abuse\n"
          "• Controlling behavior\n"
          "• Threats and intimidation\n"
          "• Financial control\n\n"
          "📞 **Get Help:**\n"
          "• 1091 - Women Helpline\n"
          "• Use RescueAstra SOS\n"
          "• Contact local women's shelter\n\n"
          "💪 **You deserve respect and safety in all relationships!**";
    }

    // Night safety
    if (message.contains('night') || message.contains('dark') || message.contains('late') || message.contains('evening')) {
      return "🌙 **Night Safety Guidelines**\n\n"
          "🚶‍♀️ **Walking at Night:**\n"
          "• Stick to well-lit, busy streets\n"
          "• Walk confidently and purposefully\n"
          "• Avoid shortcuts through dark areas\n"
          "• Keep phone charged and accessible\n"
          "• Share live location with family\n\n"
          "🚗 **Transportation:**\n"
          "• Book verified cabs/autos\n"
          "• Share trip details with contacts\n"
          "• Sit behind driver in cabs\n"
          "• Keep emergency contacts ready\n"
          "• Use RescueAstra's tracking feature\n\n"
          "🏠 **Returning Home:**\n"
          "• Have keys ready before reaching door\n"
          "• Check surroundings before entering\n"
          "• Let someone know you've reached safely\n"
          "• Keep porch lights on\n\n"
          "👥 **With Friends:**\n"
          "• Stay together in groups\n"
          "• Don't leave anyone alone\n"
          "• Designate a sober friend\n"
          "• Plan safe transportation home\n\n"
          "🚨 **Emergency Preparedness:**\n"
          "• Keep RescueAstra SOS accessible\n"
          "• Memorize emergency numbers\n"
          "• Carry whistle or personal alarm\n"
          "• Trust your instincts\n\n"
          "🌟 **Night doesn't have to be scary with proper precautions!**";
    }

    // Workplace safety
    if (message.contains('work') || message.contains('office') || message.contains('job')) {
      return "�� Workplace Safety:\n\n"
          "• Report harassment immediately\n"
          "• Document incidents with dates/details\n"
          "• Know your company's policies\n"
          "• Seek support from HR or trusted colleagues\n"
          "• Keep evidence of inappropriate behavior\n"
          "• Know your legal rights\n"
          "• Use RescueAstra if you feel threatened\n\n"
          "You deserve a safe work environment! 💼";
    }

    // Travel safety
    if (message.contains('travel') || message.contains('trip') || message.contains('journey')) {
      return "✈️ Travel Safety Tips:\n\n"
          "• Share your itinerary with trusted contacts\n"
          "• Keep emergency contacts updated\n"
          "• Research your destination\n"
          "• Stay in well-reviewed accommodations\n"
          "• Avoid isolated areas, especially at night\n"
          "• Keep copies of important documents\n"
          "• Use RescueAstra's location sharing\n\n"
          "Safe travels! 🌍";
    }

    // Mental health
    if (message.contains('stress') || message.contains('anxiety') || message.contains('mental')) {
      return "🧠 **Mental Health & Emotional Support**\n\n"
          "🌱 **Self-Care Strategies:**\n"
          "• Practice deep breathing exercises\n"
          "• Maintain a daily routine\n"
          "• Exercise regularly (even 10 mins helps)\n"
          "• Get adequate sleep (7-8 hours)\n"
          "• Limit social media exposure\n\n"
          "💬 **Seek Support:**\n"
          "• Talk to trusted friends/family\n"
          "• Consider professional counseling\n"
          "• Join support groups\n"
          "• Use meditation apps\n\n"
          "📞 **Helplines:**\n"
          "• 1800-599-0019 - Mental Health\n"
          "• 9152987821 - COOJ Mental Health\n"
          "• 080-46110007 - Sneha Suicide Prevention\n\n"
          "🚨 **Crisis Support:**\n"
          "• If you're in immediate danger, use RescueAstra SOS\n"
          "• For suicidal thoughts: Call 9152987821\n\n"
          "💚 **Remember: Seeking help is a sign of strength, not weakness!**";
    }

    // Cybersecurity and online safety
    if (message.contains('cyber') || message.contains('online') || message.contains('internet') || message.contains('social media')) {
      return "🔐 **Cybersecurity & Online Safety**\n\n"
          "📱 **Social Media Safety:**\n"
          "• Keep profiles private\n"
          "• Don't share location in real-time\n"
          "• Be cautious with friend requests\n"
          "• Report harassment immediately\n"
          "• Don't share personal information\n\n"
          "💻 **Digital Security:**\n"
          "• Use strong, unique passwords\n"
          "• Enable two-factor authentication\n"
          "• Keep apps and OS updated\n"
          "• Don't click suspicious links\n"
          "• Use secure Wi-Fi networks\n\n"
          "🚫 **Avoid These:**\n"
          "• Sharing OTPs or passwords\n"
          "• Meeting online strangers alone\n"
          "• Sharing intimate photos\n"
          "• Using public Wi-Fi for banking\n\n"
          "📞 **Report Cyber Crime:**\n"
          "• 1930 - Cyber Crime Helpline\n"
          "• cybercrime.gov.in - Online reporting\n\n"
          "🛡️ **RescueAstra helps protect your digital footprint too!**";
    }

    // Legal rights and laws
    if (message.contains('legal') || message.contains('law') || message.contains('rights') || message.contains('harassment')) {
      return "⚖️ **Legal Rights & Women Protection Laws**\n\n"
          "📜 **Key Laws Protecting Women:**\n"
          "• Sexual Harassment at Workplace Act, 2013\n"
          "• Domestic Violence Act, 2005\n"
          "• Dowry Prohibition Act, 1961\n"
          "• Criminal Law Amendment Act, 2013\n"
          "• IT Act, 2000 (Cyber crimes)\n\n"
          "🚨 **Your Rights:**\n"
          "• Right to file FIR without delay\n"
          "• Right to free legal aid\n"
          "• Right to privacy during investigation\n"
          "• Right to compensation\n"
          "• Right to protection from accused\n\n"
          "📋 **How to File Complaint:**\n"
          "• Visit nearest police station\n"
          "• File online FIR (some states)\n"
          "• Contact women's helpline 1091\n"
          "• Approach women's commission\n\n"
          "📞 **Legal Aid:**\n"
          "• 15100 - National Legal Services\n"
          "• Contact local legal aid clinic\n\n"
          "💪 **Know your rights, use them fearlessly!**";
    }

    // App troubleshooting and technical help
    if (message.contains('problem') || message.contains('issue') || message.contains('bug') || message.contains('not working') || message.contains('error')) {
      return "🔧 **Technical Support & Troubleshooting**\n\n"
          "📱 **Common Issues & Solutions:**\n\n"
          "🚨 **SOS Button Not Working:**\n"
          "• Check app permissions (Location, Phone, SMS)\n"
          "• Ensure internet connection\n"
          "• Restart the app\n"
          "• Update to latest version\n\n"
          "📍 **Location Not Sharing:**\n"
          "• Enable GPS/Location services\n"
          "• Grant location permission to app\n"
          "• Check if location is turned on in phone settings\n\n"
          "📞 **Emergency Contacts Not Working:**\n"
          "• Verify contact numbers are correct\n"
          "• Check SMS permission\n"
          "• Ensure contacts have valid phone numbers\n\n"
          "🎥 **Recording Issues:**\n"
          "• Grant camera and microphone permissions\n"
          "• Check available storage space\n"
          "• Close other apps using camera\n\n"
          "⚡ **App Performance:**\n"
          "• Clear app cache\n"
          "• Restart your phone\n"
          "• Update the app\n"
          "• Free up phone storage\n\n"
          "📧 **Still having issues?**\n"
          "Contact our support team at support@rescueastra.com\n"
          "We're here to help 24/7! 🌟";
    }

    // First aid and medical emergency
    if (message.contains('first aid') || message.contains('medical') || message.contains('injury') || message.contains('accident')) {
      return "🏥 **First Aid & Medical Emergency Guide**\n\n"
          "🚨 **In Medical Emergency:**\n"
          "1. Call 108 (Ambulance) immediately\n"
          "2. Use RescueAstra SOS for location sharing\n"
          "3. Stay calm and assess the situation\n"
          "4. Provide basic first aid if trained\n\n"
          "🩹 **Basic First Aid:**\n"
          "• **Bleeding:** Apply direct pressure with clean cloth\n"
          "• **Burns:** Cool with running water for 10+ minutes\n"
          "• **Choking:** Heimlich maneuver or back blows\n"
          "• **Unconscious:** Check breathing, place in recovery position\n\n"
          "💊 **Important Info to Share:**\n"
          "• Patient's age and gender\n"
          "• Nature of injury/illness\n"
          "• Current location (RescueAstra shares this)\n"
          "• Any known allergies or medications\n\n"
          "🚫 **Don't:**\n"
          "• Move someone with spinal injury\n"
          "• Give food/water to unconscious person\n"
          "• Leave the person alone\n\n"
          "📞 **Emergency Numbers:**\n"
          "• 108 - Ambulance\n"
          "• 102 - Medical Emergency\n"
          "• Poison Control: 1066\n\n"
          "⚠️ **Remember: RescueAstra can help coordinate emergency response!**";
    }

    // --- Additional User Guide & Safety Coverage ---
    // Hotspot analysis
    if (message.contains('hotspot') || message.contains('area analysis') || message.contains('danger zone')) {
      return "🗺️ **Hotspot Analysis Guide**\n\n"
        "• The Hotspot Analysis page shows high-risk areas based on recent incidents.\n"
        "• Tap on a hotspot to see a detailed report: incident types, threats, gender ratio, and time patterns.\n"
        "• Use this info to avoid unsafe areas and plan safer routes.\n\n"
        "You can also generate demo data for testing!";
    }
    // Incident reporting
    if (message.contains('report') && (message.contains('incident') || message.contains('threat'))) {
      return "📝 **Reporting an Incident or Threat**\n\n"
        "• Go to the Services or SOS tab.\n"
        "• Tap the 'Report Incident' or 'SOS' button.\n"
        "• Fill in details (type, location, description).\n"
        "• Optionally attach audio/video evidence.\n"
        "• Your report will alert your contacts and authorities if needed.\n\n"
        "Always report suspicious activity to help keep everyone safe!";
    }
    // Women safety general
    if (message.contains('women') && (message.contains('safety') || message.contains('secure') || message.contains('protection'))) {
      return "👩‍🦰 **Women Safety Guidance**\n\n"
        "• Always keep your phone charged and RescueAstra app accessible.\n"
        "• Share your live location with trusted contacts when traveling.\n"
        "• Use the SOS button in emergencies—help will be alerted instantly.\n"
        "• Trust your instincts and avoid isolated areas, especially at night.\n"
        "• Save emergency numbers and helplines in your contacts.\n\n"
        "If you need more specific advice, just ask! And remember, your safety and confidence matter most. I'm always here for you, like a true friend! 💜";
    }
    // App navigation
    if (message.contains('navigate') || message.contains('where is') || message.contains('find') || message.contains('menu')) {
      return "🗂️ **App Navigation Help**\n\n"
        "• Home: Main dashboard and quick access\n"
        "• Services: Emergency, contacts, and safety tools\n"
        "• Hotspot Analysis: Map of high-risk areas\n"
        "• Profile: Your info and settings\n"
        "• Sakhi: Chatbot help anytime\n\n"
        "Use the bottom navigation bar or menu to switch between sections.";
    }
    // If user asks for help or guide
    if (message.contains('guide') || message.contains('manual') || message.contains('tutorial') || message.contains('how do i')) {
      return "📖 **User Guide**\n\n"
        "• For a quick start, set up your emergency contacts and test the SOS button.\n"
        "• Use the Services tab for reporting, contacts, and settings.\n"
        "• The Hotspot Analysis page helps you avoid unsafe areas.\n"
        "• For any feature, just ask me or check the Help section in the app menu!";
    }
    // --- End Additional Coverage ---

    // --- Fallback & Apology ---
    // If no answer found, apologize and suggest alternatives
    final fallbackResponses = [
      "Oh no, I couldn't find the perfect answer for you this time. 😔\n\nBut I'm always here to help—maybe try asking in a different way, or tell me more about what you need?\n\nAnd remember, you're never alone—check the Help section or reach out to support@rescueastra.com if you want to talk to a real person! 💜",
      "Oops, I don't have info on that yet, but I'm learning every day!\n\nIf you want, we can explore the app together or you can ask me about safety, features, or anything on your mind.\n\nAnd if it's urgent, please use the SOS button or call 112. Stay safe, friend! 🌷",
      "I'm still growing my knowledge, just like a good friend would!\n\nTry asking me about RescueAstra, women safety, or anything you care about.\n\nIf you ever feel stuck, I'm here to listen and help however I can. 💪"
    ];
    // If nothing matched above, return a random fallback
    return fallbackResponses[DateTime.now().second % fallbackResponses.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[700]!, Colors.purple[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Text(
                          '👩‍💼',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sakhi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Your Safety Assistant',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask Sakhi anything...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () => _sendMessage(_messageController.text),
                  backgroundColor: Colors.purple[700],
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.purple[100],
              child: Text('👩‍💼', style: TextStyle(fontSize: 16)),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.purple[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, size: 16, color: Colors.blue[700]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.purple[100],
            child: Text('👩‍💼', style: TextStyle(fontSize: 16)),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sakhi is typing'),
                SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[700]!),
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

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
