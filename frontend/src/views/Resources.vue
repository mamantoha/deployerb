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
          <button class="btn btn-primary btn-xs" @click="showNewModal">
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
                  <i class="bi bi-trash"></i>
                </button>
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- New Resource Modal -->
    <div class="modal fade" ref="newResourceModal" v-show="false" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">New Resource</h5>
            <button type="button" class="btn-close" @click="hideNewModal"></button>
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
            <button class="btn btn-secondary" @click="hideNewModal">Cancel</button>
            <button class="btn btn-primary" @click="createResource">Create</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div class="modal fade" ref="deleteResourceModal" v-show="false" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Confirm Deletion</h5>
            <button type="button" class="btn-close" @click="hideDeleteModal"></button>
          </div>
          <div class="modal-body">
            Are you sure you want to delete <strong>{{ resourceToDelete }}</strong>?
          </div>
          <div class="modal-footer">
            <button class="btn btn-secondary" @click="hideDeleteModal">Cancel</button>
            <button class="btn btn-danger" @click="deleteResource">Delete</button>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from "vue";
import axios from "axios";
import { Modal } from "bootstrap"; // Import Bootstrap modal handling

const resources = ref([]);
const newResourceName = ref("");
const resourceToDelete = ref(null);
const newResourceModal = ref(null);
const deleteResourceModal = ref(null);
let newResourceBootstrapModal = null;
let deleteResourceBootstrapModal = null;

// Fetch resources from backend
const fetchResources = async () => {
  try {
    const response = await axios.get("/api/dashboard/resources");
    resources.value = response.data.resources;
  } catch (error) {
    console.error("Error fetching resources:", error);
  }
};

const createResource = async () => {
  if (!newResourceName.value.trim()) {
    console.error("Resource name cannot be empty");
    return;
  }

  try {
    // Send a POST request to create a new resource
    const response = await axios.post("/api/dashboard/resources", {
      name: newResourceName.value.trim(),
    });

    console.log("Resource created:", response.data);

    // Clear input field and close modal
    newResourceName.value = "";
    hideNewModal();

    // Refresh the list
    fetchResources();
  } catch (error) {
    console.error("Error creating resource:", error.response?.data || error.message);
  }
};

// Show "New Resource" modal
const showNewModal = async () => {
  await nextTick(); // Ensure DOM updates before initializing modal
  if (newResourceBootstrapModal) {
    newResourceBootstrapModal.show();
  }
};

// Hide "New Resource" modal
const hideNewModal = () => {
  if (newResourceBootstrapModal) {
    newResourceBootstrapModal.hide();
  }
};

// Show "Delete Resource" modal
const confirmDelete = async (name) => {
  resourceToDelete.value = name;
  await nextTick(); // Ensure DOM updates before showing modal
  if (deleteResourceBootstrapModal) {
    deleteResourceBootstrapModal.show();
  }
};

// Hide "Delete Resource" modal
const hideDeleteModal = () => {
  if (deleteResourceBootstrapModal) {
    deleteResourceBootstrapModal.hide();
  }
};

// Delete resource
const deleteResource = async () => {
  try {
    await axios.delete(`/api/dashboard/resources/${resourceToDelete.value}`);
    hideDeleteModal(); // Close the modal after deletion
    fetchResources(); // Refresh the list
  } catch (error) {
    console.error("Error deleting resource:", error);
  }
};

// Initialize Bootstrap modals on component mount
onMounted(async () => {
  await nextTick(); // Ensure DOM updates before initializing Bootstrap
  newResourceBootstrapModal = new Modal(newResourceModal.value);
  deleteResourceBootstrapModal = new Modal(deleteResourceModal.value);
  fetchResources();
});

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
