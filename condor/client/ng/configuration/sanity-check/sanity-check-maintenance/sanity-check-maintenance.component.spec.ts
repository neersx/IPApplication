import { fakeAsync, tick } from '@angular/core/testing';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { ChangeDetectorRefMock, NotificationServiceMock, StateServiceMock } from 'mocks';
import { of } from 'rxjs';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { SanityCheckConfigurationServiceMock } from '../sanity-check-configuration.service.mock';
import { NamesSanityCheckRuleModel, SanityCheckRuleModelEx } from './maintenance-model';
import { SanityCheckConfigurationMaintenanceComponent } from './sanity-check-maintenance.component';
import { SanityCheckMaintenanceServiceMock } from './sanity-check-maintenance.service.mock';

describe('SanityCheckConfigurationComponent', () => {
    let c: SanityCheckConfigurationMaintenanceComponent;
    let service: SanityCheckMaintenanceServiceMock;
    let notificationService: NotificationServiceMock;
    let cdr: ChangeDetectorRefMock;
    let stateService: StateServiceMock;
    let searchService: SanityCheckConfigurationServiceMock;
    let shortcutsService: IpxShortcutsServiceMock;
    const destroy$ = of();

    beforeEach(() => {
        stateService = new StateServiceMock();
        notificationService = new NotificationServiceMock();
        service = new SanityCheckMaintenanceServiceMock();
        cdr = new ChangeDetectorRefMock();
        searchService = new SanityCheckConfigurationServiceMock();
        shortcutsService = new IpxShortcutsServiceMock();
        c = new SanityCheckConfigurationMaintenanceComponent(stateService as any, service as any, notificationService as any, cdr as any, searchService as any, destroy$ as any, shortcutsService as any);
        c.stateParams = { matchType: 'case' };
    });

    it('initialize', () => {
        expect(c).toBeDefined();
        c.ngOnInit();

        expect(c.matchType).toEqual('case');
        expect(c.topicOptions).toBeDefined();
    });

    it('init data for edit cases', () => {
        c.stateParams = { matchType: 'case', id: 100 };
        c.viewData = {
            caseDetails: { caseCategory: { id: 1, key: 'A', value: 'caseCategory' } },
            dataValidation: { ruleDescription: 'abcd' },
            caseNameDetails: { name: { id: 10, key: 'a', value: 'a corp' } },
            otherDetails: { instruction: { id: 'a', value: 'XYZ' } }
        };

        const data = new SanityCheckRuleModelEx(c.viewData) as any;
        c.ngOnInit();

        expect((c.topicOptions.topics[0] as any).viewData).toEqual(data.ruleOverView);
        expect((c.topicOptions.topics[1] as any).viewData).toEqual(data.caseCharacteristics);
        expect((c.topicOptions.topics[2] as any).viewData).toEqual(data.caseName);
        expect((c.topicOptions.topics[3] as any).viewData).toEqual(data.standingInstruction);
        expect((c.topicOptions.topics[4] as any).viewData).toEqual(data.event);
        expect((c.topicOptions.topics[5] as any).viewData).toEqual(data.other);
    });

    it('init data for edit name', () => {
        c.stateParams = { matchType: 'name', id: 100 };
        c.viewData = {
            ruleOverView: { ruleDescription: 'abcd' },
            nameCharacteristics: { nameGroup: { id: 1, key: 'A', value: 'category' } },
            standingInstruction: { instructionType: { code: 'R', value: 'instructionType'} },
            other: {}
        };
        const data = new NamesSanityCheckRuleModel(c.viewData);
        c.ngOnInit();

        expect((c.topicOptions.topics[0] as any).params.viewData).toEqual(data.ruleOverView);
        expect((c.topicOptions.topics[1] as any).params.viewData).toEqual(data.nameCharacteristics);
        expect((c.topicOptions.topics[2] as any).params.viewData).toEqual(data.standingInstruction);
        expect((c.topicOptions.topics[3] as any).params.viewData).toEqual(data.other);
    });

    it('reloads the page', () => {
        c.ngOnInit();

        c.reload();

        expect(c.isDiscardEnabled).toBeFalsy();
        expect(stateService.reload).toHaveBeenCalled();
    });

    it('saves the data, to add rule', () => {
        c.ngOnInit();

        c.save();

        expect(c.isSaveEnabled).toBeFalsy();
        expect(service.save$).toHaveBeenCalled();

        expect(notificationService.success).toHaveBeenCalled();
        expect(service.resetChangeEventState).toHaveBeenCalled();
        expect(stateService.transitionTo).toHaveBeenCalled();
    });

    it('saves the data, to update the rule', () => {
        c.stateParams = { matchType: 'case', id: 100 };
        c.viewData = { a: 'a' };

        c.ngOnInit();

        c.save();

        expect(c.isSaveEnabled).toBeFalsy();
        expect(service.update$).toHaveBeenCalled();
        expect(notificationService.success).toHaveBeenCalled();
        expect(service.resetChangeEventState).toHaveBeenCalled();
        expect(stateService.reload).toHaveBeenCalled();
    });

    describe('shortcuts', () => {
        it('calls to initialize shortcut keys on init', () => {
            c.ngOnInit();
            expect(shortcutsService.observeMultiple$).toHaveBeenCalledWith([RegisterableShortcuts.REVERT, RegisterableShortcuts.SAVE]);
        });

        it('does not call function on save, if save button disabled', fakeAsync(() => {
            c.isSaveEnabled = false;
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;
            const saveSpy = jest.spyOn(c, 'save');

            c.ngOnInit();
            tick(shortcutsService.interval);
            expect(saveSpy).not.toHaveBeenCalled();
        }));

        it('does not call function on discard, if discard button disabled', fakeAsync(() => {
            c.isDiscardEnabled = false;
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.REVERT;
            const revertSpy = jest.spyOn(c, 'reload');

            c.ngOnInit();
            tick(shortcutsService.interval);
            expect(revertSpy).not.toHaveBeenCalled();
        }));

        it('calls function on save, if save button enabled', fakeAsync(() => {
            c.isSaveEnabled = true;
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;
            const saveSpy = jest.spyOn(c, 'save');

            c.ngOnInit();
            tick(shortcutsService.interval);
            expect(saveSpy).toHaveBeenCalled();
        }));

        it('calls function on revert, if revert button enabled', fakeAsync(() => {
            c.isDiscardEnabled = true;
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.REVERT;
            const revertSpy = jest.spyOn(c, 'reload');

            c.ngOnInit();
            tick(shortcutsService.interval);
            expect(revertSpy).toHaveBeenCalled();
        }));
    });
});