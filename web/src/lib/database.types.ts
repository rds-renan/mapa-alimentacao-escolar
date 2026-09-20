// Arquivo gerado por `npm run types:db` a partir das migrations em
// supabase/migrations/. Não editar à mão: mudou o schema, regera.
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
      document_meal_map: {
        Row: {
          generated_document_id: string
          meal_map_id: string
        }
        Insert: {
          generated_document_id: string
          meal_map_id: string
        }
        Update: {
          generated_document_id?: string
          meal_map_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "document_meal_map_generated_document_id_fkey"
            columns: ["generated_document_id"]
            isOneToOne: false
            referencedRelation: "generated_document"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "document_meal_map_meal_map_id_fkey"
            columns: ["meal_map_id"]
            isOneToOne: false
            referencedRelation: "meal_map"
            referencedColumns: ["id"]
          },
        ]
      }
      document_template: {
        Row: {
          file_name: string
          file_path: string
          id: string
          is_current: boolean
          school_id: string
          uploaded_at: string
          uploaded_by: string | null
        }
        Insert: {
          file_name: string
          file_path: string
          id?: string
          is_current?: boolean
          school_id: string
          uploaded_at?: string
          uploaded_by?: string | null
        }
        Update: {
          file_name?: string
          file_path?: string
          id?: string
          is_current?: boolean
          school_id?: string
          uploaded_at?: string
          uploaded_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "document_template_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "school"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "document_template_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "profile"
            referencedColumns: ["id"]
          },
        ]
      }
      food_item: {
        Row: {
          active: boolean
          created_at: string
          default_unit: string
          id: string
          name: string
          normalized_name: string | null
          school_id: string
        }
        Insert: {
          active?: boolean
          created_at?: string
          default_unit: string
          id?: string
          name: string
          normalized_name?: string | null
          school_id: string
        }
        Update: {
          active?: boolean
          created_at?: string
          default_unit?: string
          id?: string
          name?: string
          normalized_name?: string | null
          school_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "food_item_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "school"
            referencedColumns: ["id"]
          },
        ]
      }
      generated_document: {
        Row: {
          completed_at: string | null
          document_template_id: string
          expires_at: string | null
          file_name: string | null
          file_path: string | null
          id: string
          requested_at: string
          requested_by: string
          school_id: string
          status: Database["public"]["Enums"]["document_status"]
        }
        Insert: {
          completed_at?: string | null
          document_template_id: string
          expires_at?: string | null
          file_name?: string | null
          file_path?: string | null
          id?: string
          requested_at?: string
          requested_by: string
          school_id: string
          status?: Database["public"]["Enums"]["document_status"]
        }
        Update: {
          completed_at?: string | null
          document_template_id?: string
          expires_at?: string | null
          file_name?: string | null
          file_path?: string | null
          id?: string
          requested_at?: string
          requested_by?: string
          school_id?: string
          status?: Database["public"]["Enums"]["document_status"]
        }
        Relationships: [
          {
            foreignKeyName: "generated_document_document_template_id_fkey"
            columns: ["document_template_id"]
            isOneToOne: false
            referencedRelation: "document_template"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "generated_document_requested_by_fkey"
            columns: ["requested_by"]
            isOneToOne: false
            referencedRelation: "profile"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "generated_document_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "school"
            referencedColumns: ["id"]
          },
        ]
      }
      meal: {
        Row: {
          acceptance: Database["public"]["Enums"]["acceptance_level"] | null
          description: string | null
          id: string
          meal_map_id: string
          type: Database["public"]["Enums"]["meal_type"]
        }
        Insert: {
          acceptance?: Database["public"]["Enums"]["acceptance_level"] | null
          description?: string | null
          id?: string
          meal_map_id: string
          type: Database["public"]["Enums"]["meal_type"]
        }
        Update: {
          acceptance?: Database["public"]["Enums"]["acceptance_level"] | null
          description?: string | null
          id?: string
          meal_map_id?: string
          type?: Database["public"]["Enums"]["meal_type"]
        }
        Relationships: [
          {
            foreignKeyName: "meal_meal_map_id_fkey"
            columns: ["meal_map_id"]
            isOneToOne: false
            referencedRelation: "meal_map"
            referencedColumns: ["id"]
          },
        ]
      }
      meal_food_item: {
        Row: {
          food_item_id: string
          id: string
          meal_id: string
          quantity: number
        }
        Insert: {
          food_item_id: string
          id?: string
          meal_id: string
          quantity: number
        }
        Update: {
          food_item_id?: string
          id?: string
          meal_id?: string
          quantity?: number
        }
        Relationships: [
          {
            foreignKeyName: "meal_food_item_food_item_id_fkey"
            columns: ["food_item_id"]
            isOneToOne: false
            referencedRelation: "food_item"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meal_food_item_meal_id_fkey"
            columns: ["meal_id"]
            isOneToOne: false
            referencedRelation: "meal"
            referencedColumns: ["id"]
          },
        ]
      }
      meal_map: {
        Row: {
          created_at: string
          id: string
          locked: boolean
          map_date: string
          meals_served: number | null
          non_school_day: boolean
          note: string | null
          school_id: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          locked?: boolean
          map_date: string
          meals_served?: number | null
          non_school_day?: boolean
          note?: string | null
          school_id: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          locked?: boolean
          map_date?: string
          meals_served?: number | null
          non_school_day?: boolean
          note?: string | null
          school_id?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "meal_map_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "school"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meal_map_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profile"
            referencedColumns: ["id"]
          },
        ]
      }
      meal_map_unlock: {
        Row: {
          id: string
          meal_map_id: string
          reason: string
          unlocked_at: string
          unlocked_by: string
        }
        Insert: {
          id?: string
          meal_map_id: string
          reason: string
          unlocked_at?: string
          unlocked_by: string
        }
        Update: {
          id?: string
          meal_map_id?: string
          reason?: string
          unlocked_at?: string
          unlocked_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "meal_map_unlock_meal_map_id_fkey"
            columns: ["meal_map_id"]
            isOneToOne: false
            referencedRelation: "meal_map"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meal_map_unlock_unlocked_by_fkey"
            columns: ["unlocked_by"]
            isOneToOne: false
            referencedRelation: "profile"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_change: {
        Row: {
          id: string
          meal_id: string
          reason: string
        }
        Insert: {
          id?: string
          meal_id: string
          reason: string
        }
        Update: {
          id?: string
          meal_id?: string
          reason?: string
        }
        Relationships: [
          {
            foreignKeyName: "menu_change_meal_id_fkey"
            columns: ["meal_id"]
            isOneToOne: true
            referencedRelation: "meal"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_change_food_item: {
        Row: {
          food_item_id: string
          id: string
          menu_change_id: string
          quantity: number
        }
        Insert: {
          food_item_id: string
          id?: string
          menu_change_id: string
          quantity: number
        }
        Update: {
          food_item_id?: string
          id?: string
          menu_change_id?: string
          quantity?: number
        }
        Relationships: [
          {
            foreignKeyName: "menu_change_food_item_food_item_id_fkey"
            columns: ["food_item_id"]
            isOneToOne: false
            referencedRelation: "food_item"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_change_food_item_menu_change_id_fkey"
            columns: ["menu_change_id"]
            isOneToOne: false
            referencedRelation: "menu_change"
            referencedColumns: ["id"]
          },
        ]
      }
      profile: {
        Row: {
          active: boolean
          created_at: string
          email: string
          id: string
          last_access: string | null
          name: string
          role: Database["public"]["Enums"]["user_role"]
          school_id: string
        }
        Insert: {
          active?: boolean
          created_at?: string
          email: string
          id: string
          last_access?: string | null
          name: string
          role: Database["public"]["Enums"]["user_role"]
          school_id: string
        }
        Update: {
          active?: boolean
          created_at?: string
          email?: string
          id?: string
          last_access?: string | null
          name?: string
          role?: Database["public"]["Enums"]["user_role"]
          school_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "profile_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "school"
            referencedColumns: ["id"]
          },
        ]
      }
      school: {
        Row: {
          city: string
          created_at: string
          id: string
          name: string
          school_year: number
        }
        Insert: {
          city: string
          created_at?: string
          id?: string
          name: string
          school_year: number
        }
        Update: {
          city?: string
          created_at?: string
          id?: string
          name?: string
          school_year?: number
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      complete_document_generation: {
        Args: {
          p_document_id: string
          p_file_name: string
          p_file_path: string
        }
        Returns: {
          completed_at: string | null
          document_template_id: string
          expires_at: string | null
          file_name: string | null
          file_path: string | null
          id: string
          requested_at: string
          requested_by: string
          school_id: string
          status: Database["public"]["Enums"]["document_status"]
        }
        SetofOptions: {
          from: "*"
          to: "generated_document"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      current_role_is: {
        Args: { wanted: Database["public"]["Enums"]["user_role"] }
        Returns: boolean
      }
      current_school_id: { Args: never; Returns: string }
      fail_document_generation: {
        Args: { p_document_id: string }
        Returns: {
          completed_at: string | null
          document_template_id: string
          expires_at: string | null
          file_name: string | null
          file_path: string | null
          id: string
          requested_at: string
          requested_by: string
          school_id: string
          status: Database["public"]["Enums"]["document_status"]
        }
        SetofOptions: {
          from: "*"
          to: "generated_document"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      is_service: { Args: never; Returns: boolean }
      meal_map_is_locked: { Args: { map_id: string }; Returns: boolean }
      replace_document_template: {
        Args: { p_file_name: string; p_file_path: string }
        Returns: {
          file_name: string
          file_path: string
          id: string
          is_current: boolean
          school_id: string
          uploaded_at: string
          uploaded_by: string | null
        }
        SetofOptions: {
          from: "*"
          to: "document_template"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      save_meal_map: { Args: { payload: Json }; Returns: Json }
      start_document_generation: {
        Args: {
          p_meal_map_ids: string[]
          p_requested_by: string
          p_school_id: string
        }
        Returns: {
          completed_at: string | null
          document_template_id: string
          expires_at: string | null
          file_name: string | null
          file_path: string | null
          id: string
          requested_at: string
          requested_by: string
          school_id: string
          status: Database["public"]["Enums"]["document_status"]
        }
        SetofOptions: {
          from: "*"
          to: "generated_document"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      touch_last_access: { Args: never; Returns: undefined }
      unlock_meal_map: {
        Args: { map_id: string; unlock_reason: string }
        Returns: {
          created_at: string
          id: string
          locked: boolean
          map_date: string
          meals_served: number | null
          non_school_day: boolean
          note: string | null
          school_id: string
          updated_at: string
          updated_by: string | null
        }
        SetofOptions: {
          from: "*"
          to: "meal_map"
          isOneToOne: true
          isSetofReturn: false
        }
      }
    }
    Enums: {
      acceptance_level: "great" | "good" | "poor"
      document_status: "processing" | "available" | "failed"
      meal_type: "morning_snack" | "lunch" | "afternoon_snack"
      user_role: "admin" | "cook"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      acceptance_level: ["great", "good", "poor"],
      document_status: ["processing", "available", "failed"],
      meal_type: ["morning_snack", "lunch", "afternoon_snack"],
      user_role: ["admin", "cook"],
    },
  },
} as const

