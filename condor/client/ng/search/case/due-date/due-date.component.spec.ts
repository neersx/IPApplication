import { BsModalServiceMock, DateHelperMock, KeyBoardShortCutService, KnownNameTypesMock, TranslateServiceMock } from '../../../mocks';
import { SearchOperator } from '../../common/search-operators';
import { DueDateComponent } from './due-date.component';

describe('due date case search modal', () => {
    let component: DueDateComponent;
    let dueDateFilterServiceMock;
    const keyboardShortcutservice = new KeyBoardShortCutService();
    const bsModalServiceMock = new BsModalServiceMock();
    const translateService = new TranslateServiceMock();
    const knownType = new KnownNameTypesMock();
    const dateHelper = new DateHelperMock();

    beforeEach(() => {
        dueDateFilterServiceMock = {
            prepareFilter: jest.fn(),
            getPeriodTypes: jest.fn().mockReturnValue([{
                key: 'D',
                value: 'periodTypes.days'
            }, {
                key: 'W',
                value: 'periodTypes.weeks'
            }, {
                key: 'M',
                value: 'periodTypes.months'
            }, {
                key: 'Y',
                value: 'periodTypes.years'
            }])
        };

        component = new DueDateComponent(bsModalServiceMock as any, dueDateFilterServiceMock, knownType as any, translateService as any, keyboardShortcutservice as any, dateHelper as any);
        component.formData = {};
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('initialize when filter does not contain data', () => {
        component.existingFormData = undefined;
        component.initFormData = jest.fn();
        component.setMessage = jest.fn();
        component.showHideRangePeriod = jest.fn();
        component.ngOnInit();
        expect(component.initFormData).toHaveBeenCalled();

        component.existingFormData = {};
        component.existingFormData.rangetype = 1;
        component.ngOnInit();
        expect(component.showHideRangePeriod).toHaveBeenCalledWith(component.formData.rangeType, true);
    });

    it('Should set the message correctly for dueDateOnlyMessage', () => {
        component.hasDueDateColumn = true;
        component.hasAllDateColumn = false;
        component.setMessage();
        expect(component.warningMessage).toEqual('dueDate.dueDateOnlyMessage');
        expect(component.warningMessage).toBeDefined();
    });

    it('Should set the message correctly for allDateOnlyMessage', () => {
        component.hasDueDateColumn = false;
        component.hasAllDateColumn = true;
        component.setMessage();
        expect(component.warningMessage).toEqual('dueDate.allDateOnlyMessage');
        expect(component.warningMessage).toBeDefined();
    });
    it('Should set the message correctly for dueDateAndAllDateMessage', () => {
        component.hasDueDateColumn = true;
        component.hasAllDateColumn = true;
        component.setMessage();
        expect(component.warningMessage).toEqual('dueDate.dueDateAndAllDateMessage');
        expect(component.warningMessage).toBeDefined();
    });
    it('Should set the message correctly for neitherDueDateNorAllDateMessage', () => {
        component.hasDueDateColumn = false;
        component.hasAllDateColumn = false;
        component.setMessage();
        expect(component.warningMessage).toEqual('dueDate.neitherDueDateNorAllDateMessage');
        expect(component.warningMessage).toBeDefined();
    });

    it('check show and hide dateRange of due date on radio button change', () => {
        // radiobutton date range clicked
        let value = 1;
        component.showHideRangePeriod(value, true);
        expect(component.formData.isRange).toBeFalsy();
        expect(component.formData.isPeriod).toBeTruthy();

        // radiobutton date period clicked
        value = 0;
        component.showHideRangePeriod(value, true);
        expect(component.formData.isPeriod).toBeFalsy();
        expect(component.formData.isRange).toBeTruthy();
    });

    it('search from due date modal and apply filters from formData', () => {
        component.filterService.prepareFilter = jest.fn();
        component.formData = {
            event: true,
            adhoc: false,
            searchByRemindDate: false,
            isRange: true,
            isPeriod: false,
            rangeType: 3,
            searchByDate: true,
            dueDatesOperator: null,
            periodType: null,
            fromPeriod: 1,
            toPeriod: 1,
            startDate: new Date(),
            endDate: new Date(),
            importanceLevelOperator: SearchOperator.equalTo,
            importanceLevelFrom: '1',
            importanceLevelTo: '10',
            eventOperator: SearchOperator.equalTo,
            eventValue: null,
            eventCategoryOperator: SearchOperator.equalTo,
            eventCategoryValue: null,
            actionOperator: SearchOperator.equalTo,
            actionValue: '',
            isRenevals: true,
            isNonRenevals: true,
            isClosedActions: true,
            isAnyName: true,
            isStaff: true,
            isSignatory: true,
            nameTypeOperator: SearchOperator.equalTo,
            nameTypeValue: '',
            nameOperator: SearchOperator.equalTo,
            nameValue: '',
            nameGroupOperator: SearchOperator.equalTo,
            nameGroupValue: null,
            staffClassificationOperator: SearchOperator.equalTo,
            staffClassificationValue: ''
        };
        component.search();
        expect(component.filterService.prepareFilter).toHaveBeenCalledWith(component.formData);
    });

    it('close due date modal', () => {
        component.emitSearchParams = jest.fn();
        component.onClose();
        expect(component.emitSearchParams).toBeCalledWith(true);
    });

    it('at least renewal and non renewal action should be selected for due date filter', () => {
        component.formData = {
            isRenevals: false
        };
        component.manageRenewals(false);
        expect(component.formData.isRenevals).toEqual(true);

        component.formData = {
            isNonRenevals: false,
            isRenevals: true
        };
        component.manageRenewals(false);
        expect(component.formData.isNonRenevals).toEqual(true);
    });
});
