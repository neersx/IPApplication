// tslint:disable: no-use-before-declare
import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl } from '@angular/forms';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { distinctUntilChanged } from 'rxjs/operators';
import { slideInOutVisible } from 'shared/animations/common-animations';
import * as _ from 'underscore';
import { NavigationEnum } from '../ipx-picklist-search-field/ipx-picklist-search-field.component';

@Component({
  selector: 'ipx-picklist-case-search-panel',
  templateUrl: './ipx-picklist-case-search-panel.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  animations: [
    slideInOutVisible
  ]
})
export class IpxPicklistCaseSearchPanelComponent implements OnInit, AfterViewInit {
  navigation: NavigationEnum = NavigationEnum.current;
  @Input() model: any;
  showSearchBar = true;
  nameTypeDisabled = true;
  searchForm: any;
  searchText: string;
  validCombinationDescriptionsMap: any;
  extendValidCombinationPickList: any;
  lastCheckBox: any;
  @Output() readonly onSearch = new EventEmitter<any>();
  @Output() readonly onClear = new EventEmitter<any>();

  constructor(
    private readonly cdr: ChangeDetectorRef,
    private readonly fb: FormBuilder,
    private readonly vcService: CaseValidCombinationService) {
    this.validCombinationDescriptionsMap =
      vcService.validCombinationDescriptionsMap;
    this.extendValidCombinationPickList =
      vcService.extendValidCombinationPickList;
  }

  ngOnInit(): void {
    this.createSearchPanelForm();
    if (typeof (this.model) === 'string') {
      this.searchText = this.model;
    }
  }

  createSearchPanelForm(): void {
    this.searchForm = this.fb.group({
      office: new FormControl(),
      caseType: new FormControl(),
      name: new FormControl(),
      nameType: new FormControl(),
      jurisdiction: new FormControl(),
      propertyType: new FormControl(),
      pending: new FormControl(true),
      registered: new FormControl(true),
      dead: new FormControl(false)
    });
  }

  ngAfterViewInit(): void {
    this.searchForm.valueChanges.pipe(distinctUntilChanged()).subscribe(value => {
      const formValues = _.pairs(value);
      this.toggleFormFields(formValues);
      this.checkCaseStatus(formValues.splice(6, 3));
    });

    this.vcService.initFormData(this.searchForm.value);
    this.validCombinationDescriptionsMap = this.vcService.validCombinationDescriptionsMap;
    this.extendValidCombinationPickList = this.vcService.extendValidCombinationPickList;
  }

  search(value?: any): void {
    this.model = this.prepareFilter(this.searchForm.value);
    const action = value ? value.action : this.navigation;
    const eventValue = { value: this.model, action };
    this.onSearch.emit(eventValue);
  }

  getTextValue(value): any {
    this.searchText = value.value;
  }

  checkCaseStatus(checkBoxes: any): void {
    if (!checkBoxes.some(x => x[1])) {
      if (this.lastCheckBox[0] === 'pending') {
        this.searchForm.patchValue({ pending: true });
      } else if (this.lastCheckBox[0] === 'registered') {
        this.searchForm.patchValue({ registered: true });
      } else {
        this.searchForm.patchValue({ dead: true });
      }
    }

    const checkedItems = checkBoxes.filter(x => x[1]);
    if (checkedItems.length === 1) {
      this.lastCheckBox = checkedItems[0];
    }
  }

  prepareFilter = (value): CasePicklistSearchPanel => {
    const filter = new CasePicklistSearchPanel();
    filter.caseTypes = value.caseType ? value.caseType.map(x => x.code) : null;
    filter.caseOffices = value.office ? value.office.map(x => x.key) : null;
    filter.countryCodes = value.jurisdiction ? value.jurisdiction.map(x => x.key) : null;
    filter.propertyTypes = value.propertyType ? value.propertyType.map(x => x.code) : null;
    filter.nameType = value.nameType ? value.nameType.code : null;
    filter.nameKeys = value.name ? value.name.map(x => x.key) : null;
    filter.isDead = value.dead;
    filter.isPending = value.pending;
    filter.isRegistered = value.registered;
    filter.searchText = this.searchText;

    return filter;
  };

  clear(): void {
    this.model = '';
    this.searchText = '';
    this.navigation = NavigationEnum.current;
    this.resetForm();
    this.vcService.initFormData(this.searchForm.value);
    this.onClear.emit();
  }

  private resetForm(): void {
    this.searchForm.setValue({
      office: null,
      caseType: null,
      name: null,
      nameType: null,
      jurisdiction: null,
      propertyType: null,
      pending: true,
      registered: true,
      dead: false
    });
    this.nameTypeDisabled = true;
  }

  private toggleFormFields(values: any): void {
    if (values) {
      this.vcService.initFormData(this.searchForm.value);
      this.validCombinationDescriptionsMap = this.vcService.validCombinationDescriptionsMap;
      this.extendValidCombinationPickList = this.vcService.extendValidCombinationPickList;

      this.nameTypeDisabled = !values.some(x => x[0] === 'name' && x[1] && x[1].length > 0);
      if (this.nameTypeDisabled) {
        this.searchForm.patchValue({ nameType: null }, { onlySelf: true, emitEvent: false });
      }
    }
  }

  toggleSearchFieldAndPanel = (search): void => {
    this.searchText = search;
    this.cdr.markForCheck();
  };

  get pending(): AbstractControl {
    return this.searchForm.get('pending');
  }
  get registered(): AbstractControl {
    return this.searchForm.get('registered');
  }
  get dead(): AbstractControl {
    return this.searchForm.get('dead');
  }

  get jurisdiction(): AbstractControl {
    return this.searchForm.get('jurisdiction');
  }

  get office(): AbstractControl {
    return this.searchForm.get('office');
  }

  get propertyType(): AbstractControl {
    return this.searchForm.get('propertyType');
  }

  get caseType(): AbstractControl {
    return this.searchForm.get('caseType');
  }

  get name(): AbstractControl {
    return this.searchForm.get('name');
  }

  get nameType(): AbstractControl {
    return this.searchForm.get('nameType');
  }

}

export class CasePicklistSearchPanel {
  searchText: string;
  nameKeys?: Array<number>;
  nameType?: string;
  caseOffices?: Array<number>;
  caseTypes?: Array<string>;
  propertyTypes?: Array<string>;
  countryCodes?: Array<string>;
  isPending?: boolean;
  isRegistered?: boolean;
  isDead?: boolean;
}
