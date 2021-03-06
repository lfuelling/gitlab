import { config as vueConfig } from 'vue';
import { shallowMount } from '@vue/test-utils';
import IssueTimeEstimate from '~/boards/components/issue_time_estimate.vue';

describe('Issue Time Estimate component', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when limitToHours is false', () => {
    beforeEach(() => {
      wrapper = shallowMount(IssueTimeEstimate, {
        propsData: {
          estimate: 374460,
        },
        provide: {
          timeTrackingLimitToHours: false,
        },
      });
    });

    it('renders the correct time estimate', () => {
      expect(wrapper.find('time').text().trim()).toEqual('2w 3d 1m');
    });

    it('renders expanded time estimate in tooltip', () => {
      expect(wrapper.find('.js-issue-time-estimate').text()).toContain('2 weeks 3 days 1 minute');
    });

    it('prevents tooltip xss', async () => {
      const alertSpy = jest.spyOn(window, 'alert');

      try {
        // This will raise props validating warning by Vue, silencing it
        vueConfig.silent = true;
        await wrapper.setProps({ estimate: 'Foo <script>alert("XSS")</script>' });
      } finally {
        vueConfig.silent = false;
      }

      expect(alertSpy).not.toHaveBeenCalled();
      expect(wrapper.find('time').text().trim()).toEqual('0m');
      expect(wrapper.find('.js-issue-time-estimate').text()).toContain('0m');
    });
  });

  describe('when limitToHours is true', () => {
    beforeEach(() => {
      wrapper = shallowMount(IssueTimeEstimate, {
        propsData: {
          estimate: 374460,
        },
        provide: {
          timeTrackingLimitToHours: true,
        },
      });
    });

    it('renders the correct time estimate', () => {
      expect(wrapper.find('time').text().trim()).toEqual('104h 1m');
    });

    it('renders expanded time estimate in tooltip', () => {
      expect(wrapper.find('.js-issue-time-estimate').text()).toContain('104 hours 1 minute');
    });
  });
});
