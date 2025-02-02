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
        <li class="breadcrumb-item active" aria-current="page">Edit Key</li>
      </ol>
    </nav>

    <h3>Edit Key: {{ key.name }}</h3>
    <form @submit.prevent="updateKey" class="form-horizontal">
      <div class="form-group">
        <label for="keyName">Key Name</label>
        <input id="keyName" v-model="key.name" type="text" class="form-control" disabled />
      </div>

      <div class="form-group">
        <label for="keyType">Type</label>
        <select id="keyType" v-model="key.type" class="form-control">
          <option v-for="type in availableTypes" :key="type" :value="type">
            {{ type }}
          </option>
        </select>
      </div>

      <div class="panel panel-default">
        <div class="panel-heading">Validations</div>
        <div class="panel-body">
          <div class="checkbox">
            <label>
              <input type="checkbox" v-model="key.validations.presence" />
              Required
            </label>
          </div>
          <div class="checkbox">
            <label>
              <input type="checkbox" v-model="key.validations.uniqueness" />
              Unique
            </label>
          </div>
        </div>
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
import { store } from "@/store";

const route = useRoute();
const router = useRouter();

const key = ref({
  name: "",
  type: "",
  validations: { presence: false, uniqueness: false },
});

const availableTypes = ref([
  "String",
  "Integer",
  "Boolean",
  "Float",
  "Date",
  "Time",
  "Array",
  "Hash",
]);

const validationErrors = ref([]);

// Fetch the key details
const fetchKey = async () => {
  try {
    const response = await axios.get(
      `/api/dashboard/resources/${route.params.resourceName}/${route.params.keyName}`
    );

    key.value = {
      name: response.data.name,
      type: response.data.type,
      validations: {
        presence: response.data.validations?.includes("presence") || false,
        uniqueness: response.data.validations?.includes("uniqueness") || false,
      },
    };
  } catch (error) {
    console.error("Error fetching key:", error);
    router.push(`/resources/${route.params.resourceName}`);
  }
};

// Update the key
const updateKey = async () => {
  try {
    await axios.put(
      `/api/dashboard/resources/${route.params.resourceName}/${route.params.keyName}`,
      {
        type: key.value.type,
        validations: [
          key.value.validations.presence ? "presence" : null,
          key.value.validations.uniqueness ? "uniqueness" : null,
        ].filter(Boolean), // Remove null values
      }
    );

    validationErrors.value = [];

    store.successMessage = "Key updated successfully!";
    store.redirectTab = "keys";

    router.push(`/resources/${route.params.resourceName}`);
  } catch (error) {
    if (error.response && error.response.status === 422) {
      validationErrors.value = error.response.data.messages;
    } else {
      console.error("Error updating key:", error);
    }
  }
};

const cancelEdit = () => {
  store.redirectTab = "keys";
  router.push(`/resources/${route.params.resourceName}`);
};

onMounted(fetchKey);
</script>
