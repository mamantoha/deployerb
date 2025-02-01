<template>
  <div>
    <ol class="breadcrumb">
      <li>
        <router-link to="/resources">Resources</router-link>
      </li>
      <li class="active">{{ resource?.name }}</li>
    </ol>

    <div>
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
        <p>Data tab coming soon...</p>
      </div>
      <div v-if="activeTab === 'examples'">
        <p>Examples tab coming soon...</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import { useRoute } from "vue-router";
import axios from "axios";
import ResourceKeys from "@/components/ResourceKeys.vue";

const route = useRoute();
const resource = ref(null);
const activeTab = ref("keys");
</script>
