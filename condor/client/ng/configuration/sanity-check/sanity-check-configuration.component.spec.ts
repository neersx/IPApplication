import { fakeAsync, tick } from '@angular/core/testing';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { ChangeDetectorRefMock, NotificationServiceMock, StateServiceMock } from 'mocks';
import { of } from 'rxjs';
import { DefaultColumnTemplateType } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { SanityCheckConfigurationComponent } from './sanity-check-configuration.component';
import { SanityCheckConfigurationServiceMock } from './sanity-check-configuration.service.mock';

describe('SanityCheckConfigurationComponent', () => {
    let component: SanityCheckConfigurationComponent;
    let service: SanityCheckConfigurationServiceMock;
    let stateService: StateServiceMock;
    let destroy$: IpxDestroy;
    let notificationService: NotificationServiceMock;
    let shortcutsService: IpxShortcutsServiceMock;
    let cdr: ChangeDetectorRefMock;
    beforeEach(() => {
        service = new SanityCheckConfigurationServiceMock();
        stateService = new StateServiceMock();
        destroy$ = of() as any;
        notificationService = new NotificationServiceMock();
        shortcutsService = new IpxShortcutsServiceMock();
        cdr = new ChangeDetectorRefMock();
        component = new SanityCheckConfigurationComponent(service as any, stateService as any, destroy$, notificationService as any, shortcutsService as any, cdr as any);
        component.searchByCaseComp = { resetFormData: jest.fn() } as any;
        component.stateParams = { matchType: 'case' };
        component.viewInitialiser = { canCreateForName: true, canUpdateForName: true, canDeleteForName: true, canCreateForCase: true, canUpdateForCase: true, canDeleteForCase: true };
        component.gridCase = new IpxKendoGridComponentMock() as any;
        component.gridName = new IpxKendoGridComponentMock() as any;
    });

    it('should create with correct parameters', () => {
        component.viewInitialiser = { ...component.viewInitialiser, ...{ canDeleteForCase: false } };
        expect(component).toBeDefined();
        component.ngOnInit();
        expect(component.matchType).toEqual('case');
        expect(component.formData).toEqual({
            inUse: true
        });

        expect(component.gridOptions).toBeDefined();
        expect(_.findWhere(component.gridOptions.bulkActions, { id: 'Delete' })).not.toBeDefined();
        expect(_.findWhere(component.gridOptions.bulkActions, { id: 'edit' })).toBeDefined();
    });
    it('should create with correct gridOptions for names', () => {
        component.viewInitialiser = { ...component.viewInitialiser, ...{ canCreateForName: true, canUpdateForName: false, canDeleteForName: false } };
        component.stateParams.matchType = 'name';
        component.ngOnInit();
        expect(component.gridOptions).toBeDefined();
        expect(component.gridOptions.autobind).toBeFalsy();
        expect(component.gridOptions.enableGridAdd).toBeTruthy();
        expect((component.gridOptions.selectable as any).mode).toEqual('single');
        expect(component.gridOptions.bulkActions).toBeFalsy();
        expect(component.gridOptions.selectedRecords).toBeFalsy();
        expect(component.gridOptions.columns).toEqual([{
            title: 'sanityCheck.configurations.grid.ruleDescription',
            field: 'ruleDescription',
            template: true,
            sortable: true,
            width: 180
        }, {
            title: 'sanityCheck.configurations.grid.nameGroup',
            field: 'nameGroup',
            template: false,
            sortable: true,
            width: 90
        }, {
            title: 'sanityCheck.configurations.grid.name',
            field: 'name',
            template: false,
            sortable: true,
            width: 90
        }, {
            title: 'sanityCheck.configurations.country',
            field: 'jurisdiction',
            template: false,
            sortable: true,
            width: 90
        }, {
            title: 'sanityCheck.configurations.grid.category',
            field: 'category',
            template: false,
            sortable: true,
            width: 90
        }, {
            title: 'sanityCheck.configurations.grid.organization',
            field: 'organization',
            defaultColumnTemplate: DefaultColumnTemplateType.selection,
            disabled: true,
            sortable: false,
            width: 60
        }, {
            title: 'sanityCheck.configurations.grid.individual',
            field: 'individual',
            defaultColumnTemplate: DefaultColumnTemplateType.selection,
            disabled: true,
            sortable: false,
            width: 60
        }, {
            title: 'sanityCheck.configurations.grid.clientOnly',
            field: 'client',
            defaultColumnTemplate: DefaultColumnTemplateType.selection,
            disabled: true,
            sortable: false,
            width: 60
        }, {
            title: 'sanityCheck.configurations.grid.staff',
            field: 'staff',
            defaultColumnTemplate: DefaultColumnTemplateType.selection,
            disabled: true,
            sortable: false,
            width: 60
        }, {
            title: 'sanityCheck.configurations.grid.supplierOnly',
            field: 'supplier',
            defaultColumnTemplate: DefaultColumnTemplateType.selection,
            disabled: true,
            sortable: false,
            width: 60
        }, {
            title: 'sanityCheck.configurations.grid.inUse',
            field: 'inUse',
            defaultColumnTemplate: DefaultColumnTemplateType.selection,
            disabled: true,
            sortable: false,
            width: 60
        }, {
            title: 'sanityCheck.configurations.grid.deferred',
            field: 'deferred',
            defaultColumnTemplate: DefaultColumnTemplateType.selection,
            disabled: true,
            sortable: false,
            width: 60
        }, {
            title: 'sanityCheck.configurations.grid.informational',
            field: 'informational',
            defaultColumnTemplate: DefaultColumnTemplateType.selection,
            disabled: true,
            sortable: false,
            width: 60
        }]);
    });
    it('should create with correct gridOptions', () => {
        component.viewInitialiser = { ...component.viewInitialiser, ...{ canCreateForCase: true, canUpdateForCase: false, canDeleteForCase: false } };
        expect(component).toBeDefined();
        component.ngOnInit();
        expect(component.gridOptions).toBeDefined();
        expect(component.gridOptions.autobind).toBeFalsy();
        expect(component.gridOptions.enableGridAdd).toBeTruthy();
        expect((component.gridOptions.selectable as any).mode).toEqual('single');
        expect(component.gridOptions.bulkActions).toBeFalsy();
        expect(component.gridOptions.selectedRecords).toBeFalsy();
        expect(component.gridOptions.columns).toEqual([
            { field: 'ruleDescription', sortable: true, template: true, title: 'sanityCheck.configurations.grid.ruleDescription', width: 180 },
            { field: 'caseOffice', sortable: true, template: true, title: 'sanityCheck.configurations.grid.caseOffice', width: 90 },
            { field: 'caseType', sortable: true, template: true, title: 'sanityCheck.configurations.grid.caseType', width: 120 },
            { field: 'jurisdiction', sortable: true, template: true, title: 'sanityCheck.configurations.grid.jurisdiction', width: 120 },
            { field: 'propertyType', sortable: true, template: true, title: 'sanityCheck.configurations.grid.propertyType', width: 120 },
            { field: 'caseCategory', sortable: false, template: true, title: 'sanityCheck.configurations.grid.caseCategory', width: 120 },
            { field: 'subType', sortable: false, template: true, title: 'sanityCheck.configurations.grid.subType', width: 120 },
            { field: 'basis', sortable: false, template: true, title: 'sanityCheck.configurations.grid.basis', width: 120 },
            { defaultColumnTemplate: 'selection', disabled: true, field: 'pending', sortable: false, title: 'sanityCheck.configurations.grid.pending', width: 60 },
            { defaultColumnTemplate: 'selection', disabled: true, field: 'registered', sortable: false, title: 'sanityCheck.configurations.grid.registered', width: 60 },
            { defaultColumnTemplate: 'selection', disabled: true, field: 'dead', sortable: false, title: 'sanityCheck.configurations.grid.dead', width: 60 },
            { defaultColumnTemplate: 'selection', disabled: true, field: 'inUse', sortable: false, title: 'sanityCheck.configurations.grid.inUse', width: 60 },
            { defaultColumnTemplate: 'selection', disabled: true, field: 'deferred', sortable: false, title: 'sanityCheck.configurations.grid.deferred', width: 60 },
            { defaultColumnTemplate: 'selection', disabled: true, field: 'informational', sortable: false, title: 'sanityCheck.configurations.grid.informational', width: 60 }]);
    });

    it('should set canAdd and enableGrid to false - for case sanity check', () => {
        component.stateParams.matchType = 'case';
        component.viewInitialiser = { ...component.viewInitialiser, ...{ canCreateForCase: false } };

        component.ngOnInit();

        expect(component.gridOptionsCase.canAdd).toBeFalsy();
        expect(component.gridOptionsCase.enableGridAdd).toBeFalsy();
    });

    it('should set canAdd and enableGrid to false - for name sanity check', () => {
        component.stateParams.matchType = 'name';
        component.viewInitialiser = { ...component.viewInitialiser, ...{ canCreateForName: false } };

        component.ngOnInit();

        expect(component.gridOptionsName.canAdd).toBeFalsy();
        expect(component.gridOptionsName.enableGridAdd).toBeFalsy();
    });

    it('should reset search data', () => {
        component.ngOnInit();
        component.formData = {
            abc: 'abc'
        };

        component.resetFormData();
        expect(component.formData).toEqual({
            inUse: true
        });
        expect(component.searchByComp.resetFormData).toHaveBeenCalled();
    });

    it('sanity check model should be correctly created for case', () => {
        component.ngOnInit();
        component.searchByCaseComp = {
            formData: {
                caseCategory: { code: 'caseCategory' },
                caseType: { code: 'caseTypeCode' },
                basis: { code: 'basis' },
                jurisdiction: { code: 'jurisdiction' },
                statusIncludePending: false,
                statusIncludeRegistered: null,
                statusIncludeDead: false,
                eventIncludeOccurred: null,
                event: { key: 111 },
                DeferredFlag: false,
                CaseOfficeKey: null,
                caseCategoryExclude: null,
                caseTypeExclude: true,
                jurisdictionExclude: false,
                propertyTypeExclude: null,
                subTypeExclude: null,
                applyTo: ''
            }
        } as any;
        component.formData = {
            notes: 'notes',
            displayMessage: 'displayMessage'
        };

        component.gridOptions.read$(null);
        expect(service.search$.mock.calls[0][0]).toEqual('case');
        expect(service.search$.mock.calls[0][1].caseCharacteristics.basis).toEqual('basis');
        expect(service.search$.mock.calls[0][1].caseCharacteristics.basisExclude).toEqual(false);
        expect(service.search$.mock.calls[0][1].caseCharacteristics.caseType).toEqual('caseTypeCode');
        expect(service.search$.mock.calls[0][1].caseCharacteristics.caseTypeExclude).toEqual(true);
        expect(service.search$.mock.calls[0][1].caseCharacteristics.caseCategory).toEqual('caseCategory');
        expect(service.search$.mock.calls[0][1].caseCharacteristics.caseCategoryExclude).toEqual(false);
        expect(service.search$.mock.calls[0][1].caseCharacteristics.office).toEqual(null);
        expect(service.search$.mock.calls[0][1].caseCharacteristics.jurisdiction).toEqual('jurisdiction');
        expect(service.search$.mock.calls[0][1].caseCharacteristics.jurisdictionExclude).toEqual(false);
        expect(service.search$.mock.calls[0][1].caseCharacteristics.statusIncludeDead).toEqual(false);
        expect(service.search$.mock.calls[0][1].caseCharacteristics.statusIncludePending).toEqual(false);
        expect(service.search$.mock.calls[0][1].caseCharacteristics.statusIncludeRegistered).toEqual(false);
        expect(service.search$.mock.calls[0][1].caseCharacteristics.applyTo).toBeNull();

        expect(service.search$.mock.calls[0][1].caseName).toEqual({
            name: null,
            nameGroup: null,
            nameType: null
        });
        expect(service.search$.mock.calls[0][1].event).toEqual({
            eventNo: 111,
            includeDue: false,
            includeOccurred: false
        });
        expect(service.search$.mock.calls[0][1].other).toEqual({
            tableColumn: null
        });
        expect(service.search$.mock.calls[0][1].ruleOverview).toEqual({
            deferred: null,
            displayMessage: 'displayMessage',
            inUse: null,
            informationOnly: null,
            mayBypassError: null,
            notes: 'notes',
            ruleDescription: undefined,
            sanityCheckSql: null
        });
        expect(service.search$.mock.calls[0][1].standingInstruction).toEqual({
            characteristics: null,
            instructionType: null
        });
    });

    it('sanity check model should be correctly created for name', () => {
        component.stateParams.matchType = 'name';
        component.ngOnInit();
        component.searchByNameComp = {
            formData: {}
        } as any;
        component.formData = {
            notes: 'notes',
            displayMessage: 'displayMessage'
        };

        component.gridOptions.read$(null);
        expect(service.search$.mock.calls[0][0]).toEqual('name');
        expect(service.search$.mock.calls[0][1].ruleOverview).toEqual({
            deferred: null,
            displayMessage: 'displayMessage',
            inUse: null,
            informationOnly: null,
            mayBypassError: null,
            notes: 'notes',
            ruleDescription: undefined,
            sanityCheckSql: null
        });
    });

    it('should set the UI for canDelete, canUpdate permission for case rules', () => {
        component.viewInitialiser = { canDeleteForCase: true, canUpdateForCase: false };
        component.ngOnInit();

        expect(component.gridOptions).toBeDefined();
        expect(_.findWhere(component.gridOptions.bulkActions, { id: 'edit' })).not.toBeDefined();
        expect(_.findWhere(component.gridOptions.bulkActions, { id: 'Delete' })).toBeDefined();
        expect((component.gridOptions.selectable as any).mode).toEqual('multiple');
        expect(component.gridOptions.bulkActions).toBeDefined();
        expect(component.gridOptions.selectedRecords.rows.rowKeyField).toEqual('id');
    });

    it('should enable the UI for canViewNames, canViewCase', () => {
        component.viewInitialiser = { canCreateForCase: true, canCreateForName: false, canDeleteForName: true, canUpdateForName: false };
        component.stateParams.matchType = 'name';
        component.ngOnInit();

        expect(component.canSelectCase).toBeTruthy();
        expect(component.canSelectName).toBeTruthy();
    });

    it('should disable the UI for canViewNames, canViewCase', () => {
        component.viewInitialiser = { canCreateForCase: false, canCreateForName: false, canDeleteForName: false, canUpdateForName: false };
        component.stateParams.matchType = 'name';
        component.ngOnInit();

        expect(component.canSelectCase).toBeFalsy();
        expect(component.canSelectName).toBeFalsy();
    });

    it('should delete the selected records', () => {
        component.viewInitialiser = { canDeleteForCase: true };

        notificationService.confirmDelete = jest.fn().mockReturnValue(of().toPromise().then(() => {
            expect(service.deleteSanityCheck$).toHaveBeenCalled();
        }));

        component.ngOnInit();

        component.gridOptions.bulkActions[0].click.call(component);

        expect(notificationService.confirmDelete).toHaveBeenCalled();
    });

    it('should edit selected record', () => {
        component.viewInitialiser = { canUpdateForCase: true };

        component.ngOnInit();

        component.navigateToEdit({ id: 10, rowKey: 1 });

        expect(stateService.go).toHaveBeenCalled();
        expect(stateService.go.mock.calls[0][0]).toEqual('sanityCheckMaintenanceEdit');
        expect(stateService.go.mock.calls[0][1].matchType).toEqual('case');
        expect(stateService.go.mock.calls[0][1].id).toEqual(10);
        expect(stateService.go.mock.calls[0][1].rowKey).toEqual(1);
    });

    it('should edit selected record, from bulk menu', () => {
        component.viewInitialiser = { canUpdateForCase: true };

        component.ngOnInit();

        component.edit({ allSelectedItem: [{ id: 1 }, { id: 10 }] } as any);
        expect(stateService.go).not.toHaveBeenCalled();

        component.edit({ allSelectedItem: [] } as any);
        expect(stateService.go).not.toHaveBeenCalled();

        component.edit({ allSelectedItem: [{ id: 100, rowKey: 1 }] } as any);
        expect(stateService.go).toHaveBeenCalled();
        expect(stateService.go.mock.calls[0][0]).toEqual('sanityCheckMaintenanceEdit');
        expect(stateService.go.mock.calls[0][1].matchType).toEqual('case');
        expect(stateService.go.mock.calls[0][1].id).toEqual(100);
        expect(stateService.go.mock.calls[0][1].rowKey).toEqual(1);
    });

    it('setsFormData, if isLevelUp', () => {
        component.viewInitialiser = { ...component.viewInitialiser, ...{ canCreateForCase: true, canUpdateForCase: false, canDeleteForCase: false } };
        const caseSearchCriteria = { caseCategory: 'abcd' };
        const otherSearchCriteria = { other: 'a' };

        component.stateParams = { matchType: 'case', isLevelUp: true };
        service.getSearchData.mockReturnValueOnce(caseSearchCriteria).mockReturnValueOnce(otherSearchCriteria);

        component.ngOnInit();
        component.gridOptions._search = jest.fn();

        component.ngAfterViewInit();
        expect(service.getSearchData).toHaveBeenCalledWith('caseCharacteristics');
        expect(service.getSearchData).toHaveBeenCalledWith('otherData');

        expect(component.searchByComp.resetFormData).toHaveBeenLastCalledWith(caseSearchCriteria);
        expect(component.formData).toEqual(otherSearchCriteria);
        expect(component.gridOptions._search).toHaveBeenCalled();
    });

    describe('shortcuts', () => {
        it('calls to initialize shortcut keys on init', () => {
            component.ngOnInit();
            expect(shortcutsService.observeMultiple$).toHaveBeenCalledWith([RegisterableShortcuts.ADD]);
        });

        it('calls add function - for Name Sanity check', fakeAsync(() => {
            component.stateParams.matchType = 'name';
            component.viewInitialiser = { ...component.viewInitialiser, ...{ canCreateForName: true } };

            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.ADD;
            component.ngOnInit();

            tick(shortcutsService.interval);
            expect(component.gridName.onAdd).toHaveBeenCalled();
        }));

        it('calls add function - for Case Sanity check', fakeAsync(() => {
            component.stateParams.matchType = 'case';
            component.viewInitialiser = { ...component.viewInitialiser, ...{ canCreateForCase: true } };

            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.ADD;
            component.ngOnInit();

            tick(shortcutsService.interval);
            expect(component.gridCase.onAdd).toHaveBeenCalled();
        }));
    });
});