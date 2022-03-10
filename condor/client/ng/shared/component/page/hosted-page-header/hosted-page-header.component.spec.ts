import { async, fakeAsync, tick } from '@angular/core/testing';
import { ExcelExportEvent } from '@progress/kendo-angular-grid/dist/es2015/excel/excel-export-event';
import { RootScopeServiceMock } from 'ajs-upgraded-providers/mocks/rootscope.service.mock';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { EventEmitterMock } from 'mocks';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { HostedPageHeaderComponent } from './hosted-page-header.component';

describe('HostedPageHeaderComponent', () => {
    let c: HostedPageHeaderComponent;
    let shortcutsService: IpxShortcutsServiceMock;
    const destroy = of({}).pipe(delay(1000));

    beforeEach(() => {
        shortcutsService = new IpxShortcutsServiceMock();
        c = new HostedPageHeaderComponent(new RootScopeServiceMock() as any, shortcutsService as any, destroy as any);
        (c as any).onAction = new EventEmitterMock() as any;
        c.hostedMenuOptions = [{
            id: 'default'
        }, {
            id: 'revert'
        }];
    });

    it('should create the component instance', async(() => {
        expect(c).toBeTruthy();
        expect(c.isHosted).toBeTruthy();
    }));

    describe('executeAction', () => {
        it('should call onAction with click', () => {
            c.executeAction('save');

            expect(c.onAction.emit).toHaveBeenCalledWith('save');
        });
    });

    describe('intialize menu items', () => {
        it('evaluate menu options disable when use default and user has default set true', () => {
            c.useDefaultPresentation = true;
            c.userHasDefaultPresentation = true;
            c.initializeMenuItems();
            expect(c.hostedMenuOptions[0].disabled).toBe(true);
            expect(c.hostedMenuOptions[1].disabled).toBe(false);
        });
        it('evaluate menu options disable when use default and user has default set false', () => {
            c.useDefaultPresentation = false;
            c.userHasDefaultPresentation = false;
            c.initializeMenuItems();
            expect(c.hostedMenuOptions[0].disabled).toBe(false);
            expect(c.hostedMenuOptions[1].disabled).toBe(true);
        });
    });

    describe('shortcuts', () => {
        beforeEach(() => {
            c.addShortcuts = true;
        });

        it('does not register the shortcuts if addShortcuts is false', () => {
            c.addShortcuts = false;
            c.ngOnInit();
            expect(shortcutsService.observeMultiple$).not.toHaveBeenCalled();

        });
        it('registers the shortcuts on init', () => {
            c.ngOnInit();
            expect(shortcutsService.observeMultiple$).toHaveBeenCalledWith([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT]);

        });

        it('calls function save on shortcut save', fakeAsync(() => {
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;
            const saveSpy = jest.spyOn(c.onAction, 'emit');
            c.ngOnInit();

            tick(shortcutsService.interval);
            expect(saveSpy).toHaveBeenCalledWith('save');
        }));

        it('calls function to revert on shortcut revert', fakeAsync(() => {
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.REVERT;
            const revertSpy = jest.spyOn(c.onRevert, 'emit');
            c.ngOnInit();

            tick(shortcutsService.interval);
            expect(revertSpy).toHaveBeenCalledWith('');
        }));

        it('does not call functions if disabled', fakeAsync(() => {
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;
            const saveSpy = jest.spyOn(c.onAction, 'emit');
            c.disabled = true;
            c.ngOnInit();

            tick(shortcutsService.interval);
            expect(saveSpy).not.toHaveBeenCalled();
        }));
    });
});
