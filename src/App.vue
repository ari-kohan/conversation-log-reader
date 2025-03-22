<script setup lang="ts">
import { ref } from 'vue'
import UserSelector from './components/UserSelector.vue'
import ChatHistory from './components/ChatHistory.vue'

const selectedUserId = ref<string | null>(null)

const handleUserSelect = (userId: string) => {
  selectedUserId.value = userId
}
</script>

<template>
  <div class="app-container">
    <header>
      <h1>Chat History Viewer</h1>
    </header>
    
    <main>
      <UserSelector @select-user="handleUserSelect" />
      <ChatHistory :userId="selectedUserId" />
    </main>
  </div>
</template>

<style>
/* Global styles */
body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  line-height: 1.6;
  color: #333;
  background-color: #f9f9f9;
  margin: 0;
  padding: 0;
}

/* App container */
.app-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

header {
  margin-bottom: 2rem;
  text-align: center;
}

h1 {
  color: #2c3e50;
  margin-bottom: 1rem;
}

main {
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  padding: 2rem;
}
</style>
