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

      <input
        v-model="record[attribute.name]"
        type="text"
        class="form-control"
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
import { defineProps, defineEmits } from "vue";

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
