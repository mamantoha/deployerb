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
        <li class="breadcrumb-item active" aria-current="page">Show Record</li>
      </ol>
    </nav>

    <h3>Record Details</h3>

    <table class="table table-bordered">
      <tbody>
        <tr v-for="attribute in attributes" :key="attribute.name">
          <th>{{ attribute.label }}</th>
          <td>{{ record[attribute.name] }}</td>
        </tr>
      </tbody>
    </table>

    <button class="btn btn-primary" @click="editRecord">Edit</button>
    <button class="btn btn-secondary" @click="goBack">Back</button>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import axios from "axios";

const route = useRoute();
const router = useRouter();

const record = ref({});
const attributes = ref([]);

// Fetch record details
const fetchRecord = async () => {
  try {
    const response = await axios.get(`/api/dashboard/resources/${route.params.resourceName}/data/${route.params.id}`);

    attributes.value = response.data.attributes;
    record.value = response.data.record;
  } catch (error) {
    console.error("Error fetching record:", error);
    router.push(`/resources/${route.params.resourceName}`);
  }
};

const editRecord = () => {
  router.push(`/resources/${route.params.resourceName}/data/${route.params.id}/edit`);
};

const goBack = () => {
  router.push(`/resources/${route.params.resourceName}`);
};

onMounted(fetchRecord);
</script>
