import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import formComponent from '~/issue_show/components/form.vue';
import Autosave from '~/autosave';
import eventHub from '~/issue_show/event_hub';

jest.mock('~/autosave');

describe('Inline edit form component', () => {
  let vm;
  const defaultProps = {
    canDestroy: true,
    formState: {
      title: 'b',
      description: 'a',
      lockedWarningVisible: false,
    },
    issuableType: 'issue',
    markdownPreviewPath: '/',
    markdownDocsPath: '/',
    projectPath: '/',
    projectNamespace: '/',
  };

  afterEach(() => {
    vm.$destroy();
  });

  const createComponent = (props) => {
    const Component = Vue.extend(formComponent);

    vm = mountComponent(Component, {
      ...defaultProps,
      ...props,
    });
  };

  it('does not render template selector if no templates exist', () => {
    createComponent();

    expect(vm.$el.querySelector('.js-issuable-selector-wrap')).toBeNull();
  });

  it('renders template selector when templates exists', () => {
    createComponent({ issuableTemplates: ['test'] });

    expect(vm.$el.querySelector('.js-issuable-selector-wrap')).not.toBeNull();
  });

  it('hides locked warning by default', () => {
    createComponent();

    expect(vm.$el.querySelector('.alert')).toBeNull();
  });

  it('shows locked warning if formState is different', () => {
    createComponent({ formState: { ...defaultProps.formState, lockedWarningVisible: true } });

    expect(vm.$el.querySelector('.alert')).not.toBeNull();
  });

  it('hides locked warning when currently saving', () => {
    createComponent({
      formState: { ...defaultProps.formState, updateLoading: true, lockedWarningVisible: true },
    });

    expect(vm.$el.querySelector('.alert')).toBeNull();
  });

  describe('autosave', () => {
    let spy;

    beforeEach(() => {
      spy = jest.spyOn(Autosave.prototype, 'reset');
    });

    it('initialized Autosave on mount', () => {
      createComponent();

      expect(Autosave).toHaveBeenCalledTimes(2);
    });

    it('calls reset on autosave when eventHub emits appropriate events', () => {
      createComponent();

      eventHub.$emit('close.form');

      expect(spy).toHaveBeenCalledTimes(2);

      eventHub.$emit('delete.issuable');

      expect(spy).toHaveBeenCalledTimes(4);

      eventHub.$emit('update.issuable');

      expect(spy).toHaveBeenCalledTimes(6);
    });
  });
});
