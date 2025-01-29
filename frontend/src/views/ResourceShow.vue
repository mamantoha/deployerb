<template>
  <div>
    <!-- Breadcrumb Navigation -->
    <ol class="breadcrumb">
      <li>
        <router-link to="/resources">Resources</router-link>
      </li>
      <li class="active">{{ resource?.name }}</li>
    </ol>

    <div class="panel panel-default">
      <div class="panel-heading">
        <h3 class="panel-title">Resource: {{ resource?.name }}</h3>
      </div>
      <div class="panel-body">
        <p><strong>Resource Name:</strong> {{ resource?.name }}</p>
        <p><strong>Defined Keys:</strong></p>
        <ul v-if="resource?.keys?.length">
          <li v-for="key in resource.keys" :key="key.name">
            {{ key.name }} ({{ key.type }})
          </li>
        </ul>
        <p v-else>No keys defined for this resource.</p>
      </div>
    </div>

    <router-link to="/resources" class="btn btn-secondary">Back to List</router-link>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import { useRoute } from "vue-router";
import axios from "axios";

const route = useRoute();
const resource = ref(null);

const fetchResource = async () => {
  try {
    const response = await axios.get(`/api/dashboard/resources/${route.params.name}`);
    resource.value = response.data;
  } catch (error) {
    console.error("Error fetching resource:", error);
  }
};

onMounted(fetchResource);
</script>
