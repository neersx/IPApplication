import { FormControl, NgForm } from '@angular/forms';
import { ChangeDetectorRefMock } from 'mocks';
import { PeriodTypes } from 'search/case/due-date/due-date.model';
import { TaskPlannerServiceMock } from 'search/task-planner/task-planner.service.mock';
import { DateFilterType } from '../search-builder.data';
import { GeneralSearchBuilderComponent } from './general-search-builder.component';

describe('GeneralSearchBuilderComponent', () => {
    let component: GeneralSearchBuilderComponent;
    const filterService = { getPeriodTypes: jest.fn() };
    let taskPlannerService: TaskPlannerServiceMock;
    let changeDetectorRef: ChangeDetectorRefMock;
    beforeEach(() => {
        taskPlannerService = new TaskPlannerServiceMock();
        changeDetectorRef = new ChangeDetectorRefMock();
        component = new GeneralSearchBuilderComponent(filterService as any, changeDetectorRef as any, taskPlannerService as any);
        component.topic = {
            params: {
                viewData: {
                    importanceLevels: [{ value: 'Normal', key: '1' }, { value: 'Importance', key: '2' }]
                }
            }
        } as any;
        component.generalForm = new NgForm(null, null);
        component.generalForm.form.addControl('belongingTo', new FormControl(null, null));
    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate ngOnInit', () => {
        component.ngOnInit();
        expect(component.viewData).toBeDefined();
        expect(component.importanceLevelOptions.length).toEqual(2);
    });

    it('validate set Date Filter Type as DateRange', () => {
        const from = new Date('2021-04-01T04:49:01Z');
        const to = new Date('2021-04-16T04:49:01Z');
        component.viewData = {
            formData: {
                general: {
                    dateFilter: {
                        dateFilterType: 0,
                        operator: '7',
                        dateRange: {
                            from: from.toString(),
                            to: to.toString()
                        },
                        datePeriod: {
                            from: null,
                            to: null,
                            periodType: null
                        }
                    }
                }
            }
        };
        component.setDateFilterType();
        expect(component.viewData.formData.general.dateFilter.dateRange).toEqual({ from, to });
    });

    it('validate initFormData', () => {
        component.initFormData();
        expect(component.formData).toBeDefined();
        expect(component.formData.includeFilter.reminders).toBeTruthy();
        expect(component.formData.includeFilter.dueDates).toBeTruthy();
        expect(component.formData.includeFilter.adHocDates).toBeTruthy();
        expect(component.formData.importanceLevel.from).toBeNull();
    });

    it('validate toggleRangePeriod with period', () => {
        component.initFormData();
        component.formData.dateFilter.dateFilterType = DateFilterType.period;
        component.toggleRangePeriod();
        expect(component.formData.dateFilter.dateRange.from).toBeNull();
        expect(component.formData.dateFilter.dateRange.to).toBeNull();
        expect(component.formData.dateFilter.datePeriod.periodType).toEqual(PeriodTypes.days);
    });

    it('validate toggleRangePeriod with range', () => {
        component.initFormData();
        component.formData.dateFilter.dateFilterType = DateFilterType.range;
        component.toggleRangePeriod();
        expect(component.formData.dateFilter.datePeriod.from).toBeNull();
        expect(component.formData.dateFilter.datePeriod.to).toBeNull();
    });

    it('validate changeAdHocDates with only adhoc date', () => {
        component.initFormData();
        component.formData.includeFilter.adHocDates = true;
        component.formData.includeFilter.dueDates = false;
        component.formData.includeFilter.reminders = false;
        component.formData.searchByFilter.reminderDate = false;
        component.formData.searchByFilter.dueDate = false;
        component.changeAdHocDates();
        expect(component.formData.searchByFilter.dueDate).toBeTruthy();
        expect(component.formData.searchByFilter.reminderDate).toBeTruthy();
        expect(component.formData.belongingToFilter.actingAs.isDueDate).toBeFalsy();
        expect(component.disabledDueDateResponsibleStaff).toBeTruthy();
    });

    it('validate changeAdHocDates with only adhoc date and reminder', () => {
        component.initFormData();
        component.formData.includeFilter.adHocDates = true;
        component.formData.includeFilter.dueDates = false;
        component.formData.includeFilter.reminders = true;
        component.formData.searchByFilter.reminderDate = false;
        component.formData.searchByFilter.dueDate = false;
        component.changeAdHocDates();
        expect(component.formData.searchByFilter.dueDate).toBeFalsy();
        expect(component.formData.searchByFilter.reminderDate).toBeFalsy();
        expect(component.disabledDueDateResponsibleStaff).toBeFalsy();
    });

    it('validate changeDueDates with only duedate', () => {
        component.initFormData();
        component.formData.includeFilter.reminders = false;
        component.formData.includeFilter.adHocDates = false;
        component.formData.includeFilter.dueDates = true;
        component.formData.searchByFilter.reminderDate = true;
        component.formData.searchByFilter.dueDate = false;
        component.changeDueDates();
        expect(component.formData.searchByFilter.dueDate).toBeTruthy();
        expect(component.formData.searchByFilter.reminderDate).toBeFalsy();
        expect(component.disabledReminderRecipient).toBeTruthy();
    });

    it('validate changeDueDates with duedate and reminder', () => {
        component.initFormData();
        component.formData.includeFilter.reminders = true;
        component.formData.includeFilter.adHocDates = false;
        component.formData.includeFilter.dueDates = true;
        component.formData.searchByFilter.dueDate = false;
        component.formData.searchByFilter.reminderDate = true;
        component.changeDueDates();
        expect(component.formData.searchByFilter.dueDate).toBeFalsy();
        expect(component.formData.searchByFilter.reminderDate).toBeTruthy();
    });

    it('validate changeReminders', () => {
        component.initFormData();
        component.formData.includeFilter.reminders = true;
        component.formData.searchByFilter.reminderDate = false;
        component.formData.searchByFilter.dueDate = false;
        component.changeReminders();
        expect(component.formData.searchByFilter.dueDate).toBeTruthy();
        expect(component.formData.searchByFilter.reminderDate).toBeTruthy();
    });

    it('validate changePeriodDate', () => {
        component.changePeriodDate();
        expect(changeDetectorRef.detectChanges).toHaveBeenCalled();
    });

    it('validate changeBelongingTo', () => {
        component.initFormData();
        component.formData.belongingToFilter.names = [{ value: 1 }];
        component.formData.belongingToFilter.nameGroups = [{ value: 14 }];
        component.changeBelongingTo();
        expect(component.formData.belongingToFilter.names).toBeNull();
        expect(component.formData.belongingToFilter.nameGroups).toBeNull();
    });

    it('validate changeDateOperator', () => {
        component.initFormData();
        component.formData.dateFilter.operator = '14';
        component.formData.dateFilter.datePeriod.from = 1;
        component.formData.dateFilter.datePeriod.to = 22;
        component.changeDateOperator();
        expect(component.formData.dateFilter.datePeriod.from).toBeNull();
        expect(component.formData.dateFilter.dateRange.from).toBeNull();
    });

    it('validate getFormData', () => {
        component.formData.includeFilter = { adHocDates: true, reminders: true, dueDates: false };
        component.formData.belongingToFilter = { value: 'myself', actingAs: { isDueDate: true, isReminder: false, nameTypes: [] }, names: null, nameGroups: null };
        component.formData.dateFilter = {
            dateFilterType: DateFilterType.period,
            operator: '7',
            datePeriod: { from: 1, to: 2, periodType: 'D' }
        };
        const result = component.getFormData();
        expect(result.searchRequest.include.isReminders).toEqual(1);
        expect(result.searchRequest.include.isDueDates).toEqual(0);
        expect(result.searchRequest.include.isAdHocDates).toEqual(1);
        expect(result.searchRequest.belongsTo.nameKey).toEqual({ isCUrrentUser: 1, operator: 0 });
        expect(result.searchRequest.importanceLevel).toBeNull();
        expect(result.searchRequest.dates.periodRange.from).toEqual(1);
        expect(result.searchRequest.dates.periodRange.to).toEqual(2);
        expect(result.searchRequest.dates.periodRange.operator).toEqual('7');
        expect(result.formData.general).toBe(component.formData);
    });

    it('disable reminders checkbox', () => {
        component.formData.includeFilter = { adHocDates: false, reminders: true, dueDates: false };

        component.changeReminders();
        expect(component.disableReminders).toBeTruthy();
        expect(component.disableAdHocDates).toBeFalsy();
        expect(component.disableDueDates).toBeFalsy();
    });

    it('disable duedates checkbox', () => {
        component.formData.includeFilter = { adHocDates: false, reminders: false, dueDates: true };

        component.changeDueDates();
        expect(component.disableReminders).toBeFalsy();
        expect(component.disableAdHocDates).toBeFalsy();
        expect(component.disableDueDates).toBeTruthy();
    });

    it('disable adhoc date checkbox', () => {
        component.formData.includeFilter = { adHocDates: true, reminders: false, dueDates: false };

        component.changeAdHocDates();
        expect(component.disableReminders).toBeFalsy();
        expect(component.disableAdHocDates).toBeTruthy();
        expect(component.disableDueDates).toBeFalsy();
    });

    it('validate isDirty when form is dirty', () => {
        component.generalForm.form.addControl('displayName', new FormControl(null));
        component.generalForm.controls.displayName.setValue('data');
        component.generalForm.controls.displayName.markAsDirty();
        expect(component.isDirty()).toEqual(true);
    });
    it('validate isDirty when form is not dirty', () => {
        component.generalForm.form.addControl('displayName', new FormControl(null));
        expect(component.isDirty()).toEqual(false);
    });
    it('validate setPristine', () => {
        component.generalForm.form.addControl('displayName', new FormControl(null));
        component.generalForm.controls.displayName.setValue('data');
        component.generalForm.controls.displayName.markAsDirty();
        component.setPristine();
        expect(component.isDirty()).toEqual(false);
    });
});
