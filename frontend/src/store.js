import { reactive } from "vue";

export const store = reactive({
  successMessage: "",
  activeResourceTab: "keys",
  theme: localStorage.getItem("theme") || "light-theme",
});
