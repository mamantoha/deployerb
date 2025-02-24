<template>
  <div>
    <!-- Breadcrumb -->
    <nav aria-label="breadcrumb">
      <ol class="breadcrumb">
        <li class="breadcrumb-item">
          <router-link to="/resources">Resources</router-link>
        </li>
        <li class="breadcrumb-item">
          <router-link
            :to="`/resources/${route.params.resourceName}`"
            @click="store.activeResourceTab = 'data'"
          >
            {{ route.params.resourceName }}
          </router-link>
        </li>
        <li class="breadcrumb-item active" aria-current="page">Edit Record</li>
      </ol>
    </nav>

    <h3>Edit {{ route.params.resourceName }}</h3>
    <h4>ID: <span class="badge bg-secondary">{{ record._id }}</span></h4>
    <RecordForm
      :record="record"
      :attributes="attributes"
      :validationErrors="validationErrors"
      :showResetButton="true"
      @submit="updateRecord"
      @cancel="cancelEdit"
      @reset="resetForm"
    />

  </div>
</template>

<script setup>
import { ref, onMounted, computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import { store } from "@/store";
import RecordForm from "@/components/RecordForm.vue";
import { resourceApi } from "@/api/resourceApi";

const route = useRoute();
const router = useRouter();
const record = ref({});
const originalRecord = ref({});
const attributes = ref([]);

const validationErrors = ref({});

const editableRecord = computed(() => {
  const newRecord = { ...record.value };
  delete newRecord._id;
  return newRecord;
});

// Fetch record details
const fetchRecord = async () => {
  try {
    const response = await resourceApi.fetchRecord(route.params.resourceName, route.params.id);

    attributes.value = response.data.attributes;

    record.value = Object.entries(response.data.record).reduce((acc, [key, value]) => {
      acc[key] = value !== null && typeof value === "object" ? JSON.stringify(value) : value;
      return acc;
    }, {});

    originalRecord.value = { ...record.value };
  } catch (error) {
    console.error("Error fetching record:", error);
    router.push(`/resources/${route.params.resourceName}`);
  }
};

// Update record
const updateRecord = async () => {
  try {
    const recordData = { ...editableRecord.value };

    await resourceApi.updateRecord(route.params.resourceName, route.params.id, recordData);

    validationErrors.value = {};

    store.successMessage = "Record updated successfully!";
    store.activeResourceTab = "data";

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
  store.activeResourceTab = "data";
  router.push(`/resources/${route.params.resourceName}`);
};

// Reset form to original values
const resetForm = () => {
  record.value = { ...originalRecord.value };
  validationErrors.value = {};
};

onMounted(fetchRecord);
</script>
