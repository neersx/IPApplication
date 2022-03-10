import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, TemplateRef, ViewChild } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup, ValidationErrors } from '@angular/forms';
import { aggregateBy } from '@progress/kendo-data-query';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject, race } from 'rxjs';
import { debounceTime, map, skip, startWith, take, takeUntil, tap, withLatestFrom } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { DateFunctions } from 'shared/utilities/date-functions';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import { TimeSettingsService } from '../settings/time-settings.service';
import { TimeCalculationService } from '../time-calculation.service';
import { LocalSettings } from '../time-recording.namespace';
import { TimeGapsService, WorkingHours } from './time-gaps.service';

@Component({
  selector: 'app-time-gaps',
  templateUrl: './time-gaps.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [IpxDestroy, TimeGapsService]
})
export class TimeGapsComponent implements OnInit, AfterViewInit {
  @Input() viewData: any;
  @Input() callBack: any;
  @ViewChild('timeGaps', { static: false }) _grid: IpxKendoGridComponent;
  @Output() readonly onRowSelect = new EventEmitter();

  @ViewChild('durationFooter', { static: true }) footer: TemplateRef<any>;
  @ViewChild('toTimeFooter', { static: true }) toTimeFooter: TemplateRef<any>;

  form: FormGroup;
  get timeRangeFrom(): AbstractControl {
    return this.form.get('timeRangeFrom');
  }
  get timeRangeTo(): AbstractControl {
    return this.form.get('timeRangeTo');
  }

  gridOptions: IpxGridOptions;
  totalSeconds: any;
  minToAllowed?: Date;
  disableAdd: boolean;
  disableAddChanges = new BehaviorSubject(true);
  modalRef: BsModalRef;
  timeRange: any;

  constructor(public cdref: ChangeDetectorRef,
    private readonly gapsService: TimeGapsService,
    readonly settingsService: TimeSettingsService,
    private readonly notificationService: NotificationService,
    readonly formBuilder: FormBuilder,
    readonly timeCalcService: TimeCalculationService,
    readonly ipxNotificationService: IpxNotificationService,
    private readonly $destroy: IpxDestroy) {
  }

  ngOnInit(): void {
    this.viewData.selectedDate = DateFunctions.getDateOnly(new Date(this.viewData.selectedDate));

    this.gapsService.getWorkingHoursFromServer(this.viewData.selectedDate)
      .pipe(take(1), takeUntil(this.$destroy))
      .subscribe((workingHours: WorkingHours) => {
        this.createFormGroup(workingHours);
        this.cdref.detectChanges();
      });

    this.gridOptions = this.buildGridOptions();

    this.disableAddChanges.subscribe((disableAddBtn: boolean) => {
      this.disableAdd = disableAddBtn;
      this.cdref.markForCheck();
    });

    this.gapsService.preferenceSaved$()
      .pipe(takeUntil(this.$destroy))
      .subscribe(() => this.notificationService.success('accounting.time.gaps.prefSaved'));
  }

  private readonly createFormGroup = (workingHours: WorkingHours): void => {
    this.timeRange = workingHours;
    this.form = this.formBuilder.group({
      timeRangeFrom: new FormControl(workingHours.from),
      timeRangeTo: new FormControl(workingHours.to)
    });

    this.form.setValidators(this._checkTimeRangeTo);

    const fromValueChange = this.timeRangeFrom.valueChanges
      .pipe(startWith(workingHours.from),
        debounceTime(100),
        map(val => this.timeCalcService.parsePartiallyEnteredTime(val)),
        map(val => !!val ? val : DateFunctions.setTimeOnDate(this.viewData.selectedDate, 0, 0, 0)));

    const toValueChange = this.timeRangeTo.valueChanges
      .pipe(startWith(workingHours.to),
        debounceTime(100),
        map(val => this.timeCalcService.parsePartiallyEnteredTime(val)),
        map(val => !!val ? val : DateFunctions.setTimeOnDate(this.viewData.selectedDate, 23, 59, 59)));

    fromValueChange
      .pipe(tap(val => { this.minToAllowed = val; }),
        withLatestFrom(toValueChange),
        skip(1))
      .subscribe(([fromDate, toDate]) => this.rangeChanged(fromDate, toDate));

    toValueChange
      .pipe(withLatestFrom(fromValueChange),
        skip(1))
      .subscribe(([toDate, fromDate]) => this.rangeChanged(fromDate, toDate));
  };

