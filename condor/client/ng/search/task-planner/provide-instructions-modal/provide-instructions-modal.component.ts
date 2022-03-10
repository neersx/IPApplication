import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { DateService } from 'ajs-upgraded-providers/date-service.provider';
import { CommonUtilityService } from 'core/common.utility.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { eventNoteEnum } from 'portfolio/event-note-details/event-notes.model';
import { forkJoin, Observable, of } from 'rxjs';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { TaskPlannerViewData } from '../task-planner.data';
import { TaskPlannerService } from '../task-planner.service';
import { CaseInstruction, ProvideInstructionsViewData } from './provide-instructions.data';

@Component({
  selector: 'ipx-provide-instructions-modal',
  templateUrl: './provide-instructions-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ProvideInstructionsModalComponent implements OnInit {

  modalRef: BsModalRef;
  viewData: ProvideInstructionsViewData;
  resultPageViewData: TaskPlannerViewData;
  rowKey: string;
  dateFormat: any;
  eventNoteComponentData: {
    noteTypes: Array<any>;
    noteDetails: Array<any>;
    predefinedNoteType: any;
    siteControlId: any;
  };
  eventNoteEnum = eventNoteEnum;
  @Output() private readonly proceedClicked = new EventEmitter<any>();
  @Output() readonly onEventNoteUpdate: EventEmitter<any> = new EventEmitter<any>();
  @ViewChild('provideInstructionsForm', { static: true }) form: NgForm;

  constructor(bsModalRef: BsModalRef,
    private readonly dateService: DateService, private readonly dateHelper: DateHelper,
    private readonly cdRef: ChangeDetectorRef,
    private readonly taskPlannerService: TaskPlannerService,
    private readonly translate: TranslateService,
    private readonly commonService: CommonUtilityService,
    private readonly ipxNotificationService: IpxNotificationService
  ) {
    this.modalRef = bsModalRef;
  }

  ngOnInit(): void {
    this.dateFormat = this.dateService.dateFormat;
    this.viewData.instructionDate = this.dateHelper.convertForDatePicker(new Date());
    this.getEventNoteComponentData();
  }

  onClose(): void {
    this.modalRef.hide();
  }

  proceed(): void {
    this.proceedClicked.emit({
      instructions: this.getData(),
      instructionDate: this.form.form.controls.instructionDate.valid && this.viewData.instructionDate ? this.dateHelper.toLocal(this.viewData.instructionDate) : null
    });
    this.modalRef.hide();
  }

  openEventNoteModel = (ci: CaseInstruction): void => {
    ci.showEventNote = true;
    this.cdRef.detectChanges();
  };

  getEventNoteComponentData = (): void => {
    const eventNoteTypelst = this.taskPlannerService.getEventNoteTypes$();
    const existNote = this.taskPlannerService.isPredefinedNoteTypeExist();
    const siteControl = this.taskPlannerService.siteControlId();
    forkJoin([eventNoteTypelst, existNote, siteControl])
      .subscribe(([eventNoteResponse, noteTypeExist, siteControlId]) => {
        this.eventNoteComponentData = {
          noteTypes: eventNoteResponse,
          noteDetails: [],
          predefinedNoteType: noteTypeExist,
          siteControlId
        };
      });
  };

  private getData(): Array<CaseInstruction> {
    if (!this.viewData.instructions) {
      return [];
    }

    return this.viewData.instructions.filter(x => { return x.responseNo !== ''; });
  }

  isValid(): boolean {
    return this.form.valid && this.getData().length > 0;
  }

  hasUnsavedEventNotes(ci: CaseInstruction): boolean {

    return ci.selectedAction && ci.selectedAction.eventNotes && ci.selectedAction.eventNotes.length > 0;
  }

  chooseInstruction(ci: CaseInstruction): void {
    if (this.hasUnsavedEventNotes(ci)) {
      const oldSelectedAction = ci.selectedAction;
      const discardModalRef = this.ipxNotificationService.openDiscardModal();
      discardModalRef.content.cancelled$.subscribe(() => {
        ci.responseNo = oldSelectedAction.responseSequence;
        this.eventNoteComponentData.noteDetails = oldSelectedAction.eventNotes;
        this.cdRef.markForCheck();

        return;
      });
      discardModalRef.content.confirmed$.subscribe(() => {
        ci.selectedAction.eventNotes = [];
        this.eventNoteComponentData.noteDetails = [];
        this.rowKey = '';
        this.allowInstructionResponseToChange(ci);
      });
    } else {
      this.allowInstructionResponseToChange(ci);
    }
  }

  private allowInstructionResponseToChange(ci: CaseInstruction): void {
    ci.selectedAction = ci.actions.find(x => { return x.responseSequence === ci.responseNo; });
    ci.selectedAction.eventNotes = [];
    ci.responseLabel = ci.selectedAction ? ci.selectedAction.responseLabel : null;
    ci.eventNameTooltip = this.commonService.formatString(this.translate.instant('taskPlanner.provideInstructions.eventNotes.eventNameInfo'), ci.selectedAction.eventName);
    ci.eventNotesGroupTooltip = ci.selectedAction.eventNotesGroup ?
      this.commonService.formatString(this.translate.instant('taskPlanner.provideInstructions.eventNotes.eventNotesGroupInfo'), ci.selectedAction.eventNotesGroup)
      : '';
    ci.showEventNote = false;
    this.rowKey = 'I^' + ci.caseKey + '^' + ci.selectedAction.eventNo + '^' + ci.instructionCycle;
    this.cdRef.detectChanges();
  }

  getFireEventDescription(ci: CaseInstruction): string {

    return ci.eventNameTooltip + ci.eventNotesGroupTooltip;
  }

  getResponseExplanation(ci: CaseInstruction): string {

    return ci.selectedAction ? ci.selectedAction.responseExplanation : null;
  }

  handleUpdateInstructionNotes = (event: any) => {
    const instruction = this.getData().find(x => { return x.instructionDefinitionKey === event.instructionDefinitionKey; });
    if (instruction && instruction.selectedAction) {
      const note = instruction.selectedAction.eventNotes.find(x => { return x.noteType === event.note.noteType; });
      if (note) {
        note.eventText = event.note.eventText;
      } else {
        instruction.selectedAction.eventNotes.push(event.note);
      }
    }
  };

  trackByFn = (index: number): any => {
    return index;
  };
}
