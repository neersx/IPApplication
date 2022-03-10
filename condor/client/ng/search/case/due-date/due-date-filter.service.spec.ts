import { DateHelperMock } from 'ajs-upgraded-providers/mocks/date-helper.mock';
import { SearchHelperService } from '../../common/search-helper.service';
import { SearchOperator } from '../../common/search-operators';
import { DueDateFilterService } from './due-date-filter.service';
import { DueDateFormData, PeriodTypes } from './due-date.model';

describe('due date filter criteria', () => {
    let service: DueDateFilterService;
    let formData: DueDateFormData;
    let caseSearchHelperService;
    let datehelper;

    beforeEach(() => {
        caseSearchHelperService = new SearchHelperService();
        datehelper = new DateHelperMock();
        service = new DueDateFilterService(caseSearchHelperService, datehelper);
        formData = {
            event: true,
            adhoc: false,
            searchByRemindDate: false,
            isRange: true,
            isPeriod: false,
            rangeType: 0,
            searchByDate: true,
            dueDatesOperator: SearchOperator.between,
            periodType: PeriodTypes.days,
            startDate: new Date('2019-10-02T08:05:10.000Z'),
            endDate: new Date('2019-10-02T08:05:10.000Z'),
            importanceLevelOperator: SearchOperator.equalTo,
            importanceLevelFrom: '1',
            importanceLevelTo: '10',
            eventOperator: SearchOperator.notEqualTo,
            eventValue: [{ key: -11303, code: null, value: 'Take over - certificates stage', alias: '', maxCycles: 1 }],
            eventCategoryOperator: SearchOperator.equalTo,
            eventCategoryValue: null,
            actionOperator: SearchOperator.equalTo,
            actionValue: [{ key: 23, code: 'RD', value: 'Renewal Display', cycles: 1, importanceLevel: '9' }],
            isRenevals: true,
            isNonRenevals: true,
            isClosedActions: true,
            isAnyName: true,
            isStaff: true,
            isSignatory: true,
            nameTypeOperator: SearchOperator.equalTo,
            nameTypeValue: '',
            nameOperator: SearchOperator.equalTo,
            nameValue: [{ key: -6325100, code: '063251', displayName: 'Associated Trademark & Patent Services', remarks: 'Riyadh/S Arabia', ceased: null }],
            nameGroupOperator: SearchOperator.equalTo,
            nameGroupValue: [{ key: -499, title: 'Foreign Agents', comments: 'Agents we use in foreign countries' }],
            staffClassificationOperator: SearchOperator.equalTo,
            staffClassificationValue: [{ key: 1501, code: null, value: 'Accountants', typeId: 15, type: null }]
        };
    });

    it('prepare filter for due date modal', () => {
        expect(service).toBeTruthy();
    });

    it('prepare filter for due date modal', () => {
        const result = service.prepareFilter(formData);
        expect(result).toEqual(
            {
                dueDates: {
                    useEventDates: 1,
                    useAdHocDates: 0,
                    dates: {
                        useDueDate: 1,
                        useReminderDate: 0,
                        dateRange: {
                            operator: '7',
                            from: '2019-10-02',
                            to: '2019-10-02'
                        }
                    },
                    actions: {
                        includeClosed: 1,
                        isRenewalsOnly: 1,
                        isNonRenewalsOnly: 1,
                        actionKey: { value: 'RD', operator: '0' }
                    },
                    dueDateResponsibilityOf: {
                        isAnyName: 1,
                        isSignatory: 1,
                        isStaff: 1,
                        nameGroupKey: { value: '-499', operator: '0' },
                        nameKey: { operator: '0', value: '-6325100' },
                        nameType: null,
                        staffClassificationKey: { value: '1501', operator: '0' }
                    },
                    eventCategoryKey: null,
                    eventKey: { value: '-11303', operator: '1' },
                    importanceLevel: {
                        from: '1',
                        operator: '0',
                        to: '10'
                    }
                }
            }
        );
    });
    it('ensure date fields are not set to todays date while preparing criteria', () => {
        formData.endDate = undefined;
        const result = service.prepareFilter(formData);
        expect(result).toEqual(
            {
                dueDates: {
                    useEventDates: 1,
                    useAdHocDates: 0,
                    dates: {
                        useDueDate: 1,
                        useReminderDate: 0,
                        dateRange: {
                            operator: '7',
                            from: '2019-10-02',
                            to: undefined
                        }
                    },
                    actions: {
                        includeClosed: 1,
                        isRenewalsOnly: 1,
                        isNonRenewalsOnly: 1,
                        actionKey: { value: 'RD', operator: '0' }
                    },
                    dueDateResponsibilityOf: {
                        isAnyName: 1,
                        isSignatory: 1,
                        isStaff: 1,
                        nameGroupKey: { value: '-499', operator: '0' },
                        nameKey: { operator: '0', value: '-6325100' },
                        nameType: null,
                        staffClassificationKey: { value: '1501', operator: '0' }
                    },
                    eventCategoryKey: null,
                    eventKey: { value: '-11303', operator: '1' },
                    importanceLevel: {
                        from: '1',
                        operator: '0',
                        to: '10'
                    }
                }
            }
        );
    });
});
