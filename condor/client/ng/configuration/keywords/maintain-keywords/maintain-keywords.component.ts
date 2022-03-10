import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject, Subject, Subscription } from 'rxjs';
import { take, takeUntil } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import { KeywordItems } from '../keywords.model';
import { KeywordsService } from '../keywords.service';

@Component({
  selector: 'ipx-maintain-keywords',
  templateUrl: './maintain-keywords.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [IpxDestroy]
})
export class MaintainKeywordsComponent implements OnInit {
  @Input() id: any;
  @Input() isAdding: boolean;
  form: any;
  canNavigate: boolean;
  entry: KeywordItems;
  navData: {
    keys: Array<any>,
    totalRows: number,
    pageSize: number,
    fetchCallback(currentIndex: number): any
  };
  onClose$ = new Subject();
  subscription: Subscription;
  modalRef: BsModalRef;
  addedRecordId$ = new Subject();
  currentKey: number;

  constructor(readonly service: KeywordsService,
    private readonly cdRef: ChangeDetectorRef,
    private readonly ipxNotificationService: IpxNotificationService,
    readonly sbsModalRef: BsModalRef,
    readonly formBuilder: FormBuilder,
    private readonly navService: GridNavigationService,
    private readonly destroy$: IpxDestroy,
    private readonly shortcutsService: IpxShortcutsService) {
  }

  ngOnInit(): void {
    this.createFormGroup();
    if (!this.isAdding) {
      this.canNavigate = true;
      this.getKeywordDetails(this.id);

      this.navData = {
        ...this.navService.getNavigationData(),
        fetchCallback: (currentIndex: number): any => {
          return this.navService.fetchNext$(currentIndex).toPromise();
        }
      };
      this.currentKey = this.navData.keys.filter(x => x.value === this.id.toString())[0].key;
    } else {
      this.entry = new KeywordItems();
    }
    this.handleShortcuts();
  }

  handleShortcuts(): void {
    const shortcutCallbacksMap = new Map(
      [[RegisterableShortcuts.SAVE, (): void => { this.submit(); }],
      [RegisterableShortcuts.REVERT, (): void => { this.cancel(); }]]);
    this.shortcutsService.observeMultiple$([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT])
      .pipe(takeUntil(this.destroy$))
      .subscribe((key: RegisterableShortcuts) => {
        if (!!key && shortcutCallbacksMap.has(key)) {
          shortcutCallbacksMap.get(key)();
        }
      });
  }

  getKeywordDetails(keywordNo: number): any {
    if (keywordNo) {
      this.service.getKeyWordDetails(keywordNo).subscribe(res => {
        if (res) {
          this.setFormData(res);
          this.cdRef.detectChanges();
        }
      });
    }
  }

  createFormGroup = (): FormGroup => {
    this.form = this.formBuilder.group({
      keywordNo: this.id,
      keyword: ['', Validators.required],
      caseStopWord: [false],
      nameStopWord: [false],
      synonyms: null
    });
    this.cdRef.markForCheck();

    return this.form;
  };

  setFormData(data): any {
    this.form.setValue({
      keywordNo: data.keywordNo,
      keyword: data.keyWord,
      caseStopWord: data.caseStopWord,
      nameStopWord: data.nameStopWord,
      synonyms: data.synonyms ? data.synonyms : null
    });
  }

  getNextKeywordDetails(next: number): void {
    this.id = next;
    this.form.markAsPristine();
    this.getKeywordDetails(next);
  }

  submit(): void {
    if (this.form.valid && this.form.value && this.form.dirty) {
      this.service.submitKeyWord(this.form.value).subscribe((res) => {
        if (res) {
          this.addedRecordId$.next(res);
          this.onClose$.next({ success: true });
          this.form.setErrors(null);
          this.sbsModalRef.hide();
        }
        this.cdRef.markForCheck();
      });
    }
  }

  cancel(): void {
    if (this.form.dirty) {
      const modal = this.ipxNotificationService.openDiscardModal();
      modal.content.confirmed$.pipe(
        take(1))
        .subscribe(() => {
          this.resetForm();
        });
    } else {
      this.resetForm();
    }
  }

  resetForm = (): void => {
    this.form.reset();
    this.onClose$.next(false);
    this.sbsModalRef.hide();
  };

}
