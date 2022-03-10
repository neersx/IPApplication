import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, OnInit, Output } from '@angular/core';
import { AbstractControl, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { PriorArtService } from 'cases/prior-art/priorart.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Observable, race } from 'rxjs';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';

@Component({
  selector: 'update-first-linked',
  templateUrl: './update-first-linked.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [IpxDestroy]
})
export class UpdateFirstLinkedComponent implements OnInit {
  @Output() readonly confirmed$: EventEmitter<any> = new EventEmitter();
  defaultfirstLinked: any;
  caseKeys: Array<number>;
  formGroup: FormGroup;
  newLinkedCases: any;
  currentlyLinkedCases: any;
  sourceDocumentId: number;
  modalRef: BsModalRef;

  constructor(
    private readonly selfModalRef: BsModalRef,
    private readonly formBuilder: FormBuilder,
    private readonly service: PriorArtService,
    private readonly cdr: ChangeDetectorRef) {
  }

  ngOnInit(): void {
    this.formGroup = this.formBuilder.group({
      keepCurrent: false
    });
    this.service.getUpdateFirstLinkedCaseViewData$({caseKeys: this.caseKeys, sourceDocumentId: this.sourceDocumentId}).subscribe(response => {
      this.newLinkedCases = response.newLinkedCases;
      this.currentlyLinkedCases = response.currentlyLinkedCases;
      this.cdr.markForCheck();
    });
  }

  get keepCurrent(): AbstractControl {
    return this.formGroup.get('keepCurrent');
  }

  apply(): void {
    this.confirmed$.emit({ keepCurrent: this.keepCurrent.value });
    this.selfModalRef.hide();
  }

  getCaseKey(linkedCase: any): number {
      return linkedCase.id;
  }

  cancel(): void {
    this.selfModalRef.hide();
  }
}