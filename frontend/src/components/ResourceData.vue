<template>
  <div>
    <!-- Form to add new data -->
    <div class="card">
      <div
        class="card-header d-flex justify-content-between align-items-center"
        data-bs-toggle="collapse"
        data-bs-target="#collapseForm"
        role="button"
        aria-expanded="false"
        aria-controls="collapseForm"
        @click="toggleCollapse"
      >
        <span>Add New {{ resourceName }}</span>
        <span class="collapse-icon">{{ isCollapsed ? "▼" : "▲" }}</span>
      </div>
      <div class="card-body collapse" id="collapseForm">
        <RecordForm
          :record="newRecord"
          :attributes="attributes"
          :validationErrors="validationErrors"
          :showResetButton="false"
          @submit="createRecord"
          @cancel="resetForm"
        />
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div class="modal fade" id="deleteModal" v-show="false" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Confirm Deletion</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body">
            Are you sure you want to delete this record?
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-danger" @click="confirmDelete">Delete</button>
          </div>
        </div>
      </div>
    </div>

    <div>
      <h4>Data for {{ resourceName }}</h4>

      <!-- Filter Section -->
      <div class="row mb-3">
        <div class="col-md-4">
          <label for="filterField">Filter By</label>
          <select v-model="filterField" class="form-control">
            <option value="" disabled selected>Select a field</option>
            <option v-for="attribute in attributes" :key="attribute.name" :value="attribute.name">
              {{ attribute.label }}
            </option>
          </select>
        </div>
        <div class="col-md-6">
          <label for="filterValue">Search Value</label>
          <input
            v-model="filterValue"
            class="form-control"
            type="text"
            placeholder="Enter value..."
            @keyup.enter="applyFilter"
          />
        </div>
        <div class="col-md-2 d-flex align-items-end">
          <button class="btn btn-primary me-2" @click="applyFilter">Filter</button>
          <button class="btn btn-secondary" @click="clearFilters">Clear</button>
        </div>
      </div>

      <!-- Table displaying resource data -->
      <div class="table-responsive" v-if="data.length">
        <table class="table table-hover">
          <thead>
            <tr>
              <th
                v-for="attribute in attributes"
                :key="attribute.name"
                @click="sortBy(attribute.name)"
                class="sortable"
              >
                {{ attribute.label }}
                <span v-if="sortColumn === attribute.name">
                  {{ sortOrder === "asc" ? "▲" : "▼" }}
                </span>
              </th>
              <th class="fixed-column">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="record in data" :key="record._id" :id="`record-${record._id}`">
              <td v-for="key in columns" :key="key">{{ record[key] }}</td>

              <td class="fixed-column">
                <div class="btn-group btn-group-xs" role="group">
                  <button class="btn btn-info" @click="showRecord(record)">
                    Show
                  </button>
                  <button class="btn btn-primary" @click="editRecord(record)">
                    Edit
                  </button>
                  <button class="btn btn-danger" @click="openDeleteModal(record)">
                    Delete
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

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
import { Collapse } from "bootstrap";
import { Modal } from "bootstrap";
import { store } from "@/store";
import RecordForm from "@/components/RecordForm.vue";
import { resourceApi } from "@/api/resourceApi";

const route = useRoute();
const router = useRouter();

const resourceName = route.params.resourceName;

const data = ref([]);
const columns = ref([]);
const attributes = ref([]);
const newRecord = ref({});

const sortColumn = ref("_id");
const sortOrder = ref("asc");

const filterField = ref("");
const filterValue = ref("");

const validationErrors = ref({});

const currentPage = ref(1);
const perPage = ref(5);
const pagination = ref({ total_pages: 1, total_records: 0, current_page: 1 });

let collapseInstance = null;
const isCollapsed = ref(data.length === 0);

const recordToDelete = ref(null);
let deleteModalInstance = null;

