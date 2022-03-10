import { FormBuilder, FormControl, FormGroup } from '@angular/forms';
import { AdHocDateService, ChangeDetectorRefMock, EventNoteDetailServiceMock, IpxNotificationServiceMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { of } from 'rxjs';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { EventNoteDetailsComponent } from './event-note-details.component';
import { eventNoteEnum } from './event-notes.model';

describe('Event note details Component', () => {
    let component: () => EventNoteDetailsComponent;
    let cdr: ChangeDetectorRefMock;
    let translateService: any;
    const date = new Date();
    const eventNoteService = new EventNoteDetailServiceMock();
    const notificationservice = new NotificationServiceMock();
    const adHocDateService = new AdHocDateService();
    const modalService = { openModal: jest.fn() };
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        translateService = new TranslateServiceMock();
        const ipxNotificationService = new IpxNotificationServiceMock();
        component = (): EventNoteDetailsComponent => {

            const c = new EventNoteDetailsComponent(eventNoteService as any, cdr as any, translateService,
                new FormBuilder(), ipxNotificationService as any, notificationservice as any, modalService as any,
                adHocDateService as any);
            c.notes = [{
                cycle: 1,
                eventId: -102,
                eventText: '--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalan test notes 2\n--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalantest notes',
                isDefault: false,
                noteType: 1,
                lastUpdatedDateTime: date
            }];
            c.categories = [{
                description: 'Discription',
                code: 1
            }, {
                description: 'NullDiscription',
                code: null
            }];
            c.formGroup = new FormGroup({
                predefinedNote: new FormControl(),
                eventNoteType: new FormControl(),
                eventNoteText: new FormControl(),
                replaceNote: new FormControl(),
                createAdhoc: new FormControl()
            });
            c.maintainEventNotesPermissions = { update: true, insert: true };
            c.siteControlId = 1;
            c.ngOnInit();

            return c;
        };
    });

    describe('initialise view', () => {
        let c: EventNoteDetailsComponent;
        it('should initialise', () => {
            c = component();
            expect(c).toBeDefined();
            expect(c.notes).toEqual([{
                cycle: 1,
                eventId: -102,
                eventText: '--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalan test notes 2\n--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalantest notes',
                isDefault: false,
                noteType: 1,
                lastUpdatedDateTime: date
            }]);
        });

        it('should filter categorie', () => {
            c = component();

            expect(c.filteredCategories).toEqual([{
                description: 'Discription',
                code: 1
            }]);
        });

        it('should create event note items', () => {
            c = component();
            expect(c.eventTextItems[0].rowId).toEqual(0);
            expect(c.eventTextItems[1].rowId).toEqual(1);
        });
    });

    describe('Method tests', () => {
        let c: EventNoteDetailsComponent;
        it('should create formgroup', () => {
            c = component();
            const dataitem = { staffNameKey: 0, status: 'A' } as any;
            c.createFormGroup(dataitem);
            expect(c.gridOptions.enableGridAdd).toEqual(false);
            expect(c.gridOptions.formGroup).toBeDefined();
        }
        );
        it('should call Reset', () => {
            c = component();
            c.grid = new IpxKendoGridComponentMock() as any;
            c.taskPlannerRowKey = '1';
            c.currentRowIndex = 2;
            const dataitem = { staffNameKey: 0, status: 'A' };
            c.createFormGroup(dataitem);
            c.resetForm();
            expect(c.grid.rowEditFormGroups).toEqual(null);
            expect(c.gridOptions.formGroup).toEqual(null);
            expect(c.grid.currentEditRowIdx).toEqual(2);
            expect(c.grid.closeRow).toBeCalled();
        });

        it('should call makeEventNoteText for add', () => {
            c = component();
            c.grid = new IpxKendoGridComponentMock() as any;
            c.status = 'A';
            const eventNotes = { replaceNote: false, eventText: '...Note1', eventNoteType: 1 };
            c.makeEventNoteText(eventNotes);
            expect(eventNotes.eventText).toEqual('...Note1\r\n--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalan test notes 2\n\n--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalantest notes\n');
        });

        it('should call makeEventNoteText for add when replace note', () => {
            c = component();
            c.grid = new IpxKendoGridComponentMock() as any;
            c.status = 'A';
            const eventNotes = { replaceNote: true, eventText: '...Note1', eventNoteType: 1 };
            c.makeEventNoteText(eventNotes);
            expect(eventNotes.eventText).toEqual('...Note1\r\n');
        });

        it('should call makeEventNoteText for edit', () => {
            c = component();
            c.grid = new IpxKendoGridComponentMock() as any;
            c.status = 'E';
            const eventNotes = { replaceNote: false, eventText: '...Note1', eventNoteType: 1 };
            c.currentRowIndex = 0;
            c.makeEventNoteText(eventNotes);
            expect(eventNotes.eventText).toEqual('...Note1\n\n--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalantest notes\n');
        });

        it('should call makeEventNoteText for edit when replace note', () => {
            c = component();
            c.grid = new IpxKendoGridComponentMock() as any;
            c.status = 'E';
            const eventNotes = { replaceNote: true, eventText: '...Note1', eventNoteType: 1 };
            c.currentRowIndex = 0;
            c.makeEventNoteText(eventNotes);
            expect(eventNotes.eventText).toEqual('...Note1');
        });

        it('should call onChange when sitecontrolid is 0', () => {
            c = component();
            c.grid = new IpxKendoGridComponentMock() as any;
            const eventNotes = { value: 'Note1' };
            c.gridOptions.formGroup = c.formGroup;
            c.gridOptions.formGroup.controls.eventNoteText.setValue('Note2');
            c.onChange(eventNotes);
            expect(c.gridOptions.formGroup.controls.eventNoteText.value).toEqual('Note2\nNote1');
        });

        it('should call onChange when sitecontrolid is 1', () => {
            c = component();
            c.grid = new IpxKendoGridComponentMock() as any;
            const eventNotes = { value: 'Note1' };
            c.gridOptions.formGroup = c.formGroup;
            c.gridOptions.formGroup.controls.eventNoteText.setValue('Note2\r\nEnter notes here');
            c.siteControlId = 1;
            c.promptText = 'Enter notes here';
            c.onChange(eventNotes);
            expect(c.gridOptions.formGroup.controls.eventNoteText.value).toEqual('Note2\r\nNote1');
        });

        it('should call onChange when sitecontrolid is 2', () => {
            c = component();
            c.grid = new IpxKendoGridComponentMock() as any;
            const eventNotes = { value: 'Note1' };
            c.gridOptions.formGroup = c.formGroup;
            c.gridOptions.formGroup.controls.eventNoteText.setValue('Note2\r\nEnter notes here');
            c.siteControlId = 2;
            c.promptText = 'Enter notes here';
            c.onChange(eventNotes);
            expect(c.gridOptions.formGroup.controls.eventNoteText.value).toEqual('Note2\r\nNote1');
        });

        it('should call onSave', () => {
            c = component();
            c.grid = new IpxKendoGridComponentMock() as any;
            c.gridOptions.formGroup = c.formGroup;
            c.gridOptions.formGroup.controls.eventNoteText.setValue('Note2');
            c.taskPlannerRowKey = '25^267^-25^1';
            c.onSave();
            expect(c.gridOptions.formGroup.controls.eventNoteText.value).toEqual('Note2');
            expect(eventNoteService.maintainEventNotes).toHaveBeenCalled();
        });

        it('should call makeDefaultText', () => {
            c = component();
            c.grid = new IpxKendoGridComponentMock() as any;
            c.makeDefaultText();
            expect(eventNoteService.viewDataFormatting).toHaveBeenCalled();
        });

        it('should call notification service success onSave on subscribe', done => {
            c = component();
            c.grid = new IpxKendoGridComponentMock() as any;
            c.gridOptions.formGroup = c.formGroup;
            c.gridOptions.formGroup = c.formGroup;
            c.gridOptions.formGroup.controls.eventNoteText.setValue('Note2');
            c.taskPlannerRowKey = '25^267^-25^1';
            const response = { result: 'success' };
            eventNoteService.maintainEventNotes.mockReturnValue(of(response));
            c.onSave();
            eventNoteService.maintainEventNotes().subscribe((result: any) => {
                expect(result).toEqual(response);
                expect(notificationservice.success).toHaveBeenCalled();
                done();
            });
        });

        it('should call notification service info onSave on subscribe', done => {
            c = component();
            c.grid = new IpxKendoGridComponentMock() as any;
            c.gridOptions.formGroup = c.formGroup;
            c.gridOptions.formGroup = c.formGroup;
            c.gridOptions.formGroup.controls.eventNoteText.setValue('Note2');
            c.taskPlannerRowKey = '25^267^-25^1';
            const response = { result: 'partialsuccess' };
            eventNoteService.maintainEventNotes.mockReturnValue(of(response));
            c.onSave();
            eventNoteService.maintainEventNotes().subscribe((result: any) => {
                expect(result).toEqual(response);
                expect(notificationservice.info).toHaveBeenCalled();
                done();
            });
        });

        it('should call notification service info onSave and call launchAdhocDate', done => {
            c = component();
            c.grid = new IpxKendoGridComponentMock() as any;
            c.gridOptions.formGroup = c.formGroup;
            c.gridOptions.formGroup = c.formGroup;
            c.gridOptions.formGroup.controls.eventNoteText.setValue('Note2');
            c.gridOptions.formGroup.controls.createAdhoc.setValue(true);
            c.taskPlannerRowKey = '25^267^-25^1';
            const response = { result: 'partialsuccess' };
            eventNoteService.maintainEventNotes.mockReturnValue(of(response));
            c.onSave();
            eventNoteService.maintainEventNotes().subscribe((result: any) => {
                expect(result).toEqual(response);
                expect(notificationservice.info).toHaveBeenCalled();
                expect(eventNoteService.getDefaultAdhocInfo$).toHaveBeenCalled();
                expect(adHocDateService.viewData).toHaveBeenCalled();
                done();
            });
        });

        it('verify onSave method for providerInstructions', () => {
            c = component();
            c.grid = new IpxKendoGridComponentMock() as any;
            c.gridOptions.formGroup = c.formGroup;
            const eventNoteText = 'This is test note';
            const eventNoteType = 1;
            c.gridOptions.formGroup.controls.eventNoteText.setValue(eventNoteText);
            c.gridOptions.formGroup.controls.eventNoteType.setValue(eventNoteType);
            c.taskPlannerRowKey = '25^267^-25^1';
            const response = { result: 'partialsuccess' };
            eventNoteService.maintainEventNotes.mockReturnValue(of(response));
            c.eventNoteFrom = eventNoteEnum.provideInstructions;
            c.onSave();
            expect(c.notes.length).toEqual(1);
            expect(c.notes[0].noteType).toEqual(eventNoteType);
            expect(c.notes[0].lastUpdatedDateTime).toBeDefined();
            expect(c.saveCall).toBeTruthy();
            expect(c.gridOptions.formGroup).toBeNull();
            expect(c.grid.closeRow).toHaveBeenCalled();
            expect(c.grid.search).toHaveBeenCalled();
        });

    });
});