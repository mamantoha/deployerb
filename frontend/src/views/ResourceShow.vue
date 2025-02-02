<template>
  <div>
    <ol class="breadcrumb">
      <li>
        <router-link to="/resources">Resources</router-link>
      </li>
      <li class="active">{{ resource?.name }}</li>
    </ol>

    <div>
      <div v-if="successMessage" class="alert alert-success alert-dismissible">
        {{ successMessage }}
        <button type="button" class="btn-close" @click="store.successMessage = ''" data-bs-dismiss="alert" aria-label="Close">
        </button>
      </div>

      <ul class="nav nav-tabs">
        <li :class="{ active: activeTab === 'keys' }">
          <a href="#" @click="activeTab = 'keys'">Keys</a>
        </li>
        <li :class="{ active: activeTab === 'data' }">
          <a href="#" @click="activeTab = 'data'">Data</a>
        </li>
        <li :class="{ active: activeTab === 'examples' }">
          <a href="#" @click="activeTab = 'examples'">Examples</a>
        </li>
      </ul>

      <div v-if="activeTab === 'keys'">
        <ResourceKeys />
      </div>
      <div v-if="activeTab === 'data'">
        <ResourceData />
      </div>
      <div v-if="activeTab === 'examples'">
        <p>Examples tab coming soon...</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, computed } from "vue";
import { useRoute } from "vue-router";
import axios from "axios";
import { store } from "@/store";
import ResourceKeys from "@/components/ResourceKeys.vue";
import ResourceData from "@/components/ResourceData.vue";

const route = useRoute();
const resource = ref(null);

const successMessage = computed(() => store.successMessage);
const activeTab = ref("data");

// Fetch resource details
const fetchResource = async () => {
  try {
    const response = await axios.get(`/api/dashboard/resources/${route.params.resourceName}`);
    resource.value = response.data;
  } catch (error) {
    console.error("Error fetching resource:", error);
  }
};

// Watch for query changes and update active tab
watch(() => route.query.tab, (newTab) => {
  if (newTab) activeTab.value = newTab;
});

onMounted(fetchResource);
</script>