// Fetch resource data
const fetchData = async () => {
  try {
    const response = await resourceApi.fetchRecords(resourceName, {
      page: currentPage.value,
      per_page: perPage.value,
      sort_by: sortColumn.value,
      sort_order: sortOrder.value,
      filter_field: filterField.value,
      filter_value: filterValue.value,
    });

    columns.value = response.data.attributes.map(attr => attr.name);
    attributes.value = response.data.attributes;
    data.value = response.data.records;
    pagination.value = response.data.pagination;
  } catch (error) {
    console.error("Error fetching data:", error);
  }
};

const applyFilter = () => {
  currentPage.value = 1;
  fetchData();
};

const clearFilters = () => {
  filterField.value = "";
  filterValue.value = "";
  fetchData();
};

const sortBy = (column) => {
  if (sortColumn.value === column) {
    sortOrder.value = sortOrder.value === "asc" ? "desc" : "asc";
  } else {
    sortColumn.value = column;
    sortOrder.value = "asc";
  }

  fetchData();
};

// Create a new record
const createRecord = async () => {
  try {
    await resourceApi.createRecord(resourceName, newRecord.value);
    store.activeResourceTab = "data";
    newRecord.value = {};
    validationErrors.value = [];
    fetchData();
    store.successMessage = "Record created successfully!";

    if (collapseInstance) {
      collapseInstance.hide();
    }
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

  if (collapseInstance) {
    collapseInstance.hide();
  }
};

// Show a record
const showRecord = (record) => {
  router.push(`/resources/${resourceName}/data/${record._id}`);
};

// Edit a record
const editRecord = (record) => {
  router.push(`/resources/${route.params.resourceName}/data/${record._id}/edit`);
};

const openDeleteModal = (record) => {
  recordToDelete.value = record;

  // Initialize & Show Bootstrap Modal
  if (!deleteModalInstance) {
    deleteModalInstance = new Modal(document.getElementById("deleteModal"));
  }
  deleteModalInstance.show();
};

const hideDeleteModal = () => {
  if (deleteModalInstance) {
    deleteModalInstance.hide();
  }
};

// Confirm Deletion
const confirmDelete = async () => {
  if (!recordToDelete.value) return;

  try {
    await resourceApi.deleteRecord(resourceName, recordToDelete.value._id);
    store.activeResourceTab = "data";
    store.successMessage = "Record deleted successfully!";
    fetchData();
    hideDeleteModal();
  } catch (error) {
    console.error("Error deleting record:", error);
  }
};

const changePage = (page) => {
  if (page < 1 || page > pagination.value.total_pages) return;
  currentPage.value = page;
  fetchData();
};

onMounted(() => {
  fetchData();

  const collapseElement = document.getElementById("collapseForm");
  if (collapseElement) {
    collapseInstance = new Collapse(collapseElement, { toggle: false });

    // Listen to Bootstrap collapse events
    collapseElement.addEventListener("show.bs.collapse", () => {
      isCollapsed.value = false;
    });
    collapseElement.addEventListener("hide.bs.collapse", () => {
      isCollapsed.value = true;
    });
  }
});

const toggleCollapse = () => {
  if (collapseInstance) {
    isCollapsed.value ? collapseInstance.show() : collapseInstance.hide();
  }
};
</script>

<style scoped>
/* Enable horizontal scrolling */
.table-responsive {
  overflow-x: auto;
  max-width: 100%;
}

/* Ensure the last column (Actions) is always visible */
.fixed-column {
  position: sticky;
  right: 0;
  z-index: 2;
  min-width: 150px;
  text-align: center;
}

/* Add shadow effect when scrolling */
.table-responsive::-webkit-scrollbar {
  height: 8px;
}

.table-responsive::-webkit-scrollbar-thumb {
  background: #bbb;
  border-radius: 4px;
}

.table-responsive::-webkit-scrollbar-track {
  background: #f5f5f5;
}

.card {
  margin-bottom: 10px;
}
</style>
