import { createRouter, createWebHistory } from "vue-router";
import Home from "@/views/Home.vue";
import Resources from "@/views/Resources.vue";
import ResourceShow from "@/views/ResourceShow.vue";

const routes = [
  { path: "/", component: Home },
  { path: "/resources", component: Resources },
  { path: "/resources/:name", component: ResourceShow },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;
