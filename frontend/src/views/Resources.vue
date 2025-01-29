<template>
  <div>
    <!-- Breadcrumb -->
    <ol class="breadcrumb">
      <li class="active">Resources</li>
    </ol>

    <!-- Panel for Resources -->
    <div class="panel panel-default">
      <div class="panel-heading clearfix">
        <h3 class="panel-title pull-left">Resources</h3>
        <div class="btn-group pull-right">
          <button class="btn btn-primary btn-xs" @click="showModal = true">
            New
          </button>
        </div>
      </div>

      <!-- Table of Resources -->
      <table class="table table-hover">
        <thead>
          <tr>
            <th>Name</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="resource in resources" :key="resource.name">
            <td>
              <router-link :to="'/resources/' + resource.name">
                {{ resource.name }}
              </router-link>
            </td>
            <td class="col-md-1">
              <span class="actions">
                <button
                  class="btn btn-danger btn-xs"
                  @click="confirmDelete(resource.name)"
                >
                  <span class="glyphicon glyphicon-remove"></span> Delete
                </button>
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- New Resource Modal -->
    <div class="modal fade" v-if="showModal">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">New Resource</h5>
            <button type="button" class="close" @click="showModal = false">
              &times;
            </button>
          </div>
          <div class="modal-body">
            <input
              v-model="newResourceName"
              type="text"
              class="form-control"
              placeholder="Resource Name"
            />
          </div>
          <div class="modal-footer">
            <button class="btn btn-secondary" @click="showModal = false">
              Cancel
            </button>
            <button class="btn btn-primary" @click="createResource">
              Create
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div class="modal fade" v-if="showDeleteModal">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Confirm Deletion</h5>
            <button type="button" class="close" @click="showDeleteModal = false">
              &times;
            </button>
          </div>
          <div class="modal-body">
            Are you sure you want to delete <strong>{{ resourceToDelete }}</strong>?
          </div>
          <div class="modal-footer">
            <button class="btn btn-secondary" @click="showDeleteModal = false">
              Cancel
            </button>
            <button class="btn btn-danger" @click="deleteResource">
              Delete
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import axios from "axios";

const resources = ref([]);
const showModal = ref(false);
const newResourceName = ref("");
const showDeleteModal = ref(false);
const resourceToDelete = ref(null);

// Update API calls to use /dashboard/resources
const fetchResources = async () => {
  try {
    const response = await axios.get("/api/dashboard/resources");
    resources.value = response.data.resources; // Adjusted for the new JSON structure
  } catch (error) {
    console.error("Error fetching resources:", error);
  }
};

const createResource = async () => {
  try {
    await axios.post("/api/dashboard/resources", { name: newResourceName.value });
    newResourceName.value = "";
    showModal.value = false;
    fetchResources(); // Refresh the list
  } catch (error) {
    console.error("Error creating resource:", error);
  }
};

const confirmDelete = (name) => {
  resourceToDelete.value = name;
  showDeleteModal.value = true;
};

const deleteResource = async () => {
  try {
    await axios.delete(`/api/dashboard/resources/${resourceToDelete.value}`);
    showDeleteModal.value = false;
    fetchResources(); // Refresh the list
  } catch (error) {
    console.error("Error deleting resource:", error);
  }
};

onMounted(fetchResources);
</script>

<style>
.modal {
  display: block;
  background: rgba(0, 0, 0, 0.4);
}

.modal-dialog {
  top: 20%;
}
</style>
