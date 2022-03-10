import { FormControl, NgForm } from '@angular/forms';
import { DateServiceMock } from 'ajs-upgraded-providers/mocks/date-service.mock';
import { CommonUtilityServiceMock } from 'core/common.utility.service.mock';
import { BsModalRefMock, ChangeDetectorRefMock, DateHelperMock, IpxNotificationServiceMock, TranslateServiceMock } from 'mocks';
import { TaskPlannerServiceMock } from '../task-planner.service.mock';
import { ProvideInstructionsModalComponent } from './provide-instructions-modal.component';
import { CaseInstruction, ProvideInstructionsViewData } from './provide-instructions.data';

describe('ProvideInstructionsModalComponent', () => {
    let component: ProvideInstructionsModalComponent;
    let modalRef: BsModalRefMock;
    let dateService: DateServiceMock;
    let dateHelper: DateHelperMock;
    let cdref: ChangeDetectorRefMock;
    let taskPlannerService: TaskPlannerServiceMock;
    let translate: TranslateServiceMock;
    let commonService: CommonUtilityServiceMock;
    let notificationService: IpxNotificationServiceMock;

    beforeEach(() => {
        modalRef = new BsModalRefMock();
        dateHelper = new DateHelperMock();
        dateService = new DateServiceMock();
        cdref = new ChangeDetectorRefMock();
        taskPlannerService = new TaskPlannerServiceMock();
        translate = new TranslateServiceMock();
        commonService = new CommonUtilityServiceMock();
        notificationService = new IpxNotificationServiceMock();

        component = new ProvideInstructionsModalComponent(modalRef as any,
            dateService as any,
            dateHelper as any,
            cdref as any,
            taskPlannerService as any,
            translate as any,
            commonService as any,
            notificationService as any
        );
        component.viewData = new ProvideInstructionsViewData();
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('verify ngOnInit method', () => {
        component.ngOnInit();
        expect(component.dateFormat).toEqual('DD-MMM-YYYY');
        expect(dateHelper.convertForDatePicker).toHaveBeenCalled();
        expect(taskPlannerService.getEventNoteTypes$).toHaveBeenCalled();
        expect(taskPlannerService.isPredefinedNoteTypeExist).toHaveBeenCalled();
        expect(taskPlannerService.siteControlId).toHaveBeenCalled();
    });

    it('verify onClose method', () => {
        component.onClose();
        expect(modalRef.hide).toHaveBeenCalled();
    });

    it('verify isValid method with valid value', () => {
        component.viewData.instructions = [
            {
                responseNo: '1',
                caseKey: 12,
                instructionCycle: 1,
                responseLabel: 'Test 1',
                actions: [],
                instructionDefinitionKey: 1,
                instructionExplanation: null,
                instructionName: 'Name 1',
                selectedAction: null,
                eventData: null,
                eventNameTooltip: null,
                eventNotesGroupTooltip: null,
                showEventNote: null
            }
        ];
        component.form = new NgForm(null, null);
        component.form.form.addControl('instructionDate', new FormControl(null, null));
        const result = component.isValid();
        expect(result).toBeTruthy();
    });

    it('verify isValid method with invalid value', () => {
        component.viewData.instructions = [
            {
                responseNo: '',
                caseKey: 12,
                instructionCycle: 1,
                responseLabel: 'Test 1',
                actions: [],
                instructionDefinitionKey: 1,
                instructionExplanation: null,
                instructionName: 'Name 1',
                selectedAction: null,
                eventData: null,
                eventNameTooltip: null,
                eventNotesGroupTooltip: null,
                showEventNote: null
            }
        ];

        component.form = new NgForm(null, null);
        component.form.form.addControl('instructionDate', new FormControl(null, null));
        const result = component.isValid();
        expect(result).toBeFalsy();
    });

    it('verify proceed', () => {
        component.viewData.instructions = [
            {
                responseNo: '1',
                caseKey: 12,
                instructionCycle: 1,
                responseLabel: 'Test 1',
                actions: [],
                instructionDefinitionKey: 1,
                instructionExplanation: null,
                instructionName: 'Name 1',
                selectedAction: null,
                eventData: null,
                eventNameTooltip: null,
                eventNotesGroupTooltip: null,
                showEventNote: null
            }
        ];

        component.form = new NgForm(null, null);
        component.form.form.addControl('instructionDate', new FormControl(null, null));
        component.proceed();
        expect(modalRef.hide).toHaveBeenCalled();
    });

    it('verify openEventNoteModel', () => {
        const inst: CaseInstruction = {
            actions: [
                { responseLabel: 'No Action', responseSequence: '', responseExplanation: null, eventName: 'event 1', eventNotesGroup: null, eventNo: null, eventNotes: [] },
                { responseLabel: 'Resp Label 1', responseSequence: '1', responseExplanation: null, eventName: 'event 2', eventNotesGroup: 'event group 2', eventNo: null, eventNotes: [] },
                { responseLabel: 'Resp Label 2', responseSequence: '2', responseExplanation: 'exp 2', eventName: 'event 3', eventNotesGroup: null, eventNo: null, eventNotes: [] }
            ],
            caseKey: 12,
            instructionCycle: 1,
            instructionDefinitionKey: 22,
            instructionExplanation: null,
            instructionName: 'name 1',
            responseLabel: null,
            responseNo: '1',
            selectedAction: null,
            eventData: null,
            eventNameTooltip: null,
            eventNotesGroupTooltip: null,
            showEventNote: null
        };
        component.openEventNoteModel(inst);
        expect(inst.showEventNote).toBeTruthy();
        expect(cdref.detectChanges).toHaveBeenCalled();
    });

    it('verify chooseInstruction for saved selection', () => {
        component.viewData.instructions = [
            {
                responseNo: '1',
                caseKey: 12,
                instructionCycle: 1,
                responseLabel: 'Test 1',
                actions: [],
                instructionDefinitionKey: 1,
                instructionExplanation: null,
                instructionName: 'Name 1',
                selectedAction: null,
                eventData: null,
                eventNameTooltip: null,
                eventNotesGroupTooltip: null,
                showEventNote: null
            }
        ];

        const inst: CaseInstruction = {
            actions: [
                { responseLabel: 'No Action', responseSequence: '', responseExplanation: null, eventName: 'event 1', eventNotesGroup: null, eventNotes: [], eventNo: null },
                { responseLabel: 'Resp Label 1', responseSequence: '1', responseExplanation: null, eventName: 'event 2', eventNotesGroup: 'event group 2', eventNotes: [], eventNo: null },
                { responseLabel: 'Resp Label 2', responseSequence: '2', responseExplanation: 'exp 2', eventName: 'event 3', eventNotesGroup: null, eventNotes: [], eventNo: null }
            ],
            caseKey: 12,
            instructionCycle: 1,
            instructionDefinitionKey: 22,
            instructionExplanation: null,
            instructionName: 'name 1',
            responseLabel: null,
            responseNo: '1',
            selectedAction: null,
            eventData: null,
            eventNameTooltip: null,
            eventNotesGroupTooltip: null,
            showEventNote: null
        };
        component.chooseInstruction(inst);
        expect(inst.selectedAction).toBeDefined();
        expect(inst.selectedAction.responseLabel).toEqual('Resp Label 1');
        expect(inst.selectedAction.responseSequence).toEqual('1');
        expect(inst.selectedAction.responseExplanation).toBeNull();
        expect(cdref.detectChanges).toHaveBeenCalled();
    });

    it('verify chooseInstruction for unsaved selection', () => {
        component.viewData.instructions = [
            {
                responseNo: '1',
                caseKey: 12,
                instructionCycle: 1,
                responseLabel: 'Test 1',
                actions: [],
                instructionDefinitionKey: 1,
                instructionExplanation: null,
                instructionName: 'Name 1',
                selectedAction: null,
                eventData: null,
                eventNameTooltip: null,
                eventNotesGroupTooltip: null,
                showEventNote: null
            }
        ];

        const inst: CaseInstruction = {
            actions: [
                { responseLabel: 'No Action', responseSequence: '', responseExplanation: null, eventName: 'event 1', eventNotesGroup: null, eventNotes: [], eventNo: null },
                { responseLabel: 'Resp Label 1', responseSequence: '1', responseExplanation: null, eventName: 'event 2', eventNotesGroup: 'event group 2', eventNotes: null, eventNo: null },
                { responseLabel: 'Resp Label 2', responseSequence: '2', responseExplanation: 'exp 2', eventName: 'event 3', eventNotesGroup: null, eventNotes: null, eventNo: null }
            ],
            caseKey: 12,
            instructionCycle: 1,
            instructionDefinitionKey: 22,
            instructionExplanation: null,
            instructionName: 'name 1',
            responseLabel: 'Resp Label 1',
            responseNo: '1',
            selectedAction: { responseLabel: 'Resp Label 1', responseSequence: '1', responseExplanation: null, eventName: 'event 2', eventNotesGroup: 'event group 2', eventNotes: [{ eventText: 'notes 1' }], eventNo: null },
            eventData: null,
            eventNameTooltip: null,
            eventNotesGroupTooltip: null,
            showEventNote: null
        };

        component.chooseInstruction(inst);
        expect(inst.selectedAction).toBeDefined();
        expect(notificationService.openDiscardModal).toHaveBeenCalled();
        expect(notificationService.modalRef.content.cancelled$.subscribe).toHaveBeenCalled();
        expect(notificationService.modalRef.content.confirmed$.subscribe).toHaveBeenCalled();
    });

    it('verify trackByFn method', () => {
        const result = component.trackByFn(20);
        expect(result).toEqual(20);
    });

    it('verify getEventNoteComponentData method', () => {
        component.getEventNoteComponentData();
        expect(taskPlannerService.getEventNoteTypes$).toHaveBeenCalled();
        expect(taskPlannerService.isPredefinedNoteTypeExist).toHaveBeenCalled();
        expect(taskPlannerService.siteControlId).toHaveBeenCalled();
    });

    it('verify handleUpdateInstructionNotes', () => {
        component.viewData.instructions = [
            {
                responseNo: '1',
                caseKey: 12,
                instructionCycle: 1,
                responseLabel: 'Test 1',
                actions: [],
                instructionDefinitionKey: 1,
                instructionExplanation: null,
                instructionName: 'Name 1',
                selectedAction: {
                    eventName: 'event name',
                    eventNotes: []
                } as any,
                eventData: null,
                eventNameTooltip: null,
                eventNotesGroupTooltip: null,
                showEventNote: null
            }
        ];

        component.form = new NgForm(null, null);
        component.form.form.addControl('instructionDate', new FormControl(null, null));
        component.handleUpdateInstructionNotes({ instructionDefinitionKey: 1, note: { eventText: 'note 1', noteType: null } });
        expect(component.viewData.instructions[0].selectedAction.eventNotes.length).toEqual(1);
        expect(component.viewData.instructions[0].selectedAction.eventNotes[0].eventText).toEqual('note 1');
    });

});