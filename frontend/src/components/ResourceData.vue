<template>
  <div>
    <h3>Data for {{ resourceName }}</h3>

    <!-- Table displaying resource data -->
    <table class="table table-hover">
      <thead>
        <tr>
          <th v-for="key in columns" :key="key">{{ key }}</th>
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

      <div v-for="key in filteredColumns" :key="key">
        <label>{{ key }}</label>
        <input v-model="newRecord[key]" type="text" class="form-control" />
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

const route = useRoute();
const router = useRouter();

const resourceName = route.params.resourceName;
const data = ref([]);
const columns = ref([]);
const filteredColumns = computed(() => columns.value.filter((key) => key !== "_id"));
const newRecord = ref({});

const validationErrors = ref([]);

// Fetch resource data
const fetchData = async () => {
  try {
    const response = await axios.get(`/api/dashboard/resources/${resourceName}/data`);
    data.value = response.data;

    if (data.value.length > 0) {
      columns.value = Object.keys(data.value[0]); // Get field names dynamically
    }
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
    fetchData();
  } catch (error) {
    console.error("Error deleting record:", error);
  }
};

onMounted(fetchData);
</script>
