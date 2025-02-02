<template>
  <div>
    <h3>Data for {{ resourceName }}</h3>

    <!-- Table displaying resource data -->
    <table class="table table-hover">
      <thead>
        <tr>
          <th v-for="attribute in filteredAttributes" :key="attribute.name">
            {{ attribute.name }}
          </th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="record in data" :key="record._id">
          <td v-for="key in columns" :key="key">{{ record[key] }}</td>
          <td>
            <button class="btn btn-primary btn-xs" @click="editRecord(record)">
              Edit
            </button>
            <button class="btn btn-danger btn-xs" @click="deleteRecord(record._id)">
              Delete
            </button>
          </td>
        </tr>
      </tbody>
    </table>

    <!-- Form to add new data -->
    <h4>Add New Record</h4>
    <form @submit.prevent="createRecord">
      <div v-if="validationErrors.length" class="alert alert-danger">
        <ul>
          <li v-for="error in validationErrors" :key="error">{{ error }}</li>
        </ul>
      </div>

      <div class="mb-3" v-for="attribute in filteredAttributes" :key="attribute.name">
        <label>
          {{ attribute.name }}
          <span v-if="attribute.required" class="text-danger">*</span>
        </label>
        <input v-model="newRecord[attribute.name]" type="text" class="form-control" />
      </div>

      <button type="submit" class="btn btn-success">Add</button>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from "vue";
import { useRoute } from "vue-router";
import { useRouter } from "vue-router";
import axios from "axios";
import { store } from "@/store";

const route = useRoute();
const router = useRouter();

const resourceName = route.params.resourceName;

const data = ref([]);
const columns = ref([]);
const attributes = ref([]);
const filteredAttributes = computed(() => attributes.value.filter(attr => attr.name !== "_id"));
const newRecord = ref({});

const validationErrors = ref([]);

// Fetch resource data
const fetchData = async () => {
  try {
    const response = await axios.get(`/api/dashboard/resources/${resourceName}/data`);

    columns.value = response.data.attributes.map(attr => attr.name);
    attributes.value = response.data.attributes;
    data.value = response.data.records;
  } catch (error) {
    console.error("Error fetching data:", error);
  }
};

// Create a new record
const createRecord = async () => {
  try {
    await axios.post(`/api/dashboard/resources/${resourceName}/data`, newRecord.value);
    newRecord.value = {};
    validationErrors.value = [];
    fetchData();
  } catch (error) {
    if (error.response && error.response.status === 422) {
      validationErrors.value = error.response.data.messages;
    } else {
      console.error("Error creating record:", error);
    }
  }
};

// Edit a record
const editRecord = (record) => {
  router.push(`/resources/${route.params.resourceName}/data/${record._id}/edit`);
};

// Delete a record
const deleteRecord = async (id) => {
  if (!confirm("Are you sure you want to delete this record?")) return;

  try {
    await axios.delete(`/api/dashboard/resources/${resourceName}/data/${id}`);

    store.successMessage = "Record deleted successfully!";
    fetchData();
  } catch (error) {
    console.error("Error deleting record:", error);
  }
};

const isRequiredField = (key) => {
  return attributes.value.some(attr => attr.name === key && attr.required);
};

onMounted(fetchData);
</script>
