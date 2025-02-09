<template>
  <div :class="theme">
    <nav class="navbar navbar-expand-lg">
      <div class="container-fluid">
        <router-link class="navbar-brand" to="/">Deployerb</router-link>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav"
          aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
          <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
          <ul class="navbar-nav">
            <li class="nav-item">
              <router-link class="nav-link" to="/">Home</router-link>
            </li>
            <li class="nav-item">
              <router-link class="nav-link" to="/resources">Resources</router-link>
            </li>
          </ul>
          <!-- Theme Toggle Switch -->
          <div class="form-check form-switch ms-auto">
            <input class="form-check-input" type="checkbox" id="themeSwitch" @change="toggleTheme" :checked="theme === 'dark-theme'" />
            <label class="form-check-label" for="themeSwitch">
              {{ theme === "dark-theme" ? "🌙 Dark" : "☀️ Light" }}
            </label>
          </div>
        </div>
      </div>
    </nav>

    <div class="container mt-4">
      <router-view></router-view>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import { store } from "@/store";

const theme = ref(localStorage.getItem("theme") || "light-theme");

// Toggle Theme and Save to Local Storage
const toggleTheme = () => {
  store.theme = store.theme === "light-theme" ? "dark-theme" : "light-theme";
  document.documentElement.setAttribute("data-bs-theme", store.theme === "dark-theme" ? "dark" : "light");
  localStorage.setItem("theme", store.theme);
};

// Apply Theme on Page Load
onMounted(() => {
  document.documentElement.setAttribute("data-bs-theme", theme.value === "dark-theme" ? "dark" : "light");
});
</script>
