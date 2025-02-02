import { createRouter, createWebHistory } from "vue-router";
import Home from "@/views/Home.vue";
import Resources from "@/views/Resources.vue";
import ResourceShow from "@/views/ResourceShow.vue";
import EditKey from "@/components/EditKey.vue";
import EditRecord from "@/components/EditRecord.vue";

const routes = [
  { path: "/", component: Home },
  { path: "/resources", component: Resources },
  { path: "/resources/:resourceName", component: ResourceShow },
  { path: "/resources/:resourceName/:keyName/edit", component: EditKey },
  { path: "/resources/:resourceName/data/:id/edit", component: EditRecord },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;
