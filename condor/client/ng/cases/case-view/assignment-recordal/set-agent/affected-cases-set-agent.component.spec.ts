import { fakeAsync, tick } from '@angular/core/testing';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRefMock, IpxNotificationServiceMock, TranslateServiceMock } from 'mocks';
import { KnownNameTypes } from 'names/knownnametypes';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { AffectedCasesSetAgentComponent } from './affected-cases-set-agent.component';

describe('AffectedCasesSetAgentComponent', () => {
    let component: AffectedCasesSetAgentComponent;
    let service: {
        setAgent(agentId: number, mainCaseId: number, isCaseNameSet: boolean, rows: Array<string>): any,
        getCaseReference(caseKey: number): any
    };
    let affectedCasesService: {
        getAffectedCases(caseKey: number): any
    };
    let translate: TranslateServiceMock;
    let notificationService: IpxNotificationServiceMock;
    let modalRef: BsModalRefMock;
    let shortcutsService: IpxShortcutsServiceMock;
    let destroy$: any;
    beforeEach(() => {
        affectedCasesService = {
            getAffectedCases: jest.fn().mockReturnValue(of({ rows: [], totalRows: 1 }))
        };
        service = {
            setAgent: jest.fn().mockReturnValue(of({ result: 'success' })),
            getCaseReference: jest.fn().mockReturnValue(of({}))
        };
        translate = new TranslateServiceMock();
        notificationService = new IpxNotificationServiceMock();
        modalRef = new BsModalRefMock();
        shortcutsService = new IpxShortcutsServiceMock();
        destroy$ = of({}).pipe(delay(1000));
        component = new AffectedCasesSetAgentComponent(service as any, KnownNameTypes as any, translate as any, notificationService as any, modalRef as any, affectedCasesService as any, destroy$, shortcutsService as any);
        (component as any).sbsModalRef = {
            hide: jest.fn()
        } as any;
        component.affectedCases = [{}];
        component.mainCaseId = 1;
        component.onClose$.next = jest.fn() as any;
    });
    it('should create', () => {
        expect(component).toBeTruthy();
    });
    it('should call service getCaseReference', () => {
        component.ngOnInit();
        expect(service.getCaseReference).toHaveBeenCalledWith(component.mainCaseId);
    });
    it('should initialize shortcuts', () => {
        component.ngOnInit();
        expect(shortcutsService.observeMultiple$).toHaveBeenCalledWith([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT]);
    });

    it('should call save if shortcut is given', fakeAsync(() => {
        component.onSave = jest.fn();
        shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;
        component.ngOnInit();
        component.isSaveDisabled = false;
        tick(shortcutsService.interval);

        expect(component.onSave).toHaveBeenCalled();
    }));
    it('should call revert if shortcut is given', fakeAsync(() => {
        component.close = jest.fn();
        shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.REVERT;
        component.ngOnInit();
        tick(shortcutsService.interval);

        expect(component.close).toHaveBeenCalled();
    }));
    it('should call service api if allrows are selected', () => {
        component.isAllPageSelect = true;
        component.affectedCases = null;
        const queryParams = 'test';
        component.ngOnInit();
        component.gridOptions.read$(queryParams as any);
        expect(affectedCasesService.getAffectedCases).toHaveBeenCalledWith(component.mainCaseId, null, component.filterParams);
    });
    it('should enable Save if Agent picklist has some value', () => {
        expect(component.isSaveDisabled).toBe(true);
        component.onAgentChanged({ key: 1 });
        expect(component.isSaveDisabled).toBe(false);
    });
    it('should call background notification info on save if casename checkbox is checked and internal case rows are there', (done) => {
        component.formData = {
            agent: { key: 1 },
            isCaseNameSet: true
        };
        component.grid = { getCurrentData: jest.fn().mockReturnValue([{ rowKey: '1', caseId: 2 }, { rowKey: '2', caseId: 3 }]) } as any;
        component.mainCaseId = 1;
        component.onSave();
        expect(component.isSaveDisabled).toBe(true);
        service.setAgent(component.formData.agent.key, component.mainCaseId, component.formData.isCaseNameSet, ['1', '2']).subscribe(() => {
            expect(component.onClose$.next).toHaveBeenCalledWith('background');
            done();
        });
    });
    it('should call notification success on save if casename checkbox is checked but internal rows not there', (done) => {
        component.formData = {
            agent: { key: 1 },
            isCaseNameSet: true
        };
        component.grid = { getCurrentData: jest.fn().mockReturnValue([{ rowKey: '1' }, { rowKey: '2' }]) } as any;
        component.mainCaseId = 1;
        component.onSave();
        expect(component.isSaveDisabled).toBe(true);
        service.setAgent(component.formData.agent.key, component.mainCaseId, component.formData.isCaseNameSet, ['1', '2']).subscribe(() => {
            expect(component.onClose$.next).toHaveBeenCalledWith('success');
            done();
        });
    });
    it('should call notification success on save if casename checkbox is false', (done) => {
        component.formData = {
            agent: { key: 1 },
            isCaseNameSet: false
        };
        component.grid = { getCurrentData: jest.fn().mockReturnValue([{ rowKey: '1', caseId: 2 }, { rowKey: '2', caseId: 3 }]) } as any;
        component.mainCaseId = 1;
        component.onSave();
        expect(component.isSaveDisabled).toBe(true);
        service.setAgent(component.formData.agent.key, component.mainCaseId, component.formData.isCaseNameSet, ['1', '2']).subscribe(() => {
            expect(component.onClose$.next).toHaveBeenCalledWith('success');
            done();
        });
    });
    it('should call notification on close if save enabled', fakeAsync(() => {
        component.isSaveDisabled = false;
        const model = { content: { confirmed$: of(), cancelled$: of() } };
        notificationService.openDiscardModal.mockReturnValue(model);
        component.close();
        expect(notificationService.openDiscardModal).toBeCalled();
        tick(10);
        model.content.confirmed$.subscribe(() => {
            expect(modalRef.hide).toHaveBeenCalled();
            expect(component.onClose$.next).toHaveBeenCalledWith(false);
        });
    }));
    it('should hide modal if close is called', () => {
        component.isSaveDisabled = true;
        component.close();
        expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
        expect(component.onClose$.next).toHaveBeenCalledWith(false);
    });
});