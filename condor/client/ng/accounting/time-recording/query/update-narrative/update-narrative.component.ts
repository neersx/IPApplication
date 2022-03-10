import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Output } from '@angular/core';
import { AbstractControl, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Observable, race } from 'rxjs';
import { filter, map, take, takeUntil, tap } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';

@Component({
  selector: 'update-narrative',
  templateUrl: './update-narrative.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [IpxDestroy]
})
export class UpdateNarrativeComponent implements AfterViewInit {
  @Output() readonly confirmed$: EventEmitter<any> = new EventEmitter();
  defaultNarrativeText: string;
  defaultNarrative: any;
  caseKey?: number;
  debtorKey?: number;
  formGroup: FormGroup;
  narrativeValueChange: Observable<any>;
  modalRef: BsModalRef;
  narrativeExtendQuery: any;

  constructor(
    private readonly ipxNotificationService: IpxNotificationService,
    private readonly selfModalRef: BsModalRef,
    private readonly formBuilder: FormBuilder,
    private readonly destroy$: IpxDestroy,
    private readonly cdRef: ChangeDetectorRef) {
    this.formGroup = this.formBuilder.group({
      narrative: [],
      narrativeText: ['', Validators.required]
    });
    this.narrativeExtendQuery = this.narrativesFor.bind(this);
  }

  ngAfterViewInit(): void {
    const narrativeNoPresent = !!this.defaultNarrative && _.isNumber(this.defaultNarrative.narrativeNo);
    this.narrative.setValue(narrativeNoPresent ? { key: this.defaultNarrative.narrativeNo, value: this.defaultNarrative.narrativeTitle, text: this.defaultNarrative.narrativeText } : null);
    this.narrativeText.setValue(narrativeNoPresent ? this.defaultNarrative.narrativeText : this.defaultNarrativeText);

    this.handleNarrativeChanges();
    this.handleNarrativeTextChanges();
  }

  get narrative(): AbstractControl {
    return this.formGroup.get('narrative');
  }

  get narrativeText(): AbstractControl {
    return this.formGroup.get('narrativeText');
  }

  handleNarrativeChanges(): any {
    this.narrative.valueChanges
      .pipe(takeUntil(this.destroy$))
      .subscribe(newValue => {
        if (!!newValue && !!newValue.text) {
          this.narrativeText.setValue(newValue.text, { emitEvent: false });
          this.narrativeText.setErrors(null);
          this.cdRef.detectChanges();
        }
      });
  }

  handleNarrativeTextChanges(): any {
    this.narrativeText.valueChanges
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => this.narrative.setValue(null, { emitEvent: false }));
  }

  apply(): void {
    const newText = this.narrativeText.value;

    this.modalRef = this.ipxNotificationService.openConfirmationModal(null, 'accounting.time.query.updateNarrativeConfirmation', 'Proceed', 'Cancel', null, { newNarrativeText: newText });

    race(
      this.ipxNotificationService.onHide$.pipe(filter((e) => e.isCancelOrEscape), map(() => false)),
      this.modalRef.content.confirmed$.pipe(map(() => true)))
      .pipe(take(1))
      .subscribe((isConfirmed: boolean) => {
        if (isConfirmed) {
          const newNarrativeNo = !!this.narrative.value && !!this.narrative.value.key ? this.narrative.value.key : null;
          this.confirmed$.emit({ narrativeNo: newNarrativeNo, narrativeText: newText });
        }
        this.selfModalRef.hide();
      });
  }

  cancel(): void {
    this.selfModalRef.hide();
  }

    narrativesFor(query: any): void {

        return _.extend({}, query, {
            debtorKey: this.debtorKey,
            caseKey: this.caseKey
        });
    }
}