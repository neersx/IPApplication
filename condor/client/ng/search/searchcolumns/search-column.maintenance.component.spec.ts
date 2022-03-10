import { FormControl, NgForm, Validators } from '@angular/forms';
import { ChangeDetectorRefMock, GridNavigationServiceMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { Observable } from 'rxjs';
import { SearchColumnMaintenanceComponent } from './search-column.maintenance.component';
import { ItemType } from './search-columns.model';

describe('SearchColumnMaintenanceComponent', () => {
    let component: SearchColumnMaintenanceComponent;
    let searchColumnsService: any;
    let gridNavigationService: GridNavigationServiceMock;
    const modalService = new ModalServiceMock();
    const changeRefMock = new ChangeDetectorRefMock();
    const notificationServiceMock = new NotificationServiceMock();
    beforeEach(() => {
        searchColumnsService = {
            searchColumn: jest.fn().mockReturnValue(new Observable()),
            saveSearchColumn: jest.fn().mockReturnValue(new Observable()),
            updateSearchColumn: jest.fn().mockReturnValue(new Observable()
            )
        };
        gridNavigationService = new GridNavigationServiceMock();
        component = new SearchColumnMaintenanceComponent(modalService as any, searchColumnsService, notificationServiceMock as any, notificationServiceMock as any, changeRefMock as any, gridNavigationService as any);
        component.ngForm = new NgForm(null, null);
        component.ngForm.form.addControl('displayName', new FormControl(null, Validators.required));
        component.ngForm.form.addControl('columnName', new FormControl(null, Validators.required));
        component.ngForm.form.addControl('dataItem', new FormControl(null, Validators.required));
        component.ngForm.form.addControl('parameter', new FormControl(null, Validators.required));
        component.searchColumn = {
            columnId: 15,
            displayName: 'Acceptance Date',
            columnName: {
                key: 51,
                description: 'EventDate',
                queryContext: 2,
                isQualifierAvailable: true,
                isUserDefined: false,
                dataFormat: 'Date',
                isUsedBySystem: false
            },
            parameter: '-7',
            docItem: null,
            description: 'The date the case was acceptedr',
            isMandatory: false,
            isVisible: true,
            dataFormat: 'Date',
            columnGroup: null
        };
        component.navData = {
            keys: [{ key: '1', value: '-134' }, { key: '2', value: '21' }, { key: '3', value: '-133'}, { key: '4', value: '51' }],
            totalRows: 4,
            pageSize: 0,
            fetchCallback: jest.fn()
        };
    });

    it('should initialize SearchColumnsComponent', () => {
        expect(component).toBeTruthy();
    });
    it('should call onInit on updating state', () => {
        component.states = 'updating';
        component.ngOnInit();
        expect(searchColumnsService.searchColumn).toHaveBeenCalled();
    });
    it('should initialize navigation params on updating state', () => {
        component.states = 'updating';
        component.displayNavigation = true;
        component.columnId = 21;
        jest.spyOn(gridNavigationService, 'getNavigationData').mockReturnValue(component.navData);

        component.ngOnInit();
        expect(component.navData.keys).toEqual([{ key: '1', value: '-134' }, { key: '2', value: '21' }, { key: '3', value: '-133' }, { key: '4', value: '51' }]);
        expect(component.currentKey).toEqual('2');
    });

    it('should call emitSearchColumnParams method', () => {
        const a = spyOn(component.searchColumnRecord, 'emit').and.returnValue({ isModalClosed: true });
        component.emitSearchColumnParams(true);
        expect(a).toHaveBeenCalledWith(true);
    });

    it('should validate the form successfully', () => {
        const result = component.validate();
        expect(result).toEqual(true);
    });
    it('should invoke required validation for display name', () => {
        component.searchColumn.displayName = '';
        const result = component.validate();
        expect(component.ngForm.controls.displayName.errors).toEqual({ required: true });
        expect(result).toEqual(false);
    });
    it('should invoke required validation for column name', () => {
        component.searchColumn.columnName = null;
        const result = component.validate();
        expect(component.ngForm.controls.columnName.errors).toEqual({ required: true });
        expect(result).toEqual(false);
    });
    it('should invoke required validation for doc item', () => {
        component.searchColumn.columnName.isUserDefined = true;
        const result = component.validate();
        expect(component.ngForm.controls.dataItem.errors).toEqual({ required: true });
        expect(result).toEqual(false);
    });
    it('should invoke required validation for parameter', () => {
        component.searchColumn.columnName.isQualifierAvailable = true;
        component.searchColumn.parameter = '';
        const result = component.validate();
        expect(component.ngForm.controls.parameter.errors).toEqual({ required: true });
        expect(result).toEqual(false);
    });
    it('should invoke validation for dataitem item type stored procedure', () => {
        component.searchColumn.docItem = {
            itemType: ItemType.StoredProcedure
        };
        const result = component.validate();
        expect(component.ngForm.controls.dataItem.errors).toEqual({ 'searchColumn.invalidDocitem': true });
        expect(result).toEqual(false);
    });

    it('should call saveSearchColumn method on adding', () => {
        component.internalContext = 1;
        component.externalContext = 2;
        component.states = 'adding';
        component.saveSearchColumn();
        expect(searchColumnsService.saveSearchColumn).toHaveBeenCalled();
    });

    it('should call saveSearchColumn method on adding', () => {
        component.internalContext = 1;
        component.externalContext = 2;
        component.states = 'adding';
        component.saveSearchColumn();
        expect(searchColumnsService.saveSearchColumn).toHaveBeenCalled();
    });

    it('should call saveSearchColumn method on updating', () => {
        component.internalContext = 1;
        component.externalContext = 2;
        component.states = 'updating';
        component.saveSearchColumn();
        expect(searchColumnsService.updateSearchColumn).toHaveBeenCalled();
    });

    it('should call saveSearchColumn method on updating', () => {
        const response = {
            result: 'success',
            updatedId: 15
        };
        searchColumnsService.savedSearchColumns = [];
        component.afterSave(response);
        expect(searchColumnsService.savedSearchColumns).toEqual([15]);
    });

    it('should call onClose extendedParamGroupPicklist ', () => {
        component.queryContextKey = 1;
        const result = component.extendedParamGroupPicklist();
        expect(result).toEqual({ contextId: 1 });
    });
});