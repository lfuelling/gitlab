<script>
import { mapState, mapActions } from 'vuex';
import axios from '~/lib/utils/axios_utils';
import FeatureFlagForm from './form.vue';
import { NEW_VERSION_FLAG, ROLLOUT_STRATEGY_ALL_USERS } from '../constants';
import { createNewEnvironmentScope } from '../store/helpers';

import featureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    FeatureFlagForm,
  },
  mixins: [featureFlagsMixin()],
  inject: {
    showUserCallout: {},
    userCalloutId: {
      default: '',
    },
    userCalloutsPath: {
      default: '',
    },
  },
  data() {
    return {
      userShouldSeeNewFlagAlert: this.showUserCallout,
    };
  },
  computed: {
    ...mapState(['error', 'path']),
    scopes() {
      return [
        createNewEnvironmentScope(
          {
            environmentScope: '*',
            active: true,
          },
          this.glFeatures.featureFlagsPermissions,
        ),
      ];
    },
    version() {
      return NEW_VERSION_FLAG;
    },
    strategies() {
      return [{ name: ROLLOUT_STRATEGY_ALL_USERS, parameters: {}, scopes: [] }];
    },
  },
  methods: {
    ...mapActions(['createFeatureFlag']),
    dismissNewVersionFlagAlert() {
      this.userShouldSeeNewFlagAlert = false;
      axios.post(this.userCalloutsPath, {
        feature_name: this.userCalloutId,
      });
    },
  },
};
</script>
<template>
  <div>
    <h3 class="page-title">{{ s__('FeatureFlags|New feature flag') }}</h3>

    <div v-if="error.length" class="alert alert-danger">
      <p v-for="(message, index) in error" :key="index" class="mb-0">{{ message }}</p>
    </div>

    <feature-flag-form
      :cancel-path="path"
      :submit-text="s__('FeatureFlags|Create feature flag')"
      :scopes="scopes"
      :strategies="strategies"
      :version="version"
      @handleSubmit="(data) => createFeatureFlag(data)"
    />
  </div>
</template>
