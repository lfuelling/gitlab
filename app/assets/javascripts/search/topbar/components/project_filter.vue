<script>
import { mapState, mapActions } from 'vuex';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import SearchableDropdown from './searchable_dropdown.vue';
import { ANY_OPTION, GROUP_DATA, PROJECT_DATA } from '../constants';

export default {
  name: 'ProjectFilter',
  components: {
    SearchableDropdown,
  },
  props: {
    initialData: {
      type: Object,
      required: false,
      default: () => null,
    },
  },
  computed: {
    ...mapState(['projects', 'fetchingProjects']),
    selectedProject() {
      return this.initialData ? this.initialData : ANY_OPTION;
    },
  },
  methods: {
    ...mapActions(['fetchProjects']),
    handleProjectChange(project) {
      // This determines if we need to update the group filter or not
      const queryParams = {
        ...(project.namespace_id && { [GROUP_DATA.queryParam]: project.namespace_id }),
        [PROJECT_DATA.queryParam]: project.id,
      };

      visitUrl(setUrlParams(queryParams));
    },
  },
  PROJECT_DATA,
};
</script>

<template>
  <searchable-dropdown
    :header-text="$options.PROJECT_DATA.headerText"
    :selected-display-value="$options.PROJECT_DATA.selectedDisplayValue"
    :items-display-value="$options.PROJECT_DATA.itemsDisplayValue"
    :loading="fetchingProjects"
    :selected-item="selectedProject"
    :items="projects"
    @search="fetchProjects"
    @change="handleProjectChange"
  />
</template>
