<template>
  <div>
    <nav aria-label="breadcrumb">
      <ol class="breadcrumb">
        <li class="breadcrumb-item">
          <router-link to="/resources">Resources</router-link>
        </li>
        <li class="breadcrumb-item active" aria-current="page">{{ resource?.name }}</li>
      </ol>
    </nav>

    <div>
      <div v-if="successMessage" class="alert alert-success alert-dismissible">
        {{ successMessage }}
        <button type="button" class="btn-close" @click="store.successMessage = ''" aria-label="Close">
        </button>
      </div>

      <ul class="nav nav-tabs">
        <li class="nav-item">
          <a class="nav-link" :class="{ active: activeTab === 'keys' }" href="#" @click.prevent="activeTab = 'keys'">
            Keys
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" :class="{ active: activeTab === 'data' }" href="#" @click.prevent="activeTab = 'data'">
            Data
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" :class="{ active: activeTab === 'examples' }" href="#" @click.prevent="activeTab = 'examples'">
            Examples
          </a>
        </li>
      </ul>

      <!-- Tab Content -->
      <div class="tab-content mt-3">
        <div v-if="activeTab === 'keys'" class="tab-pane fade show active">
          <ResourceKeys />
        </div>
        <div v-if="activeTab === 'data'" class="tab-pane fade show active">
          <ResourceData />
        </div>
        <div v-if="activeTab === 'examples'" class="tab-pane fade show active">
          <ResourceExamples />
        </div>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref, watch, computed } from "vue";
import { store } from "@/store";
import ResourceKeys from "@/components/ResourceKeys.vue";
import ResourceData from "@/components/ResourceData.vue";
import ResourceExamples from "@/components/ResourceExamples.vue";

const resource = ref(null);

const successMessage = computed(() => store.successMessage);
const activeTab = ref(store.activeResourceTab || "keys");

watch(() => store.successMessage, (newMessage) => {
  if (newMessage) {
    activeTab.value = store.activeResourceTab;
    store.activeResourceTab = "keys"; // Reset to default for next navigation
  }
});

</script>
