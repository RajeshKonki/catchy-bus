import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, telugu }

class AppStrings {
  final AppLanguage language;
  AppStrings(this.language);

  static final translations = {
    AppLanguage.english: {
      'tracking_on': 'TRACKING ON',
      'tracking_off': 'TRACKING OFF',
      'cancel_trip': 'Cancel Trip',
      'total': 'Total',
      'boarded': 'Boarded',
      'pending': 'Pending',
      'reached': 'Reached',
      'on_time': 'On Time',
      'late': 'late',
      'min': 'min',
      'approaching': 'Approaching',
      'next_stop': 'Next Stop',
      'skip': 'Skip',
      'mark_attendance': 'Mark Attendance',
      'trip_completed': 'Trip Completed',
      'end_trip': 'End Trip',
      'start_return_trip': 'Start Return Trip',
      'select_route': 'Select Your Route',
      'start_trip': 'Start Trip',
      'distance': 'Distance',
      'duration': 'Duration',
      'warning_distance': 'Warning: You are {dist} from {stop}. Please ensure you are at the correct stop.',
      'language': 'Language',
      'select_language': 'Select Language',
      'your_route': 'YOUR ROUTE',
      'initializing': 'Initializing route...',
      'retry': 'Retry',
      'bus_number': 'Bus Number',
      'contact': 'Contact',
      'driver_id': 'Driver ID',
      'resume_trip': 'Resume Active Trip',
      'start_trip_now': 'Start Trip Now',
      'select_route_hint': 'Select one of the assigned routes to begin tracking.',
      'loading_routes': 'Loading routes...',
      'select_direction': 'Select Direction',
      'direction_hint': 'Choose your journey direction to start tracking.',
      'forward_trip': 'Forward Trip',
      'return_trip': 'Return Trip',
      'too_far': 'Too Far From Start',
      'geofence_error': 'Warning: You are too far from the starting point of this route.',
      'geofence_dist_info': 'Distance: {dist}',
      'skip_stop': 'Skip Stop',
      'skip_stop_hint': 'Please select a reason for skipping this stop. Students at this stop will be notified.',
      'reason_no_student': 'No Student at this Stop',
      'reason_road_accident': 'Road Accident / Blockage',
      'reason_traffic': 'Traffic Congestion',
      'reason_weather': 'Weather Conditions',
      'reason_emergency': 'Emergency Situation',
      'reason_other': 'Other (Specify)',
      'close': 'Close',
      'cancel_trip_hint': 'This will cancel the entire trip and notify all students. Please select a reason.',
      'reason_breakdown': 'Vehicle Breakdown',
      'reason_medical': 'Driver Medical Emergency',
      'reason_mechanical': 'Fuel / Mechanical Issue',
      'active_trip': 'Active Trip',
      'search_student_hint': 'Search by student or stop...',
      'no_results': 'No matching results',
      'no_students': 'No students found',
      'search_no_results_hint': "Try checking the student's name spelling or stop location.",
      'no_students_hint': "No students are currently tracked for this category.",
      'attendance': 'Attendance',
      'scan_qr': 'Scan QR',
      'added_to_attendance': 'added to attendance',
      'no_students_at_stop': 'No students assigned to this stop',
      'attendance_marked_at': 'Attendance marked and stop recorded at',
      'save': 'Save',
      'trip_completed_hint': 'You have completed all stops on this route. Would you like to end the trip?',
      'total_stops': 'Total Stops',
      'completed': 'Completed',
      'skipped': 'Skipped',
      'total_students': 'Total Students',
      'onboarded': 'Onboarded',
      'absent': 'Absent',
      'return_trip_hint': 'This will start a reverse trip, picking up students from the destination back to their home stops in reverse order.\n\nContinue?',
      'review_trip': 'Review Trip',
      'trip_review': 'Trip Review',
      'trip_review_hint': 'Please share your experience or any issues encountered during this trip.',
      'feedback_hint': 'Your feedback here...',
      'enter_review_error': 'Please enter your review content',
      'review_success': 'Review submitted successfully',
      'submit': 'Submit',
      'warning': 'Warning',
      'far_from_stop': 'Warning: You are {distance} from {stop}. Please ensure you are at the correct stop.',
      'bus_approaching': 'Bus Approaching',
      'min_late': 'min late',
      'boarded_students': 'Boarded Students',
      'pending_students': 'Pending Students',
      'scan_student_qr': 'Scan Student QR',
      'scan_qr_hint': 'Ask the student to show their\nattendance QR code',
      'processing': 'Processing...',
      'position_qr_hint': 'Position the QR code within the frame',
      'invalid_qr': 'Invalid QR code. Please scan a student attendance QR.',
      'arrived': 'Arrived',
      'upcoming': 'Upcoming',
      'students': 'Students',
      'exit_app_title': 'Exit Application?',
      'exit_app_message': 'An active trip is running. Do you want to close the app? Background tracking will continue.',
      'exit': 'Exit',
      'cancel': 'Cancel',
      'too_far_to_end_title': 'Too Far to End',
      'too_far_to_end': 'You are too far ({dist}) from the destination. You must be within 200m to end the trip.',
    },
    AppLanguage.telugu: {
      'tracking_on': 'ట్రాకింగ్ ఆన్',
      'tracking_off': 'ట్రాకింగ్ ఆఫ్',
      'cancel_trip': 'ట్రిప్ రద్దు చేయండి',
      'total': 'మొత్తం',
      'boarded': 'బస్సు ఎక్కారు',
      'pending': 'పెండింగ్',
      'reached': 'చేరుకున్నారు',
      'on_time': 'సమయానికి',
      'late': 'ఆలస్యం',
      'min': 'నిమిషాలు',
      'approaching': 'వస్తున్నారు',
      'next_stop': 'తదుపరి స్టాప్',
      'skip': 'దాటవేయి',
      'mark_attendance': 'అటెండెన్స్ తీసుకోండి',
      'trip_completed': 'ట్రిప్ పూర్తయింది',
      'end_trip': 'ట్రిప్ ముగించు',
      'start_return_trip': 'తిరుగు ప్రయాణం ప్రారంభించు',
      'select_route': 'మీ రూట్‌ను ఎంచుకోండి',
      'start_trip': 'ట్రిప్ ప్రారంభించండి',
      'distance': 'దూరం',
      'duration': 'సమయం',
      'warning_distance': 'హెచ్చరిక: మీరు {stop} నుండి {dist} దూరంలో ఉన్నారు. దయచేసి మీరు సరైన స్టాప్‌లో ఉన్నారని నిర్ధారించుకోండి.',
      'language': 'భాష',
      'select_language': 'భాషను ఎంచుకోండి',
      'your_route': 'మీ రూట్',
      'initializing': 'రూట్‌ను సిద్ధం చేస్తున్నాము...',
      'retry': 'మళ్ళీ ప్రయత్నికండి',
      'bus_number': 'బస్సు నంబర్',
      'contact': 'సంప్రదించండి',
      'driver_id': 'డ్రైవర్ ఐడి',
      'resume_trip': 'ట్రిప్‌ను కొనసాగించండి',
      'start_trip_now': 'ట్రిప్ ప్రారంభించండి',
      'select_route_hint': 'ట్రాకింగ్ ప్రారంభించడానికి కేటాయించిన రూట్లలో ఒకదాన్ని ఎంచుకోండి.',
      'loading_routes': 'రూట్లను లోడ్ చేస్తోంది...',
      'select_direction': 'దిశను ఎంచుకోండి',
      'direction_hint': 'ట్రాకింగ్ ప్రారంభించడానికి మీ ప్రయాణ దిశను ఎంచుకోండి.',
      'forward_trip': 'వెళ్ళే ప్రయాణం',
      'return_trip': 'తిరిగి వచ్చే ప్రయాణం',
      'too_far': 'ప్రారంభ స్థానానికి చాలా దూరంలో ఉన్నారు',
      'geofence_error': 'హెచ్చరిక: మీరు ఈ రూట్ ప్రారంభ స్థానానికి {dist} దూరంలో ఉన్నారు.',
      'geofence_dist_info': 'దూరం: {dist}',
      'skip_stop': 'స్టాప్‌ను దాటవేయి',
      'skip_stop_hint': 'ఈ స్టాప్‌ను దాటవేయడానికి కారణాన్ని ఎంచుకోండి. ఈ స్టాప్‌లోని విద్యార్థులకు సమాచారం పంపబడుతుంది.',
      'reason_no_student': 'ఈ స్టాప్‌లో విద్యార్థులు లేరు',
      'reason_road_accident': 'రోడ్డు ప్రమాదం / అడ్డంకి',
      'reason_traffic': 'ట్రాఫిక్ జామ్',
      'reason_weather': 'వాతావరణం సరిగ్గా లేదు',
      'reason_emergency': 'అత్యవసర పరిస్థితి',
      'reason_other': 'ఇతర కారణం (తెలియజేయండి)',
      'close': 'మూసివేయి',
      'cancel_trip_hint': 'ఇది మొత్తం ట్రిప్‌ను రద్దు చేస్తుంది మరియు విద్యార్థులందరికీ సమాచారం పంపుతుంది. దయచేసి కారణాన్ని ఎంచుకోండి.',
      'reason_breakdown': 'వాహనం మరమ్మత్తు',
      'reason_medical': 'డ్రైవర్ ఆరోగ్య పరిస్థితి',
      'reason_mechanical': 'ఇంధనం / మెకానికల్ సమస్య',
      'active_trip': 'ప్రస్తుత ట్రిప్',
      'search_student_hint': 'విద్యార్థి లేదా స్టాప్ పేరుతో వెతకండి...',
      'no_results': 'ఫలితాలు లేవు',
      'no_students': 'విద్యార్థులు కనిపించలేదు',
      'search_no_results_hint': "విద్యార్థి పేరు లేదా స్టాప్ పేరు సరిగ్గా ఉందో లేదో చూడండి.",
      'no_students_hint': "ఈ కేటగిరీలో విద్యార్థులు ఎవరూ లేరు.",
      'attendance': 'అటెండెన్స్',
      'scan_qr': 'QR స్కాన్',
      'added_to_attendance': 'అటెండెన్స్‌లో చేర్చబడ్డారు',
      'no_students_at_stop': 'ఈ స్టాప్‌లో విద్యార్థులు ఎవరూ లేరు',
      'attendance_marked_at': 'అటెండెన్స్ తీసుకోబడింది మరియు స్టాప్ నమోదు చేయబడింది:',
      'save': 'సేవ్ చేయండి',
      'trip_completed_hint': 'మీరు ఈ రూట్‌లోని అన్ని స్టాప్‌లను పూర్తి చేశారు. మీరు ట్రిప్‌ను ముగించాలనుకుంటున్నారా?',
      'total_stops': 'మొత్తం స్టాప్‌లు',
      'completed': 'పూర్తయినవి',
      'skipped': 'దాటవేసినవి',
      'total_students': 'మొత్తం విద్యార్థులు',
      'onboarded': 'బస్సు ఎక్కినవారు',
      'absent': 'రానివారు',
      'return_trip_hint': 'ఇది తిరుగు ప్రయాణాన్ని ప్రారంభిస్తుంది, గమ్యస్థానం నుండి విద్యార్థులను వారి ఇంటి స్టాప్‌ల వద్ద వదులుకుంటూ వెళ్తుంది.\n\nకొనసాగించాలా?',
      'review_trip': 'ట్రిప్ సమీక్ష',
      'trip_review': 'ట్రిప్ సమీక్ష',
      'trip_review_hint': 'దయచేసి మీ అనుభవాన్ని లేదా ఈ ట్రిప్ సమయంలో ఎదురైన సమస్యలను పంచుకోండి.',
      'feedback_hint': 'మీ అభిప్రాయాన్ని ఇక్కడ తెలపండి...',
      'enter_review_error': 'దయచేసి మీ సమీక్షను నమోదు చేయండి',
      'review_success': 'సమీక్ష విజయవంతంగా పంపబడింది',
      'submit': 'సమర్పించండి',
      'warning': 'హెచ్చరిక',
      'far_from_stop': 'హెచ్చరిక: మీరు {stop} నుండి {distance} దూరంలో ఉన్నారు. దయచేసి మీరు సరైన స్టాప్‌లో ఉన్నారని నిర్ధారించుకోండి.',
      'bus_approaching': 'బస్సు వస్తోంది',
      'min_late': 'నిమిషాల ఆలస్యం',
      'boarded_students': 'బస్సు ఎక్కిన విద్యార్థులు',
      'pending_students': 'పెండింగ్ విద్యార్థులు',
      'scan_student_qr': 'విద్యార్థి QR స్కాన్ చేయండి',
      'scan_qr_hint': 'విద్యార్థిని వారి అటెండెన్స్ QR కోడ్\nచూపమని అడగండి',
      'processing': 'ప్రాసెస్ చేస్తున్నాము...',
      'position_qr_hint': 'QR కోడ్‌ను ఫ్రేమ్‌లో ఉంచండి',
      'invalid_qr': 'చెల్లని QR కోడ్. దయచేసి విద్యార్థి అటెండెన్స్ QRను స్కాన్ చేయండి.',
      'arrived': 'చేరుకున్నారు',
      'upcoming': 'రాబోయే స్టాప్',
      'students': 'విద్యార్థులు',
      'exit_app_title': 'అప్లికేషన్ నుండి నిష్క్రమించాలా?',
      'exit_app_message': 'యాక్టివ్ ట్రిప్ నడుస్తోంది. మీరు యాప్‌ని మూసివేయాలనుకుంటున్నారా? బ్యాక్‌గ్రౌండ్ ట్రాకింగ్ కొనసాగుతుంది.',
      'exit': 'నిష్క్రమించు',
      'cancel': 'రద్దు చేయి',
      'too_far_to_end_title': 'ట్రిప్ ముగించడానికి చాలా దూరంలో ఉన్నారు',
      'too_far_to_end': 'మీరు గమ్యస్థానం నుండి చాలా దూరంలో ({dist}) ఉన్నారు. ట్రిప్ ముగించడానికి మీరు 200 మీటర్ల లోపు ఉండాలి.',
    },
  };

  String get(String key) {
    return translations[language]?[key] ??
        translations[AppLanguage.english]?[key] ??
        key; // safe fallback: return the key itself if missing
  }
}

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.english) {
    _loadLanguage();
  }

  static const _key = 'selected_language';

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langIndex = prefs.getInt(_key);
    if (langIndex != null) {
      state = AppLanguage.values[langIndex];
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, language.index);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(languageProvider);
  return AppStrings(lang);
});
