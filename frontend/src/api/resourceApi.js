import axios from "axios";

const API_BASE_URL = "/api/dashboard/resources";

export const resourceApi = {
  /**
   * Fetch resource data with optional filters, sorting, and pagination.
   */
  fetchRecords(resourceName, params = {}) {
    return axios.get(`${API_BASE_URL}/${resourceName}/data`, { params });
  },

  /**
   * Fetch a single record.
   */
  fetchRecord(resourceName, recordId) {
    return axios.get(`${API_BASE_URL}/${resourceName}/data/${recordId}`);
  },

  /**
   * Create a new record.
   */
  createRecord(resourceName, recordData) {
    return axios.post(`${API_BASE_URL}/${resourceName}/data`, recordData);
  },

  /**
   * Update an existing record.
   */
  updateRecord(resourceName, recordId, recordData) {
    return axios.put(`${API_BASE_URL}/${resourceName}/data/${recordId}`, recordData);
  },

  /**
   * Delete a record.
   */
  deleteRecord(resourceName, recordId) {
    return axios.delete(`${API_BASE_URL}/${resourceName}/data/${recordId}`);
  },
};
