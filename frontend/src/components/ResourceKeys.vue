<template>
  <div class="panel panel-default">
    <div class="panel-body">
      <table class="table table-hover">
        <thead>
          <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Validations</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="key in keys" :key="key.name">
            <td class="col-md-4">
              {{ key.name }}
            </td>
            <td class="col-md-2">{{ key.type }}</td>
            <td class="col-md-2">
              <span class="options">
                <span v-if="key.required" class="label label-default">Required</span>
                <span v-if="key.unique" class="label label-default">Unique</span>
              </span>
            </td>
            <td class="col-md-1">
              <span class="actions">
                <button class="btn btn-primary btn-xs" @click="editKey(key)">
                  <span class="glyphicon glyphicon-edit"></span> Edit
                </button>

                <button class="btn btn-danger btn-xs" @click="confirmDeleteKey(key.name)">
                  <span class="glyphicon glyphicon-remove"></span> Delete
                </button>
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>

  <!-- Add New Key Form -->
  <div class="panel panel-default">
    <div class="panel-heading">
      <h3 class="panel-title">Add New Key</h3>
    </div>
    <div class="panel-body">
      <form @submit.prevent="addKey" class="form-horizontal">
        <div class="form-group">
          <div class="col-sm-2">
            <select v-model="newKey.type" class="form-control" required>
              <option value="" disabled selected>Type</option>
              <option v-for="type in availableTypes" :key="type" :value="type">
                {{ type }}
              </option>
            </select>
          </div>
          <div class="col-sm-10">
            <input v-model="newKey.name" type="text" class="form-control" placeholder="Enter name" required />
          </div>
        </div>
        <div class="panel panel-default">
          <div class="panel-heading">Validations</div>
          <div class="panel-body">
            <div class="checkbox">
              <label>
                <input type="checkbox" v-model="newKey.validations.presence" />
                Required
              </label>
            </div>
            <div class="checkbox">
              <label>
                <input type="checkbox" v-model="newKey.validations.uniqueness" />
                Unique
              </label>
            </div>
          </div>
        </div>
        <div class="col-sm-offset-2 col-sm-10">
          <div class="form-group" style="float: right">
            <button type="submit" class="btn btn-primary">
              <span class="glyphicon glyphicon-plus"></span> Add
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import axios from "axios";
import { useRouter, useRoute } from "vue-router";

const router = useRouter();
const route = useRoute();
const keys = ref([]);
const availableTypes = ref([
  "String",
  "Integer",
  "Boolean",
  "Float",
  "Date",
  "Time",
  "Array",
  "Hash",
]); // Available types from backend

const newKey = ref({
  name: "",
  type: "",
  validations: { presence: false, uniqueness: false },
});

// Fetch keys for this resource
const fetchKeys = async () => {
  try {
    const response = await axios.get(`/api/dashboard/resources/${route.params.name}`);

    if (response.data.keys) {
      keys.value = response.data.keys.map((key) => ({
        name: key.name,
        type: key.type,
        required: key.validations?.includes("presence") || false,
        unique: key.validations?.includes("uniqueness") || false,
      }));
    } else {
      keys.value = [];
    }

    console.log("Fetched keys:", keys.value);
  } catch (error) {
    console.error("Error fetching resource keys:", error);
  }
};

// Add a new key
const addKey = async () => {
  if (!newKey.value.name || !newKey.value.type) {
    console.error("Key name and type are required.");
    return;
  }

  try {
    // Build the validations array correctly
    const validations = [];
    if (newKey.value.validations.presence) validations.push("presence");
    if (newKey.value.validations.uniqueness) validations.push("uniqueness");

    const response = await axios.post(`/api/dashboard/resources/${route.params.name}`, {
      name: newKey.value.name.trim(),
      type: newKey.value.type,
      validations,
    });

    console.log("New key added:", response.data);

    // Manually add the new key to the list to update the UI instantly
    keys.value.push({
      name: newKey.value.name,
      type: newKey.value.type,
      required: newKey.value.validations.presence,
      unique: newKey.value.validations.uniqueness,
    });

    // Reset form
    newKey.value = { name: "", type: "", validations: { presence: false, uniqueness: false } };

  } catch (error) {
    console.error("Error adding key:", error.response?.data || error.message);
  }
};

const editKey = (key) => {
  router.push(`/resources/${route.params.name}/${key.name}/edit`);
};

// Delete a key
const confirmDeleteKey = async (keyName) => {
  if (!confirm(`Are you sure you want to delete the key '${keyName}'?`)) return;

  try {
    await axios.delete(`/api/dashboard/resources/${route.params.name}/${keyName}`);
    fetchKeys(); // Refresh the list after deletion
  } catch (error) {
    console.error("Error deleting key:", error);
  }
};

onMounted(fetchKeys);
</script>
