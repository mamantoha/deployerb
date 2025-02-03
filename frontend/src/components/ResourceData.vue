<template>
  <div>
    <!-- Form to add new data -->
    <div class="card">
      <div class="card-header">
        Add new {{ resourceName }}
      </div>
      <div class="card-body">
        <RecordForm
          :record="newRecord"
          :attributes="attributes"
          :validationErrors="validationErrors"
          @submit="createRecord"
          @cancel="resetForm"
        />
      </div>
    </div>

    <!-- Table displaying resource data -->
    <h4>Data for {{ resourceName }}</h4>
    <table class="table table-hover">
      <thead>
        <tr>
          <th v-for="attribute in attributes" :key="attribute.name">
            {{ attribute.label }}
          </th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="record in data" :key="record._id" :id="`record-${record._id}`">
          <td v-for="key in columns" :key="key">{{ record[key] }}</td>

          <td>
            <div class="btn-group btn-group-xs" role="group">
              <button class="btn btn-info" @click="showRecord(record)">
                Show
              </button>
              <button class="btn btn-primary" @click="editRecord(record)">
                Edit
              </button>
              <button class="btn btn-danger" @click="deleteRecord(record)">
                Delete
              </button>
            </div>
          </td>
        </tr>
      </tbody>
    </table>

    <!-- Pagination -->
    <nav aria-label="Page navigation" v-if="pagination.total_pages > 1">
      <ul class="pagination">
        <li class="page-item" :class="{ disabled: pagination.current_page === 1 }">
          <button class="page-link" @click="changePage(pagination.current_page - 1)">
            Previous
          </button>
        </li>

        <li v-for="page in pagination.total_pages" :key="page" class="page-item" :class="{ active: pagination.current_page === page }">
          <button class="page-link" @click="changePage(page)">
            {{ page }}
          </button>
        </li>

        <li class="page-item" :class="{ disabled: pagination.current_page === pagination.total_pages }">
          <button class="page-link" @click="changePage(pagination.current_page + 1)">
            Next
          </button>
        </li>
      </ul>
    </nav>

  </div>
</template>

<script setup>
import { ref, onMounted, computed } from "vue";
import { useRoute } from "vue-router";
import { useRouter } from "vue-router";
import axios from "axios";
import { store } from "@/store";
import RecordForm from "@/components/RecordForm.vue";

const route = useRoute();
const router = useRouter();

const resourceName = route.params.resourceName;

const data = ref([]);
const columns = ref([]);
const attributes = ref([]);
const newRecord = ref({});

const validationErrors = ref([]);

const currentPage = ref(1);
const perPage = ref(5);
const pagination = ref({ total_pages: 1, total_records: 0, current_page: 1 });

// Fetch resource data
const fetchData = async () => {
  try {
    const response = await axios.get(`/api/dashboard/resources/${resourceName}/data`, {
      params: { page: currentPage.value, per_page: perPage.value }
    });

    columns.value = response.data.attributes.map(attr => attr.name);
    attributes.value = response.data.attributes;
    data.value = response.data.records;
    pagination.value = response.data.pagination;
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
    store.successMessage = "Record created successfully!";
  } catch (error) {
    if (error.response && error.response.status === 422) {
      validationErrors.value = error.response.data.messages;
    } else {
      console.error("Error creating record:", error);
    }
  }
};

const resetForm = () => {
  newRecord.value = {};
  validationErrors.value = [];
};

// Show a record
const showRecord = (record) => {
  router.push(`/resources/${resourceName}/data/${record._id}`);
};

// Edit a record
const editRecord = (record) => {
  router.push(`/resources/${route.params.resourceName}/data/${record._id}/edit`);
};

// Delete a record
const deleteRecord = async (record) => {
  if (!confirm("Are you sure you want to delete this record?")) return;

  try {
    await axios.delete(`/api/dashboard/resources/${resourceName}/data/${record._id}`);

    store.successMessage = "Record deleted successfully!";
    fetchData();
  } catch (error) {
    console.error("Error deleting record:", error);
  }
};

const changePage = (page) => {
  if (page < 1 || page > pagination.value.total_pages) return;
  currentPage.value = page;
  fetchData();
};

onMounted(fetchData);
</script>
