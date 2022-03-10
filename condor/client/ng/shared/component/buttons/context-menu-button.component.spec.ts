import { async } from '@angular/core/testing';
import { ContextMenuButtonComponent } from './context-menu-button.component';

describe('Context Menu button component', () => {
    let c: ContextMenuButtonComponent;
    const contextMenuMock: any = {
        show: jest.fn()
    };

    beforeEach(() => {
        c = new ContextMenuButtonComponent();
        c.contextMenu = contextMenuMock;
    });

    it('should create the component instance', async(() => {
        expect(c).toBeTruthy();
    }));

    it('should check button click', async(() => {

        const event = { pageX: 1, pageY: 2, view: { window } };
        c.onButtonClick(event);
        spyOn(c.contextMenu, 'show');
        expect(c.contextMenu).toBeDefined();
    }));

    it('should check onMenuItemSelected', async(() => {

        const event: any = {
            item: {
                action: jest.fn()
            }
        };

        spyOn(event.item, 'action');
        c.onMenuItemSelected(event);
        expect(event.item.action).toBeCalled();
    }));

});