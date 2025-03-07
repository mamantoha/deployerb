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
    <h4>ID: <span class="badge bg-secondary">{{ record._id }}</span></h4>

    <div v-if="validationErrors.length" class="alert alert-danger">
      <h5>Validation Errors</h5>
      <ul>
        <li v-for="error in validationErrors" :key="error">{{ error }}</li>
      </ul>
    </div>

    <table class="table table-bordered">
      <tbody>
        <tr v-for="attribute in attributes" :key="attribute.name">
          <th>{{ attribute.label }}</th>
          <td>{{ record[attribute.name] }}</td>
        </tr>
      </tbody>
    </table>

    <div>
      <h4>Raw Document</h4>
      <div class="code-container">
        <button class="copy-btn" @click="copyToClipboard">
          <i :class="copied ? 'bi bi-clipboard-check' : 'bi bi-clipboard'"></i>
        </button>
        <pre class="raw-document" v-html="highlightedJSON"></pre>
      </div>
    </div>

    <button class="btn btn-primary me-1" @click="editRecord">Edit</button>
    <button class="btn btn-secondary" @click="goBack">Back</button>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import hljs from "highlight.js";
import { store } from "@/store";
import { resourceApi } from "@/api/resourceApi";

const route = useRoute();
const router = useRouter();

const attributes = ref([]);
const record = ref({});
const raw_document = ref({});
const validationErrors = ref([]);

const documentJSON = computed(() => JSON.stringify(raw_document.value, null, 2));

// Fetch record details
const fetchRecord = async () => {
  try {
    const response = await resourceApi.fetchRecord(route.params.resourceName, route.params.id);

    attributes.value = response.data.attributes;
    raw_document.value = response.data.document;
    record.value = response.data.record;
    validationErrors.value = response.data.errors;
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
  return hljs.highlight(documentJSON.value, { language: "json" }).value;
});

const loadHighlightTheme = (theme) => {
  const oldTheme = document.getElementById("hljs-theme");
  if (oldTheme) oldTheme.remove(); // Remove previous theme

  // Dynamically create a new <link> element for the theme
  const newTheme = document.createElement("link");
  newTheme.id = "hljs-theme";
  newTheme.rel = "stylesheet";
  newTheme.href = theme === "dark-theme"
    ? "/hljs-themes/github-dark.min.css"
    : "/hljs-themes/github.min.css";

  document.head.appendChild(newTheme); // Apply new theme
};

const copied = ref(false);
const copyToClipboard = () => {
  navigator.clipboard.writeText(documentJSON.value).then(() => {
    copied.value = true;
    setTimeout(() => (copied.value = false), 1500);
  });
};

onMounted(() => {
  fetchRecord();
  loadHighlightTheme(store.theme);
});

watch(() => store.theme, (newTheme) => {
  console.log("Theme changed to:", newTheme);
  loadHighlightTheme(newTheme);
});
</script>

<style scoped>
.raw-document {
  padding: 10px;
  border-radius: 5px;
  font-family: monospace;
  white-space: pre-wrap;
  word-wrap: break-word;
  overflow-x: auto;
}

[data-bs-theme="light"] .raw-document {
  background: #f5f5f5;
  color: #24292e;
  border: 1px solid #ddd;
}

[data-bs-theme="dark"] .raw-document {
  background: #1D1D1D;
  color: #c9d1d9;
  border-color: #30363d;
}

.code-container {
  position: relative;
}

.copy-btn {
  position: absolute;
  top: 10px;
  right: 10px;
  border: none;
  background: #007bff;
  color: white;
  padding: 5px 10px;
  border-radius: 5px;
  font-size: 14px;
  cursor: pointer;
}

.copy-btn:hover {
  background: #0056b3;
}
</style>
