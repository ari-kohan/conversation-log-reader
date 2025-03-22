export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      activities: {
        Row: {
          category: string | null
          created_at: string
          id: string
          name: string
        }
        Insert: {
          category?: string | null
          created_at?: string
          id?: string
          name: string
        }
        Update: {
          category?: string | null
          created_at?: string
          id?: string
          name?: string
        }
        Relationships: []
      }
      calendar_events: {
        Row: {
          all_day: boolean | null
          calendar_event_id: string | null
          created_at: string | null
          description: string | null
          end_time: string
          feedback_notes: string | null
          feedback_sent: boolean | null
          google_event_id: string | null
          id: string
          location: string | null
          mood: string | null
          start_time: string
          timezone: string | null
          title: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          all_day?: boolean | null
          calendar_event_id?: string | null
          created_at?: string | null
          description?: string | null
          end_time: string
          feedback_notes?: string | null
          feedback_sent?: boolean | null
          google_event_id?: string | null
          id?: string
          location?: string | null
          mood?: string | null
          start_time: string
          timezone?: string | null
          title: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          all_day?: boolean | null
          calendar_event_id?: string | null
          created_at?: string | null
          description?: string | null
          end_time?: string
          feedback_notes?: string | null
          feedback_sent?: boolean | null
          google_event_id?: string | null
          id?: string
          location?: string | null
          mood?: string | null
          start_time?: string
          timezone?: string | null
          title?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: []
      }
      chat_history: {
        Row: {
          created_at: string
          evening_checkin: boolean | null
          event_id: string | null
          event_title: string | null
          id: string
          is_ai: boolean
          is_onboarding_message: boolean | null
          is_secret: boolean | null
          message: string
          morning_checkin: boolean | null
          typewriter_played: boolean | null
          user_id: string
        }
        Insert: {
          created_at?: string
          evening_checkin?: boolean | null
          event_id?: string | null
          event_title?: string | null
          id?: string
          is_ai?: boolean
          is_onboarding_message?: boolean | null
          is_secret?: boolean | null
          message: string
          morning_checkin?: boolean | null
          typewriter_played?: boolean | null
          user_id: string
        }
        Update: {
          created_at?: string
          evening_checkin?: boolean | null
          event_id?: string | null
          event_title?: string | null
          id?: string
          is_ai?: boolean
          is_onboarding_message?: boolean | null
          is_secret?: boolean | null
          message?: string
          morning_checkin?: boolean | null
          typewriter_played?: boolean | null
          user_id?: string
        }
        Relationships: []
      }
      chat_summaries: {
        Row: {
          chat_end: string | null
          chat_start: string | null
          created_at: string
          id: string
          summary: string | null
          user_id: string
        }
        Insert: {
          chat_end?: string | null
          chat_start?: string | null
          created_at?: string
          id?: string
          summary?: string | null
          user_id?: string
        }
        Update: {
          chat_end?: string | null
          chat_start?: string | null
          created_at?: string
          id?: string
          summary?: string | null
          user_id?: string
        }
        Relationships: []
      }
      contact_group_memberships: {
        Row: {
          contact_id: string
          group_id: string
        }
        Insert: {
          contact_id: string
          group_id: string
        }
        Update: {
          contact_id?: string
          group_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "contact_group_memberships_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contact_group_memberships_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "contact_groups"
            referencedColumns: ["id"]
          },
        ]
      }
      contact_groups: {
        Row: {
          created_at: string
          emoji: string | null
          id: string
          name: string
          user_id: string
        }
        Insert: {
          created_at?: string
          emoji?: string | null
          id?: string
          name: string
          user_id: string
        }
        Update: {
          created_at?: string
          emoji?: string | null
          id?: string
          name?: string
          user_id?: string
        }
        Relationships: []
      }
      contacts: {
        Row: {
          address: string | null
          closeness: number | null
          created_at: string
          email: string | null
          id: string
          instagram: string | null
          interests: Json | null
          is_archived: boolean | null
          linkedin: string | null
          meeting_story: string | null
          name: string
          phone: string | null
          photo: string | null
          relationship: string | null
          twitter: string | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          address?: string | null
          closeness?: number | null
          created_at?: string
          email?: string | null
          id?: string
          instagram?: string | null
          interests?: Json | null
          is_archived?: boolean | null
          linkedin?: string | null
          meeting_story?: string | null
          name: string
          phone?: string | null
          photo?: string | null
          relationship?: string | null
          twitter?: string | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          address?: string | null
          closeness?: number | null
          created_at?: string
          email?: string | null
          id?: string
          instagram?: string | null
          interests?: Json | null
          is_archived?: boolean | null
          linkedin?: string | null
          meeting_story?: string | null
          name?: string
          phone?: string | null
          photo?: string | null
          relationship?: string | null
          twitter?: string | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: []
      }
      event_attendees: {
        Row: {
          contact_id: string
          created_at: string
          event_id: string
        }
        Insert: {
          contact_id: string
          created_at?: string
          event_id: string
        }
        Update: {
          contact_id?: string
          created_at?: string
          event_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "event_attendees_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_attendees_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "calendar_events"
            referencedColumns: ["id"]
          },
        ]
      }
      food_items: {
        Row: {
          category: string | null
          created_at: string
          id: string
          name: string
        }
        Insert: {
          category?: string | null
          created_at?: string
          id?: string
          name: string
        }
        Update: {
          category?: string | null
          created_at?: string
          id?: string
          name?: string
        }
        Relationships: []
      }
      languages: {
        Row: {
          created_at: string
          id: string
          name: string
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
        }
        Relationships: []
      }
      messages: {
        Row: {
          created_at: string | null
          direction: string | null
          id: number
          message: string | null
          phone_number: string | null
          status: string | null
          twilio_message_id: string | null
        }
        Insert: {
          created_at?: string | null
          direction?: string | null
          id?: number
          message?: string | null
          phone_number?: string | null
          status?: string | null
          twilio_message_id?: string | null
        }
        Update: {
          created_at?: string | null
          direction?: string | null
          id?: number
          message?: string | null
          phone_number?: string | null
          status?: string | null
          twilio_message_id?: string | null
        }
        Relationships: []
      }
      music_genres: {
        Row: {
          category: string | null
          created_at: string
          id: string
          name: string
        }
        Insert: {
          category?: string | null
          created_at?: string
          id?: string
          name: string
        }
        Update: {
          category?: string | null
          created_at?: string
          id?: string
          name?: string
        }
        Relationships: []
      }
      nightly_journal: {
        Row: {
          bud: Json | null
          created_at: string
          id: string
          rose: Json | null
          thorn: Json | null
          user_id: string | null
        }
        Insert: {
          bud?: Json | null
          created_at?: string
          id?: string
          rose?: Json | null
          thorn?: Json | null
          user_id?: string | null
        }
        Update: {
          bud?: Json | null
          created_at?: string
          id?: string
          rose?: Json | null
          thorn?: Json | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "nightly_journal_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          age: number | null
          avatar_url: string | null
          catch_up_contacts: string[] | null
          city: string | null
          current_interests: Json | null
          desired_food_preferences: Json | null
          desired_interests: Json | null
          desired_music_preferences: Json | null
          display_name: string | null
          food_preferences: Json | null
          gender: string | null
          goals: Json | null
          google_access_token: string | null
          google_refresh_token: string | null
          google_token_expired: boolean
          google_token_expires_at: string | null
          has_completed_tutorial: boolean | null
          has_google_calendar: boolean
          id: string
          languages: Json | null
          long_term_goals: Json | null
          music_preferences: Json | null
          occupation: string | null
          onboarding_completed: boolean | null
          onboarding_started_at: string | null
          onboarding_step: string | null
          personality_comments: string[] | null
          personality_traits: Json | null
          phone_number: string | null
          relationship_status: string | null
          skill_aesthete: number | null
          skill_athlete: number | null
          skill_gourmand: number | null
          skill_reveler: number | null
          skill_traveler: number | null
          updated_at: string | null
          username: string | null
          utc_offset_minutes: number | null
        }
        Insert: {
          age?: number | null
          avatar_url?: string | null
          catch_up_contacts?: string[] | null
          city?: string | null
          current_interests?: Json | null
          desired_food_preferences?: Json | null
          desired_interests?: Json | null
          desired_music_preferences?: Json | null
          display_name?: string | null
          food_preferences?: Json | null
          gender?: string | null
          goals?: Json | null
          google_access_token?: string | null
          google_refresh_token?: string | null
          google_token_expired?: boolean
          google_token_expires_at?: string | null
          has_completed_tutorial?: boolean | null
          has_google_calendar?: boolean
          id: string
          languages?: Json | null
          long_term_goals?: Json | null
          music_preferences?: Json | null
          occupation?: string | null
          onboarding_completed?: boolean | null
          onboarding_started_at?: string | null
          onboarding_step?: string | null
          personality_comments?: string[] | null
          personality_traits?: Json | null
          phone_number?: string | null
          relationship_status?: string | null
          skill_aesthete?: number | null
          skill_athlete?: number | null
          skill_gourmand?: number | null
          skill_reveler?: number | null
          skill_traveler?: number | null
          updated_at?: string | null
          username?: string | null
          utc_offset_minutes?: number | null
        }
        Update: {
          age?: number | null
          avatar_url?: string | null
          catch_up_contacts?: string[] | null
          city?: string | null
          current_interests?: Json | null
          desired_food_preferences?: Json | null
          desired_interests?: Json | null
          desired_music_preferences?: Json | null
          display_name?: string | null
          food_preferences?: Json | null
          gender?: string | null
          goals?: Json | null
          google_access_token?: string | null
          google_refresh_token?: string | null
          google_token_expired?: boolean
          google_token_expires_at?: string | null
          has_completed_tutorial?: boolean | null
          has_google_calendar?: boolean
          id?: string
          languages?: Json | null
          long_term_goals?: Json | null
          music_preferences?: Json | null
          occupation?: string | null
          onboarding_completed?: boolean | null
          onboarding_started_at?: string | null
          onboarding_step?: string | null
          personality_comments?: string[] | null
          personality_traits?: Json | null
          phone_number?: string | null
          relationship_status?: string | null
          skill_aesthete?: number | null
          skill_athlete?: number | null
          skill_gourmand?: number | null
          skill_reveler?: number | null
          skill_traveler?: number | null
          updated_at?: string | null
          username?: string | null
          utc_offset_minutes?: number | null
        }
        Relationships: []
      }
      user_push_tokens: {
        Row: {
          created_at: string
          device_type: string
          id: string
          last_updated: string
          push_token: string
          user_id: string
        }
        Insert: {
          created_at?: string
          device_type: string
          id?: string
          last_updated?: string
          push_token: string
          user_id: string
        }
        Update: {
          created_at?: string
          device_type?: string
          id?: string
          last_updated?: string
          push_token?: string
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      duplicate_contacts: {
        Row: {
          contact_ids: string[] | null
          count: number | null
          name: string | null
          user_id: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      check_completed_events: {
        Args: Record<PropertyKey, never>
        Returns: Json
      }
      extract_activity: {
        Args: {
          title: string
        }
        Returns: string
      }
      extract_food_item: {
        Args: {
          title: string
        }
        Returns: string
      }
      get_timezone_for_city: {
        Args: {
          city_name: string
        }
        Returns: string
      }
      matches_activity: {
        Args: {
          title: string
        }
        Returns: boolean
      }
      matches_food_item: {
        Args: {
          title: string
        }
        Returns: boolean
      }
      schedule_all_user_checkins: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      schedule_evening_checkin: {
        Args: Record<PropertyKey, never>
        Returns: Json
      }
      schedule_morning_checkin: {
        Args: Record<PropertyKey, never>
        Returns: Json
      }
      schedule_timezone_aware_checkin: {
        Args: {
          user_id: string
          target_hour: number
          checkin_type: string
        }
        Returns: undefined
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type PublicSchema = Database[Extract<keyof Database, "public">]

export type Tables<
  PublicTableNameOrOptions extends
    | keyof (PublicSchema["Tables"] & PublicSchema["Views"])
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
        Database[PublicTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
      Database[PublicTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : PublicTableNameOrOptions extends keyof (PublicSchema["Tables"] &
        PublicSchema["Views"])
    ? (PublicSchema["Tables"] &
        PublicSchema["Views"])[PublicTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  PublicEnumNameOrOptions extends
    | keyof PublicSchema["Enums"]
    | { schema: keyof Database },
  EnumName extends PublicEnumNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = PublicEnumNameOrOptions extends { schema: keyof Database }
  ? Database[PublicEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : PublicEnumNameOrOptions extends keyof PublicSchema["Enums"]
    ? PublicSchema["Enums"][PublicEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof PublicSchema["CompositeTypes"]
    | { schema: keyof Database },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof Database }
  ? Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof PublicSchema["CompositeTypes"]
    ? PublicSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never
