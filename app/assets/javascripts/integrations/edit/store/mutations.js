import * as types from './mutation_types';

export default {
  [types.SET_OVERRIDE](state, override) {
    state.override = override;
  },
  [types.SET_IS_SAVING](state, isSaving) {
    state.isSaving = isSaving;
  },
  [types.SET_IS_TESTING](state, isTesting) {
    state.isTesting = isTesting;
  },
  [types.SET_IS_RESETTING](state, isResetting) {
    state.isResetting = isResetting;
  },
  [types.REQUEST_RESET_INTEGRATION](state) {
    state.isResetting = true;
  },
  [types.RECEIVE_RESET_INTEGRATION_ERROR](state) {
    state.isResetting = false;
  },
};
