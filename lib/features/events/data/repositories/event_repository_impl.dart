import 'dart:typed_data';

import 'package:coexist_app_portal/core/constants/app_constants.dart';
import 'package:coexist_app_portal/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/event_model.dart';
import '../../domain/models/event_registration_model.dart';
import '../../domain/models/registered_user_model.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/repositories/event_repository.dart';

/// Implementation of EventRepository using Supabase
class EventRepositoryImpl implements EventRepository {
  final SupabaseClient _supabaseClient;
  final ApiClient _apiClient;
  static const String _eventsTable = 'events';
  static const String _registrationsTable = 'event_registrations';
  static const String _usersTable = 'users';

  EventRepositoryImpl({
    required SupabaseClient supabaseClient,
    required ApiClient apiClient,
  }) : _supabaseClient = supabaseClient,
       _apiClient = apiClient;

  @override
  Future<List<EventModel>> getEvents() async {
    print('🔍 EVENTS: Fetching all events');
    try {
      // Fetch all approved events
      final eventsResponse = await _supabaseClient
          .from(_eventsTable)
          .select()
          .order('date', ascending: true);

      print('✅ EVENTS: Fetched ${eventsResponse} events');

      // Get current user ID
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        // If no user is logged in, return events without registration status
        return eventsResponse
            .map((data) => EventModel.fromSupabase(data))
            .toList();
      }

      // Fetch user's registrations
      final registrationsResponse = await _supabaseClient
          .from(_registrationsTable)
          .select('event_id')
          .eq('user_id', userId);

      // Extract event IDs the user is registered for
      final registeredEventIds = registrationsResponse
          .map((data) => data['event_id'] as String)
          .toSet();

      // Map events with registration status
      return eventsResponse.map((data) {
        final eventId = data['id'] as String;
        final isRegistered = registeredEventIds.contains(eventId);
        return EventModel.fromSupabase(data, isRegistered: isRegistered);
      }).toList();
    } catch (e) {
      print('❌ EVENTS ERROR: ${e.toString()}');
      return [];
    }
  }

  @override
  Future<List<EventModel>> getMyCreatedEvents() async {
    print('🔍 EVENTS: Fetching events created by current user');
    try {
      // Get current user ID
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        print('❌ EVENTS: No authenticated user found');
        return [];
      }

      // Fetch all events created by the user (regardless of status)
      final response = await _supabaseClient
          .from(_eventsTable)
          .select()
          .eq('created_by', userId)
          .order('date', ascending: true);

      print('✅ EVENTS: Fetched ${response.length} created events');
      return response.map((data) => EventModel.fromSupabase(data)).toList();
    } catch (e) {
      print('❌ EVENTS ERROR: ${e.toString()}');
      return [];
    }
  }

  @override
  Future<List<EventModel>> getMyRegisteredEvents() async {
    print('🔍 EVENTS: Fetching events user is registered for');
    try {
      // Get current user ID
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        print('❌ EVENTS: No authenticated user found');
        return [];
      }

      // Fetch registrations for the user
      final registrationsResponse = await _supabaseClient
          .from(_registrationsTable)
          .select('event_id')
          .eq('user_id', userId);

      // Extract event IDs
      final eventIds = registrationsResponse
          .map((data) => data['event_id'] as String)
          .toList();

      if (eventIds.isEmpty) {
        print('✅ EVENTS: User is not registered for any events');
        return [];
      }

      // Fetch events by IDs
      final eventsResponse = await _supabaseClient
          .from(_eventsTable)
          .select()
          .inFilter('id', eventIds)
          .order('date', ascending: true);

      print('✅ EVENTS: Fetched ${eventsResponse.length} registered events');
      return eventsResponse
          .map((data) => EventModel.fromSupabase(data, isRegistered: true))
          .toList();
    } catch (e) {
      print('❌ EVENTS ERROR: ${e.toString()}');
      return [];
    }
  }

  @override
  Future<EventModel?> createEvent(EventModel event, Uint8List bytes) async {
    print('🔍 EVENTS: Creating new event: ${event.title}');
    try {
      // Get current user ID
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        print('❌ EVENTS: No authenticated user found');
        return null;
      }
      final fileName = "event_${DateTime.now().millisecondsSinceEpoch}.png";

      // 1️⃣ Upload binary file to bucket: events
      await _supabaseClient.storage
          .from("events")
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: "image/png"),
          );

      // 2️⃣ Generate signed URL (valid for 10 years)
      final tenYearsSeconds = 315360000;

      final signedUrl = await _supabaseClient.storage
          .from("events")
          .createSignedUrl(fileName, tenYearsSeconds);
      final updatedEvent = event.copyWith(imageUrl: signedUrl);
      // Create event with current user as creator
      final eventData = {...updatedEvent.toSupabase(), 'created_by': userId};

      // Remove any null or empty values that might cause issues
      eventData.removeWhere(
        (key, value) => value == null || (value is String && value.isEmpty),
      );

      // Ensure date is properly formatted

      final response = await _supabaseClient
          .from(_eventsTable)
          .insert(eventData)
          .select()
          .single();

      print('✅ EVENTS: Event created successfully');
      return EventModel.fromSupabase(response);
    } catch (e) {
      print('❌ EVENTS ERROR: ${e.toString()}');
      return null;
    }
  }

  @override
  Future<EventModel?> updateEvent(EventModel event, Uint8List? bytes) async {
    print('🔍 EVENTS: Updating event: ${event.id}');
    try {
      if (event.imageUrl == "Image selected") {
        final fileName = "event_${DateTime.now().millisecondsSinceEpoch}.png";

        // 1️⃣ Upload binary file to bucket: events
        await _supabaseClient.storage
            .from("events")
            .uploadBinary(
              fileName,
              bytes!,
              fileOptions: const FileOptions(contentType: "image/png"),
            );

        // 2️⃣ Generate signed URL (valid for 10 years)
        final tenYearsSeconds = 315360000;

        final signedUrl = await _supabaseClient.storage
            .from("events")
            .createSignedUrl(fileName, tenYearsSeconds);
        event = event.copyWith(imageUrl: signedUrl);
      }
      final response = await _supabaseClient
          .from(_eventsTable)
          .update(event.toSupabase())
          .eq('id', event.id)
          .select()
          .single();

      print('✅ EVENTS: Event updated successfully');
      return EventModel.fromSupabase(response);
    } catch (e) {
      print('❌ EVENTS ERROR: ${e.toString()}');
      return null;
    }
  }

  @override
  Future<bool> deleteEvent(String eventId) async {
    print('🔍 EVENTS: Deleting event: $eventId');
    try {
      await _supabaseClient.from(_eventsTable).delete().eq('id', eventId);
      print('✅ EVENTS: Event deleted successfully');
      return true;
    } catch (e) {
      print('❌ EVENTS ERROR: ${e.toString()}');
      return false;
    }
  }

  Future<void> _sendEventNotification(
    Map<String, dynamic> eventDetails,
    String userEmail,
    String userId,
  ) async {
    // Prepare the request payload
    final Map<String, dynamic> payload = {
      'record': {
        'event_id': eventDetails['event_id'],
        'user_id': userId,
        'id': eventDetails['id'],
        'registered_at': eventDetails['registered_at'],
        'user_email': userEmail,
      },
    };
    // Set the specific authorization header for this API
    final options = Options(
      headers: {
        'Authorization': 'Bearer ${AppConstants.apiKey}',
        'Content-Type': 'application/json',
      },
    );
    try {
      await _apiClient.post(
        '${AppConstants.baseUrl}/functions/v1/send-event-registration-email',
        data: payload,
        options: options,
      );
      print('📨 Notification sent');
    } catch (e) {
      print('⚠️ EVENT: Failed to send notification - $e');
      if (e is DioError) {
        print('Response data: ${e.response?.data}');
      }
    }
  }

  @override
  Future<bool> registerForEvent(EventModel event) async {
    print('🔍 EVENTS: Registering for event: ${event.id}');
    try {
      // Get current user ID
      final userId = _supabaseClient.auth.currentUser?.id;
      final userEmail = _supabaseClient.auth.currentUser?.email ?? '';
      if (userId == null) {
        print('❌ EVENTS: No authenticated user found');
        return false;
      }

      // Create registration
      final eventRegistration = await _supabaseClient
          .from(_registrationsTable)
          .insert({'event_id': event.id, 'user_id': userId})
          .select()
          .single();
      print('✅ EVENTS: Registered for event successfully');

      try {
        print('🔄 EVENT: Sending registration notification');

        final balance = await _supabaseClient
            .from('user_tokens')
            .select('balance')
            .eq('user_id', userId)
            .maybeSingle();

        final token = balance != null && balance['balance'] != null
            ? (balance['balance'] as num).toInt()
            : 0;

        await _supabaseClient
            .from('user_tokens')
            .update({'balance': token + (500)})
            .eq('user_id', userId);

        await _sendEventNotification(eventRegistration, userEmail, userId);

        print('✅ Event: Notification sent successfully');
      } catch (apiError) {
        print('⚠️ Event: Failed to send notification - ${apiError.toString()}');
        // Don't fail the entire operation if notification fails
      }
      return true;
    } catch (e) {
      print('❌ EVENTS ERROR: ${e.toString()}');
      return false;
    }
  }

  @override
  Future<bool> unregisterFromEvent(String eventId) async {
    print('🔍 EVENTS: Unregistering from event: $eventId');
    try {
      // Get current user ID
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        print('❌ EVENTS: No authenticated user found');
        return false;
      }

      // Check if the event is paid
      final isPaid = await isEventPaid(eventId);
      if (isPaid) {
        print('❌ EVENTS: Cannot unregister from paid event');
        return false;
      }

      // Delete registration
      await _supabaseClient
          .from(_registrationsTable)
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);

      print('✅ EVENTS: Unregistered from event successfully');
      return true;
    } catch (e) {
      print('❌ EVENTS ERROR: ${e.toString()}');
      return false;
    }
  }

  @override
  Future<bool> isRegisteredForEvent(String eventId) async {
    print('🔍 EVENTS: Checking if user is registered for event: $eventId');
    try {
      // Get current user ID
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        print('❌ EVENTS: No authenticated user found');
        return false;
      }

      // Check if registration exists
      final response = await _supabaseClient
          .from(_registrationsTable)
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      final isRegistered = response != null;
      print(
        '✅ EVENTS: User is ${isRegistered ? '' : 'not '}registered for event',
      );
      return isRegistered;
    } catch (e) {
      print('❌ EVENTS ERROR: ${e.toString()}');
      return false;
    }
  }

  @override
  Future<List<EventRegistrationModel>> getEventRegistrations(
    String eventId,
  ) async {
    print('🔍 EVENTS: Fetching registrations for event: $eventId');
    try {
      final response = await _supabaseClient
          .from(_registrationsTable)
          .select()
          .eq('event_id', eventId)
          .order('registered_at', ascending: false);

      print('✅ EVENTS: Fetched ${response.length} registrations');
      return response
          .map((data) => EventRegistrationModel.fromSupabase(data))
          .toList();
    } catch (e) {
      print('❌ EVENTS ERROR: ${e.toString()}');
      return [];
    }
  }

  @override
  Future<bool> isEventPaid(String eventId) async {
    print('🔍 EVENTS: Checking if event is paid: $eventId');
    try {
      final response = await _supabaseClient
          .from(_eventsTable)
          .select('is_paid')
          .eq('id', eventId)
          .single();

      final isPaid = response['is_paid'] ?? false;
      print('✅ EVENTS: Event is ${isPaid ? 'paid' : 'free'}');
      return isPaid;
    } catch (e) {
      print('❌ EVENTS ERROR: ${e.toString()}');
      return false;
    }
  }

  @override
  Future<bool> approveEvent(EventModel event) async {
    print('🔍 EVENTS: Updating event: ${event.id}');
    // try {
    print('🔍 EVENTS: Approving event: ${event.toSupabase()}');
    await _supabaseClient
        .from(_eventsTable)
        .update({'status': 'Approved'})
        .eq('id', event.id)
        .select()
        .single();

    print('✅ EVENTS: Event updated successfully');
    return true;
    // } catch (e) {
    //   print('❌ EVENTS ERROR: ${e.toString()}');
    //   return false;
    // }
  }

  @override
  Future<List<RegisteredUserModel>> getRegisteredUsersForEvent(
    String eventId,
  ) async {
    print('🔍 EVENTS: Fetching registered users for event: $eventId');
    try {
      // Get registrations for the event
      final registrationsResponse = await _supabaseClient
          .from(_registrationsTable)
          .select()
          .eq('event_id', eventId)
          .order('registered_at', ascending: false);

      if (registrationsResponse.isEmpty) {
        print('✅ EVENTS: No users registered for this event');
        return [];
      }

      // Extract user IDs from registrations
      final userIds = registrationsResponse
          .map((data) => data['user_id'] as String)
          .where((id) => id.isNotEmpty)
          .toList();

      if (userIds.isEmpty) {
        print('✅ EVENTS: No valid user IDs found in registrations');
        return [];
      }

      // Fetch user profiles for these users from users table
      final usersResponse = await _supabaseClient
          .from(_usersTable)
          .select()
          .inFilter('id', userIds);

      // Create a map of userId -> UserModel for quick lookup
      final Map<String, UserModel> usersMap = {};
      for (final userData in usersResponse) {
        final user = UserModel.fromSupabase(userData);
        usersMap[user.id] = user;
      }

      // Combine registration data with user profiles
      final registeredUsers = registrationsResponse.map((registrationData) {
        final userId = registrationData['user_id'] as String;
        final user = usersMap[userId];

        return RegisteredUserModel.fromRegistrationAndUser(
          registrationData,
          user,
        );
      }).toList();

      print('✅ EVENTS: Fetched ${registeredUsers.length} registered users');
      return registeredUsers;
    } catch (e) {
      print('❌ EVENTS ERROR: ${e.toString()}');
      return [];
    }
  }

  @override
  Future<bool> setEventBannerStatus(String eventId, bool isBanner) async {
    try {
      // Step 1: Set all rows to is_banner = false
      await _supabaseClient
          .from(_eventsTable)
          .update({'is_banner': false})
          .neq('id', eventId);

      // Step 2: Set selected row to is_banner = true
      await _supabaseClient
          .from(_eventsTable)
          .update({'is_banner': true})
          .eq('id', eventId);

      return true;
    } catch (e) {
      print('Error setting banner: $e');
      return false;
    }
  }
}
