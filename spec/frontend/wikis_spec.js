import { escape } from 'lodash';
import { setHTMLFixture } from 'helpers/fixtures';
import Wikis from '~/pages/shared/wikis/wikis';
import Tracking from '~/tracking';

describe('Wikis', () => {
  const editFormHtmlFixture = (args) => `<form class="wiki-form ${
    args.newPage ? 'js-new-wiki-page' : ''
  }">
    <input type="text" id="wiki_title" value="My title" />
    <input type="text" id="wiki_message" />
    <select class="form-control select-control" name="wiki[format]" id="wiki_format">
      <option value="markdown">Markdown</option>
      <option selected="selected" value="rdoc">RDoc</option>
      <option value="asciidoc">AsciiDoc</option>
      <option value="org">Org</option>
    </select>
    <textarea id="wiki_content"></textarea>
    <code class="js-markup-link-example">{Link title}[link:page-slug]</code>
    <input type="submit" class="js-wiki-btn-submit">
    </input>
  </form>
  `;

  let wikis;
  let titleInput;
  let contentInput;
  let messageInput;
  let changeFormatSelect;
  let linkExample;

  const findBeforeUnloadWarning = () => window.onbeforeunload?.();
  const findForm = () => document.querySelector('.wiki-form');
  const findSubmitButton = () => document.querySelector('.js-wiki-btn-submit');

  describe('when the wiki page is being created', () => {
    const formHtmlFixture = editFormHtmlFixture({ newPage: true });

    beforeEach(() => {
      setHTMLFixture(formHtmlFixture);

      titleInput = document.getElementById('wiki_title');
      messageInput = document.getElementById('wiki_message');
      changeFormatSelect = document.querySelector('#wiki_format');
      linkExample = document.querySelector('.js-markup-link-example');
      wikis = new Wikis();
    });

    it('binds an event listener to the title input', () => {
      wikis.handleWikiTitleChange = jest.fn();

      titleInput.dispatchEvent(new Event('keyup'));

      expect(wikis.handleWikiTitleChange).toHaveBeenCalled();
    });

    it('sets the commit message when title changes', () => {
      titleInput.value = 'My title';
      messageInput.value = '';

      titleInput.dispatchEvent(new Event('keyup'));

      expect(messageInput.value).toEqual('Create My title');
    });

    it('replaces hyphens with spaces', () => {
      titleInput.value = 'my-hyphenated-title';
      titleInput.dispatchEvent(new Event('keyup'));

      expect(messageInput.value).toEqual('Create my hyphenated title');
    });
  });

  describe('when the wiki page is being updated', () => {
    const formHtmlFixture = editFormHtmlFixture({ newPage: false });

    beforeEach(() => {
      setHTMLFixture(formHtmlFixture);

      titleInput = document.getElementById('wiki_title');
      messageInput = document.getElementById('wiki_message');
      wikis = new Wikis();
    });

    it('sets the commit message when title changes, prefixing with "Update"', () => {
      titleInput.value = 'My title';
      messageInput.value = '';

      titleInput.dispatchEvent(new Event('keyup'));

      expect(messageInput.value).toEqual('Update My title');
    });

    it.each`
      value         | text
      ${'markdown'} | ${'[Link Title](page-slug)'}
      ${'rdoc'}     | ${'{Link title}[link:page-slug]'}
      ${'asciidoc'} | ${'link:page-slug[Link title]'}
      ${'org'}      | ${'[[page-slug]]'}
    `('updates a message when value=$value is selected', ({ value, text }) => {
      changeFormatSelect.value = value;
      changeFormatSelect.dispatchEvent(new Event('change'));

      expect(linkExample.innerHTML).toBe(text);
    });

    it('starts with no unload warning', () => {
      expect(findBeforeUnloadWarning()).toBeUndefined();
    });

    describe('when wiki content is updated', () => {
      beforeEach(() => {
        contentInput = document.getElementById('wiki_content');
        contentInput.value = 'Lorem ipsum dolar sit!';
        contentInput.dispatchEvent(new Event('input'));
      });

      it('sets before unload warning', () => {
        expect(findBeforeUnloadWarning()).toBe('');
      });

      it('when form submitted, unsets before unload warning', () => {
        findForm().dispatchEvent(new Event('submit'));
        expect(findBeforeUnloadWarning()).toBeUndefined();
      });
    });
  });

  describe('submit button state', () => {
    beforeEach(() => {
      setHTMLFixture(editFormHtmlFixture({ newPage: true }));

      titleInput = document.getElementById('wiki_title');
      contentInput = document.getElementById('wiki_content');

      wikis = new Wikis();
    });

    it.each`
      title          | text           | buttonState   | disabledAttr
      ${'something'} | ${'something'} | ${'enabled'}  | ${null}
      ${''}          | ${'something'} | ${'disabled'} | ${'true'}
      ${'something'} | ${''}          | ${'disabled'} | ${'true'}
      ${''}          | ${''}          | ${'disabled'} | ${'true'}
      ${'   '}       | ${'   '}       | ${'disabled'} | ${'true'}
    `(
      "when title='$title', content='$content', then, buttonState='$buttonState'",
      ({ title, text, disabledAttr }) => {
        titleInput.value = title;
        titleInput.dispatchEvent(new Event('keyup'));

        contentInput.value = text;
        contentInput.dispatchEvent(new Event('input'));

        expect(findSubmitButton().getAttribute('disabled')).toBe(disabledAttr);
      },
    );
  });

  describe('trackPageView', () => {
    const trackingPage = 'projects:wikis:show';
    const trackingContext = { foo: 'bar' };
    const showPageHtmlFixture = `
      <div class="js-wiki-page-content" data-tracking-context="${escape(
        JSON.stringify(trackingContext),
      )}"></div>
    `;

    beforeEach(() => {
      setHTMLFixture(showPageHtmlFixture);
      document.body.dataset.page = trackingPage;
      jest.spyOn(Tracking, 'event').mockImplementation();

      Wikis.trackPageView();
    });

    it('sends the tracking event and context', () => {
      expect(Tracking.event).toHaveBeenCalledWith(trackingPage, 'view_wiki_page', {
        label: 'view_wiki_page',
        context: {
          schema: 'iglu:com.gitlab/wiki_page_context/jsonschema/1-0-1',
          data: trackingContext,
        },
      });
    });
  });
});
