import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject } from 'rxjs';
import { CaseListPicklistComponent } from 'shared/component/typeahead/ipx-picklist/ipx-picklist-modal-maintenance/case-list-picklist/case-list-picklist.component';
import { CaseList } from 'shared/component/typeahead/ipx-picklist/ipx-picklist-modal-maintenance/case-list-picklist/case-list-picklist.model';
import * as _ from 'underscore';

@Component({
  selector: 'app-caselist-modal',
  templateUrl: './caselist-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaselistModalComponent implements OnInit {

  private _caseList: CaseList;
  private readonly modalRef: BsModalRef;
  onClose$ = new BehaviorSubject({});
  modalTitle: string;
  isAddAnotherChecked = false;
  showAddAnother = false;
  @ViewChild('caseListComponent', { static: true }) caseListComponent: CaseListPicklistComponent;

  @Input() set caseList(valueRecieve: CaseList) {
    this._caseList = valueRecieve;
    this.showAddAnother = _.isEmpty(valueRecieve);
  }

  get caseList(): CaseList {
    return this._caseList;
  }

  constructor(bsModalRef: BsModalRef, private readonly translate: TranslateService) {
    this.modalRef = bsModalRef;
  }

  ngOnInit(): void {
    this.modalTitle = this.caseList ? this.translate.instant('picklist.caselist.editTitle') : this.translate.instant('picklist.caselist.addTitle');
  }

  canSave(): boolean {
    const state = this.caseListComponent.service.modalStates$.getValue();

    return state.canSave;
  }

  save(): void {
    this.caseListComponent.service.addOrUpdate$('api/picklists/CaseLists', this.caseListComponent.entry, this.onSuccess);
  }

  private readonly onSuccess = (response) => {
    this.modalRef.hide();
    if (this.showAddAnother) {
      this.onClose$.next({ addAnother: this.isAddAnotherChecked, newlyAddedCaselistKey: response.key });
    } else {
      this.onClose$.next(true);
    }
  };

  close = (): void => {
    if (this.caseListComponent.form.dirty) {
      this.caseListComponent.service.discard$(() => {
        this.modalRef.hide();
        this.onClose$.next(false);
      });
    } else {
      this.modalRef.hide();
      this.onClose$.next(false);
    }
  };

}
