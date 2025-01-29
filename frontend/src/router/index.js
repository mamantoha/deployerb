import { createRouter, createWebHistory } from "vue-router";
import Home from "@/views/Home.vue";
import Resources from "@/views/Resources.vue";

const routes = [
  { path: "/", component: Home },
  { path: "/resources", component: Resources },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;
