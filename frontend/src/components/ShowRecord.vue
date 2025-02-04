<template>
  <div>
    <!-- Breadcrumb -->
    <nav aria-label="breadcrumb">
      <ol class="breadcrumb">
        <li class="breadcrumb-item">
          <router-link to="/resources">Resources</router-link>
        </li>
        <li class="breadcrumb-item">
          <router-link
            :to="`/resources/${route.params.resourceName}`"
            @click="store.activeResourceTab = 'data'"
          >
            {{ route.params.resourceName }}
          </router-link>
        </li>
        <li class="breadcrumb-item active" aria-current="page">Show Record</li>
      </ol>
    </nav>

    <h3>Record Details</h3>

    <table class="table table-bordered">
      <tbody>
        <tr v-for="attribute in attributes" :key="attribute.name">
          <th>{{ attribute.label }}</th>
          <td>{{ record[attribute.name] }}</td>
        </tr>
      </tbody>
    </table>

    <h4>Raw Document</h4>
    <pre class="raw-document" v-html="highlightedJSON"></pre>

    <button class="btn btn-primary me-1" @click="editRecord">Edit</button>
    <button class="btn btn-secondary" @click="goBack">Back</button>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import axios from "axios";
import hljs from "highlight.js";
import "highlight.js/styles/github.css";
import { store } from "@/store";

const route = useRoute();
const router = useRouter();

const attributes = ref([]);
const record = ref({});
const raw_document = ref({});

// Fetch record details
const fetchRecord = async () => {
  try {
    const response = await axios.get(`/api/dashboard/resources/${route.params.resourceName}/data/${route.params.id}`);

    attributes.value = response.data.attributes;
    raw_document.value = response.data.raw_document;
    record.value = response.data.record;
  } catch (error) {
    console.error("Error fetching record:", error);
    router.push(`/resources/${route.params.resourceName}`);
  }
};

const editRecord = () => {
  router.push(`/resources/${route.params.resourceName}/data/${route.params.id}/edit`);
};

const goBack = () => {
  store.activeResourceTab = "data";
  router.push(`/resources/${route.params.resourceName}`);
};

// Format JSON and apply syntax highlighting
const highlightedJSON = computed(() => {
  const jsonStr = JSON.stringify(raw_document.value, null, 2);
  return hljs.highlight(jsonStr, { language: "json" }).value;
});

onMounted(fetchRecord);
</script>

<style scoped>
.raw-document {
  background: #f5f5f5;
  padding: 10px;
  border-radius: 5px;
  font-family: monospace;
  white-space: pre-wrap;
  word-wrap: break-word;
  overflow-x: auto;
  border: 1px solid #ddd;
}
</style>
