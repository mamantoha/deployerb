<template>
  <div>
    <!-- Breadcrumb -->
    <nav aria-label="breadcrumb">
      <ol class="breadcrumb">
        <li class="breadcrumb-item">
          <router-link to="/resources">Resources</router-link>
        </li>
        <li class="breadcrumb-item">
          <router-link :to="`/resources/${route.params.resourceName}`">{{ route.params.resourceName }}</router-link>
        </li>
        <li class="breadcrumb-item active" aria-current="page">Edit Record</li>
      </ol>
    </nav>

    <h3>ID: {{ record._id }}</h3>
    <form @submit.prevent="updateRecord">
      <div v-if="validationErrors.length" class="alert alert-danger">
        <ul>
          <li v-for="error in validationErrors" :key="error">{{ error }}</li>
        </ul>
      </div>

      <div class="mb-3" v-for="(value, key) in filteredRecord" :key="key">
        <label>{{ key }}</label>
        <input v-model="filteredRecord[key]" type="text" class="form-control" />
      </div>

      <button type="submit" class="btn btn-primary">Save</button>
      <button @click="cancelEdit" class="btn btn-secondary">Cancel</button>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import axios from "axios";
import { store } from "@/store";

const route = useRoute();
const router = useRouter();
const record = ref({});

const validationErrors = ref([]);

const filteredRecord = computed(() => {
  const newRecord = { ...record.value };
  delete newRecord._id;
  return newRecord;
});

// Fetch record details
const fetchRecord = async () => {
  try {
    const response = await axios.get(
      `/api/dashboard/resources/${route.params.resourceName}/data/${route.params.id}`
    );
    record.value = response.data;
  } catch (error) {
    console.error("Error fetching record:", error);
    router.push(`/resources/${route.params.resourceName}`);
  }
};

// Update record
const updateRecord = async () => {
  try {
    const recordData = { ...filteredRecord.value };
    await axios.put(
      `/api/dashboard/resources/${route.params.resourceName}/data/${route.params.id}`,
      recordData
    );

    validationErrors.value = [];

    store.successMessage = "Record updated successfully!";
    store.redirectTab = "data";

    router.push(`/resources/${route.params.resourceName}`);
  } catch (error) {
    if (error.response && error.response.status === 422) {
      validationErrors.value = error.response.data.messages;
    } else {
      console.error("Error updating record:", error);
    }
  }
};


// Cancel edit and return to the resource data list
const cancelEdit = () => {
  store.redirectTab = "data";
  router.push(`/resources/${route.params.resourceName}`);
};

onMounted(fetchRecord);
</script>