  ngAfterViewInit(): void {
    this.disableAddChanges.next(true);
  }

  buildGridOptions(): IpxGridOptions {
    return {
      sortable: true,
      autobind: true,
      persistSelection: true,
      manualOperations: true,
      read$: () => this.gapsService.getGaps(this.viewData.userNameId, this.viewData.selectedDate, { ...this.timeRange }),
      columns: [
        {
          title: 'accounting.time.gaps.fromTime',
          field: 'startTime',
          sortable: true,
          template: true,
          width: 100
        },
        {
          title: 'accounting.time.gaps.toTime',
          field: 'finishTime',
          sortable: true,
          template: true,
          width: 100,
          footer: this.toTimeFooter
        },
        {
          title: 'accounting.time.gaps.duration',
          field: 'durationInSeconds',
          sortable: true,
          template: true,
          footer: this.footer
        }
      ],
      onDataBound: (boundData: any) => {
        this.totalSeconds = aggregateBy(boundData, [{ aggregate: 'sum', field: 'durationInSeconds' }]);
        this.cdref.markForCheck();
      },
      selectable: {
        mode: 'multiple',
        enabled: true
      },
      selectedRecords: {
        rows: {
          rowKeyField: 'id',
          selectedKeys: [],
          selectedRecords: []
        }
      },
      gridMessages: {
        performSearch: 'accounting.time.gaps.noGapsFound',
        noResultsFound: 'accounting.time.gaps.noGapsFound'
      }
    };
  }

  onRowSelectionChanged(event: any): void {
    this.disableAddOnCondition();
    this.onRowSelect.emit({ value: event.rowSelection });
  }

  disableAddOnCondition(): void {
    this.disableAddChanges.next(this._grid ? (this._grid.getRowSelectionParams().allSelectedItems.length ? false : true) : true);
    this.cdref.detectChanges();
  }

  createItems(): void {
    if (this.disableAdd) {
      return;
    }
    if (!!this.viewData.hasPendingChanges) {
      this.modalRef = this.ipxNotificationService.openConfirmationModal('modal.unsavedchanges.title', 'accounting.time.gaps.discardPendingChanges', 'Proceed', 'Cancel');
      race(this.modalRef.content.confirmed$.pipe(map(() => true)),
        this.ipxNotificationService.onHide$.pipe(map(() => false)))
        .pipe(take(1), takeUntil(this.$destroy))
        .subscribe((confirmed: boolean) => {
          if (!!confirmed) {
            this._addEntries();
            this.viewData.hasPendingChanges = false;
          }
        });
    } else {
      this._addEntries();
    }
  }

  _addEntries(): void {
    this.disableAddChanges.next(true);
    const selectedGaps = this._grid.getRowSelectionParams().allSelectedItems;
    this.gapsService.addEntries(selectedGaps).subscribe((res: Array<any>) => {
      const firstAddedGapEntryNo = !!res && !!res.entries && res.entries.length > 0 ? res.entries[0].entryNo : null;
      this.notificationService.success();
      this._grid.search();
      this.viewData.onAddition(firstAddedGapEntryNo);
    });
  }

  private readonly _checkTimeRangeTo = (): ValidationErrors | null => {
    const currentValue = this.timeCalcService.parsePartiallyEnteredTime(this.timeRangeTo.value);

    if (!!currentValue && !!this.minToAllowed && currentValue.getTime() <= this.minToAllowed.getTime()) {
      this.timeRangeTo.markAsDirty();
      this.timeRangeTo.markAsTouched();
      this.timeRangeTo.setErrors({ errorMessage: 'accounting.time.gaps.timeRangeCheck' });

      return { errorMessage: 'rangeError' };
    }

    this.timeRangeTo.setErrors(null);

    return null;
  };

  rangeChanged = (fromValue: Date, toValue: Date): void => {
    this.timeRangeTo.updateValueAndValidity({ emitEvent: false });

    if (!this.form.valid) {
      this._grid.clear();

      return;
    }

    this.timeRange.from = new Date(fromValue);
    this.timeRange.to = new Date(toValue);

    this.gridOptions._search();
    this.gapsService.saveWorkingHours({ ...this.timeRange });
  };
}
