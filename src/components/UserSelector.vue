<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase'

const userIds = ref<{ id: string, username: string }[]>([])
const isLoading = ref(true)
const error = ref<string | null>(null)

const emit = defineEmits<{
  (e: 'select-user', userId: string): void
}>()

onMounted(async () => {
  try {
    // Get unique user IDs from the chat_history table
    const { data, error: supabaseError } = await supabase
      .from('profiles')
      .select('id, username')
      .order('id')

    if (supabaseError) throw supabaseError

    // Extract unique user IDs
    userIds.value = data
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to fetch user IDs'
    console.error('Error fetching user IDs:', err)
  } finally {
    isLoading.value = false
  }
})

const selectUser = (userId: string) => {
  emit('select-user', userId)
}
</script>

<template>
  <div class="user-selector">
    <h2>Select a User</h2>
    
    <div v-if="isLoading" class="loading">
      Loading users...
    </div>
    
    <div v-else-if="error" class="error">
      {{ error }}
    </div>
    
    <div v-else-if="userIds.length === 0" class="no-users">
      No users found in the chat history.
    </div>
    
    <div v-else class="user-list">
      <button 
        v-for="user in userIds" 
        :key="user.id"
        @click="selectUser(user.id)"
        class="user-button"
      >
        {{ user.username }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.user-selector {
  margin-bottom: 2rem;
}

.user-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-top: 1rem;
}

.user-button {
  padding: 0.5rem 1rem;
  background-color: #f1f1f1;
  border: 1px solid #ddd;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.user-button:hover {
  background-color: #e0e0e0;
}

.loading, .error, .no-users {
  padding: 1rem;
  margin-top: 1rem;
  border-radius: 4px;
}

.error {
  background-color: #ffebee;
  color: #c62828;
}
</style>
