<template>
  <div>
    <h3>Edit Record</h3>
    <form @submit.prevent="updateRecord">
      <div v-for="(value, key) in record" :key="key">
        <label>{{ key }}</label>
        <input v-model="record[key]" type="text" class="form-control" />
      </div>
      <button type="submit" class="btn btn-primary">Save</button>
      <button @click="cancelEdit" class="btn btn-secondary">Cancel</button>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import axios from "axios";

const route = useRoute();
const router = useRouter();
const record = ref({});

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
    await axios.put(
      `/api/dashboard/resources/${route.params.resourceName}/data/${route.params.id}`,
      record.value
    );
    router.push(`/resources/${route.params.resourceName}`);
  } catch (error) {
    console.error("Error updating record:", error);
  }
};

// Cancel edit and return to the resource data list
const cancelEdit = () => {
  router.push(`/resources/${route.params.resourceName}`);
};

onMounted(fetchRecord);
</script>
