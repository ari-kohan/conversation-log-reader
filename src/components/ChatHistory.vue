<script setup lang="ts">
import { ref, watch } from 'vue'
import { supabase } from '../lib/supabase'
import type { Database } from '../../types/supabase'

type ChatMessage = Database['public']['Tables']['chat_history']['Row']

const props = defineProps<{
  userId: string | null
}>()

const messages = ref<ChatMessage[]>([])
const isLoading = ref(false)
const error = ref<string | null>(null)

// Fetch chat history when userId changes
watch(() => props.userId, async (newUserId) => {
  if (!newUserId) {
    messages.value = []
    return
  }
  
  isLoading.value = true
  error.value = null
  
  try {
    console.log('user id', newUserId)
    const { data, error: supabaseError } = await supabase
      .from('chat_history')
      .select('*')
      .limit(100)
      .eq('user_id', newUserId)
      .order('created_at', { ascending: false })
    
    if (supabaseError) throw supabaseError
    
    messages.value = data.reverse() || []
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to fetch chat history'
    console.error('Error fetching chat history:', err)
  } finally {
    isLoading.value = false
  }
}, { immediate: true })

// Format date from ISO string
const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleString()
}
</script>

<template>
  <div class="chat-history">
    <div v-if="!userId" class="no-selection">
      Please select a user to view their chat history.
    </div>
    
    <div v-else>
      <h2>Chat History for User: {{ userId }}</h2>
      
      <div v-if="isLoading" class="loading">
        Loading chat history...
      </div>
      
      <div v-else-if="error" class="error">
        {{ error }}
      </div>
      
      <div v-else-if="messages.length === 0" class="no-messages">
        No chat messages found for this user.
      </div>
      
      <div v-else class="messages">
        <div 
          v-for="message in messages" 
          :key="message.id"
          :class="['message', message.is_ai ? 'ai-message' : 'user-message']"
        >
          <div class="message-header">
            <span class="sender">{{ message.is_ai ? 'Agent' : 'User' }}</span>
            <span class="timestamp">{{ formatDate(message.created_at) }}</span>
          </div>
          <div class="message-content">
            {{ message.message }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.chat-history {
  max-width: 800px;
  margin: 0 auto;
}

.messages {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-top: 1rem;
}

.message {
  padding: 1rem;
  border-radius: 8px;
  max-width: 80%;
}

.user-message {
  align-self: flex-end;
  background-color: #e3f2fd;
  border: 1px solid #bbdefb;
}

.ai-message {
  align-self: flex-start;
  background-color: #f5f5f5;
  border: 1px solid #e0e0e0;
}

.message-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.5rem;
  font-size: 0.8rem;
  color: #666;
}

.message-content {
  white-space: pre-wrap;
}

.loading, .error, .no-messages, .no-selection {
  padding: 1rem;
  margin-top: 1rem;
  border-radius: 4px;
  text-align: center;
}

.error {
  background-color: #ffebee;
  color: #c62828;
}

.no-selection {
  background-color: #f5f5f5;
  font-style: italic;
}
</style>
