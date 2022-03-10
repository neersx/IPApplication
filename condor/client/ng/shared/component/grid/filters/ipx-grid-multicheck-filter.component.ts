// tslint:disable template-use-track-by-function
import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { FilterService } from '@progress/kendo-angular-grid';
import { CompositeFilterDescriptor, distinct, filterBy, FilterDescriptor } from '@progress/kendo-data-query';
import { Observable } from 'rxjs';

@Component({
  selector: 'multicheck-filter',
  templateUrl: './ipx-grid-multicheck-filter.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class MultiCheckFilterComponent implements OnInit, AfterViewInit {
  @Input() isPrimitive: boolean;
  @Input() currentFilter: CompositeFilterDescriptor;
  @Input() textField;
  @Input() valueField;
  @Input() filterService: FilterService;
  @Input() column: any;
  @Input() data: Array<any>;
  @Input() readFilterMeta: (column: any, otherFilters: any) => Observable<Array<any>>;
  @Output() readonly valueChange = new EventEmitter<Array<number>>();

  currentData: any;
  showFilter = true;
  private value: Array<any> = [];
  field: string;
  checkedCount = 0;
  selectAll = false;
  protected textAccessor = (dataItem: any) => this.isPrimitive ? dataItem : dataItem ? dataItem[this.textField] || '(empty)' : '(empty)';
  protected valueAccessor = (dataItem: any) => this.isPrimitive ? dataItem : dataItem ? dataItem[this.valueField] || 'empty' : '(empty)';
  constructor(private readonly cdr: ChangeDetectorRef) { }

  ngOnInit(): void {
    this.field = this.column.field;
    this.textField = this.textField || 'description';
    this.valueField = this.valueField || 'code';
  }

  ngAfterViewInit(): void {
    if (this.readFilterMeta) {
      this.readFilterMeta(this.column, [])
        .subscribe(arg => {
          this.data = arg;
          this.initialDataLoad();
        });
    } else {
      this.initialDataLoad();
    }
  }

  isItemSelected(item): any {
    return this.value.some(x => x === this.valueAccessor(item));
  }

  onSelectionChange(item, li): void {
    const itemValue = this.valueAccessor(item);
    if (this.value.some(x => x === itemValue)) {
      this.value = this.value.filter(x => x !== itemValue);
    } else {
      this.value.push(itemValue);
    }

    this.filterService.filter({
      filters: [{
        field: this.field,
        operator: 'in',
        value: this.value.join(',')
      }],
      logic: 'and'
    });

    this.checkedCount = this.value.length;

    this.onFocus(li);
  }

  onInput(e: any): void {
    this.currentData = distinct([
      ...this.currentData.filter(dataItem => this.value.some(val => val === this.valueAccessor(dataItem))),
      ...filterBy(this.data, {
        operator: 'contains',
        field: this.textField,
        value: e.target.value
      })],
      this.textField
    );
  }

  onFocus(li: any): void {
    const ul = li.parentNode;
    const below = ul.scrollTop + ul.offsetHeight < li.offsetTop + li.offsetHeight;
    const above = li.offsetTop < ul.scrollTop;

    // Scroll to focused checkbox
    if (below || above) {
      ul.scrollTop = li.offsetTop;
    }
  }

  onSelectAll(): void {
    this.value = this.selectAll ? this.currentData.map(v => this.valueAccessor(v)) : [];

    this.filterService.filter({
      filters: [{
        field: this.field,
        operator: 'in',
        value: this.value.join(',')
      }],
      logic: 'and'
    });

    this.checkedCount = this.value.length;
  }

  private initialDataLoad(): void {
    this.currentData = this.data;
    const joinedFilters = this.currentFilter.filters.map((f: FilterDescriptor) => f.value);
    if (joinedFilters.length > 0) {
      this.value = joinedFilters[0].split(',');
    }

    this.checkedCount = this.getCheckedItemCount();
    this.selectAll = this.currentData.length === this.checkedCount;

    this.showFilter = typeof this.textAccessor(this.currentData[0]) === 'string';

    this.cdr.markForCheck();
  }

  private getCheckedItemCount(): number {
    let count = 0;
    if (this.value.length > 0 && this.currentData.length > 0) {
      this.currentData.forEach(d => {
        if (this.isItemSelected(d)) {
          count++;
        }
      });
    }

    return count;
  }
}