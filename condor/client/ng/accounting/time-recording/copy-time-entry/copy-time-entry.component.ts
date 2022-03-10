import { ChangeDetectionStrategy, Component, EventEmitter, OnInit, Output } from '@angular/core';
import { take } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { TimeSearchService } from '../query/time-search.service';
import { UserInfoService } from '../settings/user-info.service';
import { TimeEntry } from '../time-recording-model';

@Component({
  selector: 'copy-time-entry',
  templateUrl: './copy-time-entry.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CopyTimeEntryComponent implements OnInit {
  searchGridOptions: IpxGridOptions;
  private staffNameId: number;
  @Output() readonly selectedEntry$ = new EventEmitter<TimeEntry>();
  constructor(private readonly timeSearchService: TimeSearchService,
    private readonly userInfo: UserInfoService) { }

  ngOnInit(): void {
    this.userInfo.userDetails$
      .pipe(take(1))
      .subscribe((res) => {
        this.staffNameId = res.staffId;
        this.initGridOptions();
      });
  }

  initGridOptions = (): void => {
    this.searchGridOptions = {
      columnPicker: false,
      filterable: false,
      navigable: true,
      sortable: true,
      autobind: true,
      reorderable: true,
      manualOperations: true,
      selectable: {
        mode: 'single'
      },
      read$: (queryParams: GridQueryParameters) => {
        queryParams.take = 30;

        return this.timeSearchService.recentEntries$(this.staffNameId, queryParams);
      },
      columns: [{
        title: 'accounting.time.fields.date',
        field: 'start',
        width: 100,
        template: true
      }, {
        title: 'accounting.time.fields.case',
        field: 'caseReference',
        width: 120,
        template: true
      }, {
        title: 'accounting.time.fields.name',
        field: 'name',
        width: 180,
        template: true
      }, {
        title: 'accounting.time.fields.activity',
        field: 'activity',
        width: 180
      }, {
        title: 'accounting.time.fields.narrativeText',
        field: 'narrativeText',
        width: 300,
        template: true
      }, {
        title: 'accounting.time.fields.notes',
        field: 'notes',
        width: 300,
        template: true,
        hidden: true
      }],
      sort: [{
        field: 'start',
        dir: 'desc'
      }]
    };
  };

  dataItemClicked = (entry: TimeEntry): void => {
    this.selectedEntry$.next(entry);
  };

  cancel = (): void => {
    this.selectedEntry$.next(null);
  };
}
