<template>
  <form @submit.prevent="submitForm">
    <div v-if="validationErrors.length" class="alert alert-danger">
      <ul>
        <li v-for="error in validationErrors" :key="error">{{ error }}</li>
      </ul>
    </div>

    <div class="mb-3" v-for="attribute in attributes" :key="attribute.name">
      <label>
        {{ attribute.label }}
        <span v-if="attribute.required" class="text-danger">*</span>
      </label>

      <!-- Dropdown for Boolean Fields -->
      <select
        v-if="attribute.type === 'Mongoid::Boolean'"
        v-model="record[attribute.name]"
        class="form-select"
      >
        <option :value="null">Null</option>
        <option :value="true">True</option>
        <option :value="false">False</option>
      </select>

      <!-- Date Picker for Date Fields -->
      <input
        v-else-if="attribute.type === 'Date'"
        v-model="record[attribute.name]"
        type="date"
        class="form-control"
        :required="attribute.required"
      />

      <!-- Number Input for Integer Fields -->
      <input
        v-else-if="attribute.type === 'Integer'"
        v-model.number="record[attribute.name]"
        type="number"
        class="form-control"
        :required="attribute.required"
        step="1"
      />

      <!-- Number Input for Float Fields -->
      <input
        v-else-if="attribute.type === 'Float'"
        v-model.number="record[attribute.name]"
        type="number"
        class="form-control"
        :required="attribute.required"
        step="any"
      />

      <!-- Default Text Input -->
      <input
        v-else
        v-model="record[attribute.name]"
        type="text"
        class="form-control"
        :required="attribute.required"
      />

      <div class="form-text">
        {{ attribute.type }}
      </div>
    </div>

    <button type="submit" class="btn btn-primary">Save</button>
    <button @click="cancel" type="button" class="btn btn-secondary">Cancel</button>
  </form>
</template>

<script setup>
import { defineEmits } from "vue";

const props = defineProps({
  record: Object,
  attributes: Array,
  validationErrors: Array,
});

const emit = defineEmits(["submit", "cancel"]);

const submitForm = () => {
  emit("submit");
};

const cancel = () => {
  emit("cancel");
};
</script>
