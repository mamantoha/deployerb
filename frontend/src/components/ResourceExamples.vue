<template>
  <div>
    <h3>API Examples for {{ resourceName }}</h3>
    <div class="well">
      <p>You can use the following API requests to interact with this resource:</p>
      <p><strong>Base URL:</strong> http://api.{{ baseUrl }}/dashboard/resources/{{ resourceName }}</p>
    </div>

    <table class="table">
      <thead>
        <tr>
          <th>Task</th>
          <th>Method</th>
          <th>URL</th>
          <th>Accepts</th>
          <th>Returns</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>List all records</td>
          <td><span class="badge bg-info">GET</span></td>
          <td>/{{ resourceName }}</td>
          <td>Nothing</td>
          <td>An array of objects</td>
        </tr>
        <tr>
          <td>Create a record</td>
          <td><span class="badge bg-success">POST</span></td>
          <td>/{{ resourceName }}</td>
          <td>A JSON object</td>
          <td>The created object</td>
        </tr>
        <tr>
          <td>Retrieve a single record</td>
          <td><span class="badge bg-info">GET</span></td>
          <td>/{{ resourceName }}/:id</td>
          <td>Nothing</td>
          <td>A single object</td>
        </tr>
        <tr>
          <td>Update a record</td>
          <td><span class="badge bg-warning">PUT</span></td>
          <td>/{{ resourceName }}/:id</td>
          <td>A JSON object</td>
          <td>The updated object</td>
        </tr>
        <tr>
          <td>Delete a record</td>
          <td><span class="badge bg-danger">DELETE</span></td>
          <td>/{{ resourceName }}/:id</td>
          <td>Nothing</td>
          <td>The deleted object</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
import { useRoute } from "vue-router";

const route = useRoute();
const resourceName = route.params.resourceName;
const baseUrl = window.location.host; // Dynamic base URL
</script>

<style scoped>
.badge {
  font-size: 12px;
  padding: 5px;
  border-radius: 5px;
}
</style>
