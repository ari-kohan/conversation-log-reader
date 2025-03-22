

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";






CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."check_completed_events"() RETURNS "json"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$DECLARE
    event_record RECORD;
    response json;
BEGIN
    FOR event_record IN
        SELECT ce.* 
        FROM calendar_events ce
        WHERE 
            ce.end_time BETWEEN NOW() - INTERVAL '15 minutes' AND NOW()
            AND (ce.feedback_sent IS NULL OR ce.feedback_sent = FALSE)
    LOOP
        -- Only send message if we found completed events
        PERFORM net.http_post(
            url:='https://ejqucnzpgebbujlnmdzx.functions.supabase.co/daily-checkin',
            headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqcXVjbnpwZ2ViYnVqbG5tZHp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc1MDA3NjgsImV4cCI6MjA1MzA3Njc2OH0.wXBUTxCLlq4vtGnF8ScvGFzZQeJfdYhgzvW6CF3eViI"}'::jsonb,
            body:=json_build_object(
                'type', 'post-event',
                'event_id', event_record.id,
                'user_id', event_record.user_id,
                'event_title', event_record.title
            )::jsonb
        );
    END LOOP;

    response := json_build_object('status', 'Completed events check finished');
    RETURN response;
END;$$;


ALTER FUNCTION "public"."check_completed_events"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."extract_activity"("title" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  activity_name text;
BEGIN
  SELECT name INTO activity_name
  FROM activities
  WHERE title ILIKE '%' || name || '%'
  LIMIT 1;
  RETURN activity_name;
END;
$$;


ALTER FUNCTION "public"."extract_activity"("title" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."extract_food_item"("title" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  food_item text;
BEGIN
  SELECT name INTO food_item
  FROM food_items
  WHERE title ILIKE '%' || name || '%'
  LIMIT 1;
  RETURN food_item;
END;
$$;


ALTER FUNCTION "public"."extract_food_item"("title" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_timezone_for_city"("city_name" "text") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    CASE city_name
        WHEN 'New York, NY, USA' THEN RETURN 'America/New_York';
        WHEN 'Los Angeles, CA, USA' THEN RETURN 'America/Los_Angeles';
        WHEN 'Chicago, IL, USA' THEN RETURN 'America/Chicago';
        WHEN 'London, UK' THEN RETURN 'Europe/London';
        WHEN 'Paris, France' THEN RETURN 'Europe/Paris';
        WHEN 'Berlin, Germany' THEN RETURN 'Europe/Berlin';
        WHEN 'Tokyo, Japan' THEN RETURN 'Asia/Tokyo';
        ELSE RETURN 'UTC';
    END CASE;
END;
$$;


ALTER FUNCTION "public"."get_timezone_for_city"("city_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into public.profiles (
    id, 
    username, 
    avatar_url,
    onboarding_completed,
    onboarding_step,
    onboarding_started_at,
    has_completed_tutorial
  )
  values (
    new.id,
    new.raw_user_meta_data->>'username',
    new.raw_user_meta_data->>'avatar_url',
    false,
    'initial',
    now(),
    false
  );
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."matches_activity"("title" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM activities 
    WHERE title ILIKE '%' || name || '%'
  );
END;
$$;


ALTER FUNCTION "public"."matches_activity"("title" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."matches_food_item"("title" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM food_items 
    WHERE title ILIKE '%' || name || '%'
  );
END;
$$;


ALTER FUNCTION "public"."matches_food_item"("title" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."schedule_all_user_checkins"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  user_record RECORD;
BEGIN
  FOR user_record IN SELECT id FROM profiles
  LOOP
    -- Schedule morning check-in for 7 AM in user's timezone
    PERFORM schedule_timezone_aware_checkin(user_record.id, 7, 'morning');
    
    -- Schedule evening check-in for 10 PM in user's timezone
    PERFORM schedule_timezone_aware_checkin(user_record.id, 22, 'evening');
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."schedule_all_user_checkins"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."schedule_evening_checkin"() RETURNS "json"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  SELECT
    net.http_post(
      url:='https://ejqucnzpgebbujlnmdzx.functions.supabase.co/daily-checkin',
      headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqcXVjbnpwZ2ViYnVqbG5tZHp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc1MDA3NjgsImV4cCI6MjA1MzA3Njc2OH0.wXBUTxCLlq4vtGnF8ScvGFzZQeJfdYhgzvW6CF3eViI"}'::jsonb,
      body:='{"type": "evening"}'::jsonb
    );
  RETURN json_build_object('status', 'Evening check-in scheduled');
END;
$$;


ALTER FUNCTION "public"."schedule_evening_checkin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."schedule_morning_checkin"() RETURNS "json"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  SELECT
    net.http_post(
      url:='https://ejqucnzpgebbujlnmdzx.functions.supabase.co/daily-checkin',
      headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqcXVjbnpwZ2ViYnVqbG5tZHp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc1MDA3NjgsImV4cCI6MjA1MzA3Njc2OH0.wXBUTxCLlq4vtGnF8ScvGFzZQeJfdYhgzvW6CF3eViI"}'::jsonb,
      body:='{"type": "morning"}'::jsonb
    );
  RETURN json_build_object('status', 'Morning check-in scheduled');
END;
$$;


ALTER FUNCTION "public"."schedule_morning_checkin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."schedule_timezone_aware_checkin"("user_id" "uuid", "target_hour" integer, "checkin_type" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$DECLARE
  utc_offset_minutes INTEGER;
  calculated_utc_hour INTEGER;
  current_local_hour INTEGER;
  NEW_YORK_OFFSET CONSTANT INTEGER := -240; -- New York UTC offset in minutes
BEGIN
  -- Get UTC offset from profile, defaulting to New York offset
  SELECT COALESCE(profiles.utc_offset_minutes, NEW_YORK_OFFSET) 
  INTO utc_offset_minutes
  FROM profiles 
  WHERE id = user_id;

  -- Calculate current hour in user's local time
  SELECT 
    MOD(
      EXTRACT(HOUR FROM CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::INTEGER + 
      (utc_offset_minutes / 60) + 24,
      24
    )
  INTO current_local_hour;

  -- Only proceed if current local hour is >= target_hour AND < target_hour + 1
  IF current_local_hour >= target_hour AND current_local_hour < MOD(target_hour + 1, 24) THEN
    -- Convert local time to UTC hour using offset
    WITH time_conversion AS (
      SELECT 
        MOD(
          target_hour - (utc_offset_minutes / 60) + 24,
          24
        )::INTEGER as converted_hour
    )
    SELECT converted_hour INTO calculated_utc_hour FROM time_conversion;

    -- Invoke the daily-checkin function at the calculated UTC time
    PERFORM net.http_post(
      url:='https://ejqucnzpgebbujlnmdzx.functions.supabase.co/daily-checkin',
      headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqcXVjbnpwZ2ViYnVqbG5tZHp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc1MDA3NjgsImV4cCI6MjA1MzA3Njc2OH0.wXBUTxCLlq4vtGnF8ScvGFzZQeJfdYhgzvW6CF3eViI"}'::jsonb,
      body:=json_build_object(
        'type', checkin_type,
        'user_id', user_id
      )::jsonb
    );
  END IF;
END;$$;


ALTER FUNCTION "public"."schedule_timezone_aware_checkin"("user_id" "uuid", "target_hour" integer, "checkin_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_contact_interests_from_event"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  contact_record RECORD;
  activity_record RECORD;
  debug_info jsonb;
BEGIN
  -- Store debug info for logging
  debug_info := jsonb_build_object(
    'event_id', NEW.id,
    'event_title', NEW.title,
    'normalized_title', lower(NEW.title)
  );
  
  RAISE LOG 'Processing event: %', debug_info;

  -- First attempt: exact match with more detailed logging
  SELECT name, category INTO activity_record
  FROM activities
  WHERE lower(NEW.title) LIKE '%' || lower(name) || '%'
  ORDER BY length(name) DESC
  LIMIT 1;

  RAISE LOG 'Initial activity search result: %', 
    jsonb_build_object(
      'found_activity', activity_record.name IS NOT NULL,
      'search_term', NEW.title,
      'matched_activity', activity_record.name,
      'category', activity_record.category
    );

  -- Second attempt: try with common variations if no match found
  IF activity_record.name IS NULL THEN
    SELECT name, category INTO activity_record
    FROM activities
    WHERE 
      lower(NEW.title) LIKE '%' || lower(name) || 's%' OR  -- plural
      lower(NEW.title) LIKE '%' || lower(name) || 'ing%'   -- gerund
    ORDER BY length(name) DESC
    LIMIT 1;

    RAISE LOG 'Secondary activity search result: %',
      jsonb_build_object(
        'found_activity', activity_record.name IS NOT NULL,
        'search_term', NEW.title,
        'matched_activity', activity_record.name,
        'category', activity_record.category
      );
  END IF;

  -- If we found a matching activity
  IF activity_record.name IS NOT NULL THEN
    -- Log the start of attendee processing
    RAISE LOG 'Starting to process attendees for event %', NEW.id;
    
    -- Process each contact attending the event
    FOR contact_record IN 
      SELECT 
        ea.contact_id, 
        c.name as contact_name,
        c.food_interests,
        c.recreation_interests,
        c.arts_interests
      FROM event_attendees ea
      JOIN contacts c ON ea.contact_id = c.id
      WHERE ea.event_id = NEW.id
    LOOP
      RAISE LOG 'Processing contact: %', 
        jsonb_build_object(
          'contact_id', contact_record.contact_id,
          'contact_name', contact_record.contact_name,
          'activity_name', activity_record.name,
          'activity_category', activity_record.category
        );

      -- Update based on activity category with detailed logging
      CASE activity_record.category
        WHEN 'Arts' THEN
          UPDATE contacts 
          SET arts_interests = 
            CASE 
              WHEN arts_interests @> jsonb_build_array(activity_record.name) THEN arts_interests
              ELSE arts_interests || jsonb_build_array(activity_record.name)
            END,
            updated_at = now()
          WHERE id = contact_record.contact_id;
          
          RAISE LOG 'Updated arts interests for contact: %',
            jsonb_build_object(
              'contact_id', contact_record.contact_id,
              'activity', activity_record.name
            );
          
        WHEN 'Food / Drinks' THEN
          UPDATE contacts 
          SET food_interests = 
            CASE 
              WHEN food_interests @> jsonb_build_array(activity_record.name) THEN food_interests
              ELSE food_interests || jsonb_build_array(activity_record.name)
            END,
            updated_at = now()
          WHERE id = contact_record.contact_id;
          
          RAISE LOG 'Updated food interests for contact: %',
            jsonb_build_object(
              'contact_id', contact_record.contact_id,
              'activity', activity_record.name
            );
          
        ELSE -- Recreation or other categories
          UPDATE contacts 
          SET recreation_interests = 
            CASE 
              WHEN recreation_interests @> jsonb_build_array(activity_record.name) THEN recreation_interests
              ELSE recreation_interests || jsonb_build_array(activity_record.name)
            END,
            updated_at = now()
          WHERE id = contact_record.contact_id;
          
          RAISE LOG 'Updated recreation interests for contact: %',
            jsonb_build_object(
              'contact_id', contact_record.contact_id,
              'activity', activity_record.name
            );
      END CASE;
    END LOOP;
  END IF;
  
  RETURN NEW;

EXCEPTION 
  WHEN OTHERS THEN
    RAISE LOG 'Error in trigger: %', SQLERRM;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_contact_interests_from_event"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."activities" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "category" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."activities" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."calendar_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "start_time" timestamp with time zone NOT NULL,
    "end_time" timestamp with time zone NOT NULL,
    "google_event_id" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "location" "text",
    "feedback_sent" boolean DEFAULT false,
    "mood" "text",
    "feedback_notes" "text",
    "timezone" "text",
    "all_day" boolean,
    "calendar_event_id" "text"
);


ALTER TABLE "public"."calendar_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."chat_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "message" "text" NOT NULL,
    "is_ai" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "is_onboarding_message" boolean DEFAULT false,
    "morning_checkin" boolean,
    "evening_checkin" boolean,
    "is_secret" boolean,
    "event_id" "uuid",
    "event_title" "text",
    "typewriter_played" boolean
);

ALTER TABLE ONLY "public"."chat_history" REPLICA IDENTITY FULL;


ALTER TABLE "public"."chat_history" OWNER TO "postgres";


COMMENT ON COLUMN "public"."chat_history"."typewriter_played" IS 'has typewriter animation been played';



CREATE TABLE IF NOT EXISTS "public"."chat_summaries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "chat_start" timestamp with time zone,
    "chat_end" timestamp with time zone,
    "summary" "text"
);


ALTER TABLE "public"."chat_summaries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."contact_group_memberships" (
    "contact_id" "uuid" NOT NULL,
    "group_id" "uuid" NOT NULL
);


ALTER TABLE "public"."contact_group_memberships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."contact_groups" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "emoji" "text"
);


ALTER TABLE "public"."contact_groups" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."contacts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "email" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "closeness" numeric DEFAULT 0.5,
    "phone" "text",
    "instagram" "text",
    "linkedin" "text",
    "twitter" "text",
    "meeting_story" "text",
    "relationship" "text",
    "is_archived" boolean DEFAULT false,
    "interests" "jsonb",
    "photo" "text",
    "address" "text",
    "updated_at" timestamp with time zone
);


ALTER TABLE "public"."contacts" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."duplicate_contacts" WITH ("security_invoker"='on') AS
 SELECT "contacts"."user_id",
    "contacts"."name",
    "count"(*) AS "count",
    "array_agg"("contacts"."id") AS "contact_ids"
   FROM "public"."contacts"
  GROUP BY "contacts"."user_id", "contacts"."name"
 HAVING ("count"(*) > 1)
  ORDER BY "contacts"."user_id", "contacts"."name";


ALTER TABLE "public"."duplicate_contacts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."event_attendees" (
    "event_id" "uuid" NOT NULL,
    "contact_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."event_attendees" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."food_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "category" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."food_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."languages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."languages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" integer NOT NULL,
    "phone_number" character varying(15),
    "message" "text",
    "direction" character varying(10),
    "status" character varying(20),
    "twilio_message_id" character varying(50),
    "created_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."messages_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."messages_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."messages_id_seq" OWNED BY "public"."messages"."id";



CREATE TABLE IF NOT EXISTS "public"."music_genres" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "category" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."music_genres" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."nightly_journal" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_id" "uuid",
    "rose" "json",
    "bud" "json",
    "thorn" "json"
);


ALTER TABLE "public"."nightly_journal" OWNER TO "postgres";


COMMENT ON TABLE "public"."nightly_journal" IS 'stores rose, bud, and thorn entries';



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "username" "text",
    "avatar_url" "text",
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "google_access_token" "text",
    "google_refresh_token" "text",
    "google_token_expires_at" timestamp with time zone,
    "display_name" "text",
    "onboarding_completed" boolean DEFAULT false,
    "goals" "jsonb" DEFAULT '[]'::"jsonb",
    "personality_traits" "jsonb" DEFAULT '{}'::"jsonb",
    "personality_comments" "text"[],
    "current_interests" "jsonb" DEFAULT '[]'::"jsonb",
    "desired_interests" "jsonb" DEFAULT '[]'::"jsonb",
    "age" integer,
    "city" "text",
    "languages" "jsonb" DEFAULT '[]'::"jsonb",
    "relationship_status" "text",
    "gender" "text",
    "occupation" "text",
    "onboarding_step" "text" DEFAULT 'initial'::"text",
    "onboarding_started_at" timestamp with time zone,
    "has_completed_tutorial" boolean DEFAULT false,
    "food_preferences" "jsonb" DEFAULT '[]'::"jsonb",
    "music_preferences" "jsonb" DEFAULT '[]'::"jsonb",
    "has_google_calendar" boolean DEFAULT false NOT NULL,
    "google_token_expired" boolean DEFAULT false NOT NULL,
    "desired_food_preferences" "jsonb" DEFAULT '[]'::"jsonb",
    "desired_music_preferences" "jsonb" DEFAULT '[]'::"jsonb",
    "skill_gourmand" numeric DEFAULT 0,
    "skill_aesthete" numeric DEFAULT 0,
    "skill_traveler" numeric DEFAULT 0,
    "skill_athlete" numeric DEFAULT 0,
    "skill_reveler" numeric DEFAULT 0,
    "utc_offset_minutes" smallint,
    "phone_number" "text",
    "long_term_goals" "jsonb" DEFAULT '[]'::"jsonb",
    "catch_up_contacts" "uuid"[] DEFAULT ARRAY[]::"uuid"[],
    CONSTRAINT "username_length" CHECK (("char_length"("username") >= 3))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


COMMENT ON COLUMN "public"."profiles"."skill_gourmand" IS 'Scale from 0-100 representing progress in food and dining experiences';



COMMENT ON COLUMN "public"."profiles"."skill_aesthete" IS 'Scale from 0-100 representing progress in art and cultural experiences';



COMMENT ON COLUMN "public"."profiles"."skill_traveler" IS 'Scale from 0-100 representing progress in travel experiences';



COMMENT ON COLUMN "public"."profiles"."skill_athlete" IS 'Scale from 0-100 representing progress in athletic activities';



COMMENT ON COLUMN "public"."profiles"."skill_reveler" IS 'Scale from 0-100 representing progress in social and entertainment activities';



COMMENT ON COLUMN "public"."profiles"."long_term_goals" IS 'Array of goal objects with ranking. Format: [{"type": "string", "description": "string", "rank": number}]';



COMMENT ON COLUMN "public"."profiles"."catch_up_contacts" IS 'Array of contact IDs that the user wants to catch up with';



CREATE TABLE IF NOT EXISTS "public"."user_push_tokens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "push_token" "text" NOT NULL,
    "device_type" "text" NOT NULL,
    "last_updated" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_push_tokens" OWNER TO "postgres";


ALTER TABLE ONLY "public"."messages" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."messages_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."activities"
    ADD CONSTRAINT "activities_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."activities"
    ADD CONSTRAINT "activities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."calendar_events"
    ADD CONSTRAINT "calendar_events_google_event_id_key" UNIQUE ("google_event_id");



ALTER TABLE ONLY "public"."calendar_events"
    ADD CONSTRAINT "calendar_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chat_history"
    ADD CONSTRAINT "chat_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chat_summaries"
    ADD CONSTRAINT "chat_summaries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contact_group_memberships"
    ADD CONSTRAINT "contact_group_memberships_pkey" PRIMARY KEY ("contact_id", "group_id");



ALTER TABLE ONLY "public"."contact_groups"
    ADD CONSTRAINT "contact_groups_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contacts"
    ADD CONSTRAINT "contacts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."event_attendees"
    ADD CONSTRAINT "event_attendees_pkey" PRIMARY KEY ("event_id", "contact_id");



ALTER TABLE ONLY "public"."food_items"
    ADD CONSTRAINT "food_items_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."food_items"
    ADD CONSTRAINT "food_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."languages"
    ADD CONSTRAINT "languages_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."languages"
    ADD CONSTRAINT "languages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."music_genres"
    ADD CONSTRAINT "music_genres_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."music_genres"
    ADD CONSTRAINT "music_genres_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."nightly_journal"
    ADD CONSTRAINT "nightly_journal_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_username_key" UNIQUE ("username");



ALTER TABLE ONLY "public"."event_attendees"
    ADD CONSTRAINT "unique_event_attendee" UNIQUE ("event_id", "contact_id");



ALTER TABLE ONLY "public"."user_push_tokens"
    ADD CONSTRAINT "user_push_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_push_tokens"
    ADD CONSTRAINT "user_push_tokens_user_id_push_token_key" UNIQUE ("user_id", "push_token");



CREATE INDEX "calendar_events_start_time_idx" ON "public"."calendar_events" USING "btree" ("start_time");



CREATE INDEX "calendar_events_user_id_idx" ON "public"."calendar_events" USING "btree" ("user_id");



CREATE INDEX "event_attendees_contact_id_idx" ON "public"."event_attendees" USING "btree" ("contact_id");



CREATE INDEX "event_attendees_event_id_idx" ON "public"."event_attendees" USING "btree" ("event_id");



CREATE INDEX "idx_contacts_arts_interests" ON "public"."contacts" USING "gin" ("interests");



CREATE INDEX "idx_contacts_user_id_name" ON "public"."contacts" USING "btree" ("user_id", "name");



CREATE INDEX "idx_profiles_goals" ON "public"."profiles" USING "gin" ("goals");



CREATE INDEX "idx_user_push_tokens_token" ON "public"."user_push_tokens" USING "btree" ("push_token");



CREATE INDEX "idx_user_push_tokens_user_id" ON "public"."user_push_tokens" USING "btree" ("user_id");



CREATE INDEX "profiles_catch_up_contacts_idx" ON "public"."profiles" USING "gin" ("catch_up_contacts");



CREATE OR REPLACE TRIGGER "update_contact_interests_from_event_trigger" AFTER INSERT ON "public"."calendar_events" FOR EACH ROW EXECUTE FUNCTION "public"."update_contact_interests_from_event"();



ALTER TABLE ONLY "public"."calendar_events"
    ADD CONSTRAINT "calendar_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."chat_history"
    ADD CONSTRAINT "chat_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."contact_group_memberships"
    ADD CONSTRAINT "contact_group_memberships_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."contact_group_memberships"
    ADD CONSTRAINT "contact_group_memberships_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."contact_groups"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."contact_groups"
    ADD CONSTRAINT "contact_groups_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."contacts"
    ADD CONSTRAINT "contacts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."event_attendees"
    ADD CONSTRAINT "event_attendees_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."event_attendees"
    ADD CONSTRAINT "event_attendees_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."calendar_events"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."nightly_journal"
    ADD CONSTRAINT "nightly_journal_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_push_tokens"
    ADD CONSTRAINT "user_push_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Activities are viewable by everyone" ON "public"."activities" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable insert for admin" ON "public"."activities" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users" ON "public"."food_items" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Enable insert for authenticated users" ON "public"."music_genres" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Enable users to manage their own contacts" ON "public"."contacts" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Food items are viewable by everyone" ON "public"."food_items" FOR SELECT USING (true);



CREATE POLICY "Languages are viewable by everyone" ON "public"."languages" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Music genres are viewable by everyone" ON "public"."music_genres" FOR SELECT USING (true);



CREATE POLICY "Public profiles are viewable by everyone." ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "Users can create their own groups" ON "public"."contact_groups" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete own calendar events" ON "public"."calendar_events" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete own event attendees" ON "public"."event_attendees" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."calendar_events"
  WHERE (("calendar_events"."id" = "event_attendees"."event_id") AND ("calendar_events"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can delete their own calendar events" ON "public"."calendar_events" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete their own contact groups" ON "public"."contact_groups" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can delete their own contacts" ON "public"."contacts" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete their own groups" ON "public"."contact_groups" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete their own push tokens" ON "public"."user_push_tokens" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert event attendees for their events" ON "public"."event_attendees" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."calendar_events"
  WHERE (("calendar_events"."id" = "event_attendees"."event_id") AND ("calendar_events"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can insert own calendar events" ON "public"."calendar_events" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert own event attendees" ON "public"."event_attendees" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."calendar_events"
  WHERE (("calendar_events"."id" = "event_attendees"."event_id") AND ("calendar_events"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can insert their own calendar events" ON "public"."calendar_events" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert their own contact groups" ON "public"."contact_groups" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can insert their own contacts" ON "public"."contacts" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert their own messages" ON "public"."chat_history" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert their own profile." ON "public"."profiles" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can insert their own push tokens" ON "public"."user_push_tokens" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can manage their own contact group memberships" ON "public"."contact_group_memberships" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."contacts" "c"
  WHERE (("c"."id" = "contact_group_memberships"."contact_id") AND ("c"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can manage their own goals" ON "public"."profiles" USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can read their own calendar events" ON "public"."calendar_events" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read their own contacts" ON "public"."contacts" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read their own messages" ON "public"."chat_history" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read their own onboarding status" ON "public"."profiles" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can read their own tokens" ON "public"."profiles" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can see their own event attendees" ON "public"."event_attendees" FOR SELECT USING (("event_id" IN ( SELECT "calendar_events"."id"
   FROM "public"."calendar_events"
  WHERE ("calendar_events"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can select their own contact groups" ON "public"."contact_groups" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can select their own push tokens" ON "public"."user_push_tokens" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own calendar events" ON "public"."calendar_events" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own profile." ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can update their own calendar events" ON "public"."calendar_events" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update their own catch_up_contacts" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can update their own chat messages" ON "public"."chat_history" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update their own contact groups" ON "public"."contact_groups" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can update their own contacts" ON "public"."contacts" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update their own event attendees" ON "public"."event_attendees" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."calendar_events"
  WHERE (("calendar_events"."id" = "event_attendees"."event_id") AND ("calendar_events"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."calendar_events"
  WHERE (("calendar_events"."id" = "event_attendees"."event_id") AND ("calendar_events"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can update their own push tokens" ON "public"."user_push_tokens" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update their own tokens" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can update their personality data" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can view attendees for their events" ON "public"."event_attendees" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."calendar_events"
  WHERE (("calendar_events"."id" = "event_attendees"."event_id") AND ("calendar_events"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can view own calendar events" ON "public"."calendar_events" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own event attendees" ON "public"."event_attendees" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."calendar_events"
  WHERE (("calendar_events"."id" = "event_attendees"."event_id") AND ("calendar_events"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can view their own catch_up_contacts" ON "public"."profiles" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can view their own groups" ON "public"."contact_groups" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."activities" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."calendar_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chat_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chat_summaries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."contact_group_memberships" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."contact_groups" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."contacts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."event_attendees" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."food_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."languages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."music_genres" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."nightly_journal" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_push_tokens" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


CREATE PUBLICATION "supabase_realtime_messages_publication" WITH (publish = 'insert, update, delete, truncate');


ALTER PUBLICATION "supabase_realtime_messages_publication" OWNER TO "supabase_admin";


ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."calendar_events";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."chat_history";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";












































































































































































































GRANT ALL ON FUNCTION "public"."check_completed_events"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_completed_events"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_completed_events"() TO "service_role";



GRANT ALL ON FUNCTION "public"."extract_activity"("title" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."extract_activity"("title" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."extract_activity"("title" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."extract_food_item"("title" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."extract_food_item"("title" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."extract_food_item"("title" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_timezone_for_city"("city_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_timezone_for_city"("city_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_timezone_for_city"("city_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."matches_activity"("title" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."matches_activity"("title" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."matches_activity"("title" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."matches_food_item"("title" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."matches_food_item"("title" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."matches_food_item"("title" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."schedule_all_user_checkins"() TO "anon";
GRANT ALL ON FUNCTION "public"."schedule_all_user_checkins"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."schedule_all_user_checkins"() TO "service_role";



GRANT ALL ON FUNCTION "public"."schedule_evening_checkin"() TO "anon";
GRANT ALL ON FUNCTION "public"."schedule_evening_checkin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."schedule_evening_checkin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."schedule_morning_checkin"() TO "anon";
GRANT ALL ON FUNCTION "public"."schedule_morning_checkin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."schedule_morning_checkin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."schedule_timezone_aware_checkin"("user_id" "uuid", "target_hour" integer, "checkin_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."schedule_timezone_aware_checkin"("user_id" "uuid", "target_hour" integer, "checkin_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."schedule_timezone_aware_checkin"("user_id" "uuid", "target_hour" integer, "checkin_type" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_contact_interests_from_event"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_contact_interests_from_event"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_contact_interests_from_event"() TO "service_role";
























GRANT ALL ON TABLE "public"."activities" TO "anon";
GRANT ALL ON TABLE "public"."activities" TO "authenticated";
GRANT ALL ON TABLE "public"."activities" TO "service_role";



GRANT ALL ON TABLE "public"."calendar_events" TO "anon";
GRANT ALL ON TABLE "public"."calendar_events" TO "authenticated";
GRANT ALL ON TABLE "public"."calendar_events" TO "service_role";



GRANT ALL ON TABLE "public"."chat_history" TO "anon";
GRANT ALL ON TABLE "public"."chat_history" TO "authenticated";
GRANT ALL ON TABLE "public"."chat_history" TO "service_role";



GRANT ALL ON TABLE "public"."chat_summaries" TO "anon";
GRANT ALL ON TABLE "public"."chat_summaries" TO "authenticated";
GRANT ALL ON TABLE "public"."chat_summaries" TO "service_role";



GRANT ALL ON TABLE "public"."contact_group_memberships" TO "anon";
GRANT ALL ON TABLE "public"."contact_group_memberships" TO "authenticated";
GRANT ALL ON TABLE "public"."contact_group_memberships" TO "service_role";



GRANT ALL ON TABLE "public"."contact_groups" TO "anon";
GRANT ALL ON TABLE "public"."contact_groups" TO "authenticated";
GRANT ALL ON TABLE "public"."contact_groups" TO "service_role";



GRANT ALL ON TABLE "public"."contacts" TO "anon";
GRANT ALL ON TABLE "public"."contacts" TO "authenticated";
GRANT ALL ON TABLE "public"."contacts" TO "service_role";



GRANT ALL ON TABLE "public"."duplicate_contacts" TO "anon";
GRANT ALL ON TABLE "public"."duplicate_contacts" TO "authenticated";
GRANT ALL ON TABLE "public"."duplicate_contacts" TO "service_role";



GRANT ALL ON TABLE "public"."event_attendees" TO "anon";
GRANT ALL ON TABLE "public"."event_attendees" TO "authenticated";
GRANT ALL ON TABLE "public"."event_attendees" TO "service_role";



GRANT ALL ON TABLE "public"."food_items" TO "anon";
GRANT ALL ON TABLE "public"."food_items" TO "authenticated";
GRANT ALL ON TABLE "public"."food_items" TO "service_role";



GRANT ALL ON TABLE "public"."languages" TO "anon";
GRANT ALL ON TABLE "public"."languages" TO "authenticated";
GRANT ALL ON TABLE "public"."languages" TO "service_role";



GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";



GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."music_genres" TO "anon";
GRANT ALL ON TABLE "public"."music_genres" TO "authenticated";
GRANT ALL ON TABLE "public"."music_genres" TO "service_role";



GRANT ALL ON TABLE "public"."nightly_journal" TO "anon";
GRANT ALL ON TABLE "public"."nightly_journal" TO "authenticated";
GRANT ALL ON TABLE "public"."nightly_journal" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."user_push_tokens" TO "anon";
GRANT ALL ON TABLE "public"."user_push_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."user_push_tokens" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






























RESET ALL;
