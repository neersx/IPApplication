import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { TypeAheadConfigProvider } from 'shared/component/typeahead/ipx-typeahead/typeahead.config.provider';
import { TypeDecorator } from 'shared/component/utility/type.decorator';
import * as _ from 'underscore';
import { IpxPicklistMaintenanceService } from '../../ipx-picklist-maintenance.service';
import { IpxModalOptions } from '../../ipx-picklist-modal-options';
import { IpxPicklistModalService } from '../../ipx-picklist-modal.service';
import { PicklistMainainanceComponent } from '../ipx-picklist-maintenance-templates/ipx-picklist-mainainance.component';
import { CaseList } from './case-list-picklist.model';
import { IpxCaselistPicklistService } from './ipx-caselist-picklist.service';

@TypeDecorator('CaseListPicklistComponent')
@Component({
  selector: 'case-list-picklist',
  templateUrl: './case-list-picklist.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseListPicklistComponent implements OnInit, PicklistMainainanceComponent {
  static componentName = 'CaseListPicklistComponent';
  form: FormGroup;
  errorStatus: Boolean;
  private _entry: CaseList;
  private _extendedActions: any;
  gridoptions: IpxGridOptions;
  _caseGrid: IpxKendoGridComponent;
  casesInCaseList: Array<number> = [];
  newSelectedCases: Array<number> = [];
  deletingCases: Array<number> = [];
  state: any;
  @ViewChild('caseGrid', { static: false }) set caseGrid(grid: IpxKendoGridComponent) {
    if (grid && !(this._caseGrid === grid)) {
      this._caseGrid = grid;
    }
  }

  @Input() set entry(valueRecieve: CaseList) {
    this._entry = {
      key: null,
      value: null,
      description: null,
      primeCase: null,
      caseKeys: new Array<number>(),
      newlyAddedCaseKeys: new Array<number>()
    };

    if (valueRecieve) {
      this._entry.key = valueRecieve.key;
      this._entry.value = valueRecieve.value;
      this._entry.description = valueRecieve.description;
      this._entry.primeCase = valueRecieve.primeCase;
      this._entry.caseKeys = valueRecieve.caseKeys;
      this.casesInCaseList = this._entry.caseKeys;
      if (valueRecieve.newlyAddedCaseKeys) {
        this.newSelectedCases = valueRecieve.newlyAddedCaseKeys;
      }
    }
  }

  get entry(): CaseList {
    return this.getEntry();
  }

  @Input() set extendedActions(valueRecieve: any) {
    this._extendedActions = valueRecieve;
  }

  get extendedActions(): any {
    return this._extendedActions;
  }

  constructor(
    public service: IpxPicklistMaintenanceService,
    public caselistPicklistService: IpxCaselistPicklistService,
    private readonly cdf: ChangeDetectorRef,
    private readonly picklistModalService: IpxPicklistModalService,
    private readonly typeaheadConfigProvider: TypeAheadConfigProvider) {
    this.gridoptions = this.getGridOptions();
  }

  ngOnInit(): void {
    this.state = this.service.maintenanceMetaData$.getValue();
    this.errorStatus = false;
    this.form = new FormGroup({
      value: new FormControl(null, [Validators.required, Validators.maxLength(50)]),
      description: new FormControl(null, [Validators.maxLength(254)]),
      primeCase: new FormControl(null)
    });

    this.loadData();
    if (this.newSelectedCases.length > 0) {
      this.form.markAsDirty();
      this.setFormStatus();
      this.nextModalState('VALID');
    }
  }

  private readonly loadData = () => {
    this.form.setValue({
      value: this._entry.value,
      description: this._entry.description,
      primeCase: this._entry.primeCase
    });
    this.setFormStatus();
    this.form.statusChanges.subscribe((value) => {
      this.nextModalState(value);
    });
  };

  private readonly nextModalState = (value) => {
    const state = this.service.modalStates$.getValue();
    state.canSave = value === 'VALID' && this.form.dirty;

    if (this.errorStatus) {
      state.canSave = false;
      this.errorStatus = false;
    }
    this.service.nextModalState(state);
  };

  private setFormStatus(): void {
    this.form.updateValueAndValidity();
    this.cdf.markForCheck();
  }

  readonly getEntry = (): CaseList => {
    if (this.form) {
      this._entry.value = this.form.controls.value.value ? this.form.controls.value.value : null;
      this._entry.description = this.form.controls.description.value ? this.form.controls.description.value : null;
      this._entry.primeCase = this.form.controls.primeCase.value ? this.form.controls.primeCase.value : null;
      this._entry.caseKeys = this.casesInCaseList;
    }

    return this._entry;
  };

  validate(): void {
    this.errorStatus = !this.form.valid;
    this.cdf.markForCheck();
  }

  isEditable(): Boolean {
    return this.state.maintainabilityActions.action !== 'view' && ((this.state.maintainabilityActions.allowEdit && this.state.maintainability.canEdit) || this.state.maintainability.canAdd);
  }

  isDeletingCase(caseKey: number): Boolean {

    const isDeletingCase = _.some(this.deletingCases, (key: number) => {
      return key === caseKey;
    });

    return isDeletingCase;
  }

  private readonly getGridOptions = (): IpxGridOptions => {

    return {
      autobind: true,
      pageable: true,
      read$: (queryParams: GridQueryParameters) => {

        const primeCaseKey = this._entry.primeCase ? this._entry.primeCase.key : null;

        return this.caselistPicklistService.getCasesListItems$(this.casesInCaseList.concat(this.deletingCases), primeCaseKey, queryParams, this.newSelectedCases);
      },
      customRowClass: (context) => {
        const isNewlyAdded = _.some(this.newSelectedCases, (key: number) => {
          return key === context.dataItem.caseKey;
        });
        const isDeletingCase = _.some(this.deletingCases, (key: number) => {
          return key === context.dataItem.caseKey;
        });

        return isNewlyAdded ? 'added' : isDeletingCase ? 'deleted' : '';
      },
      columns: [
        {
          field: 'caseKey',
          title: '',
          width: 15,
          template: true
        },
        {
          field: 'caseRef',
          title: 'caseList.maintenance.caseRef',
          width: 100,
          template: true
        }, {
          field: 'officialNumber',
          title: 'caseList.maintenance.officialNo',
          width: 100
        }, {
          field: 'title',
          title: 'caseList.maintenance.title',
          width: 100,
          template: true
        },
        {
          field: 'isPrimeCase',
          title: 'caseList.maintenance.primeCase',
          width: 100,
          template: true,
          headerClass: 'k-header-center-aligned'
        }]
    };
  };

  delete = (caseKey: number): void => {
    const index: number = this.casesInCaseList.indexOf(caseKey);
    if (index !== -1) {
      this.casesInCaseList.splice(index, 1);
      this.setFormStatus();
    }

    this.deletingCases.push(caseKey);
    this.form.markAsDirty();
    this.setFormStatus();
  };

  revert = (caseKey: number): void => {
    const index: number = this.deletingCases.indexOf(caseKey);
    if (index !== -1) {
      this.deletingCases.splice(index, 1);
      this.casesInCaseList.push(caseKey);
    }
  };

  onAdd = (): void => {
    this.openModal();
  };

  private openModal(): void {
    const picklistOptions = new IpxModalOptions(false, '', [], false, false, '', '', null, null, false, false, false, '', false, false, false);
    const options = this.typeaheadConfigProvider.resolve({ config: 'case', autoBind: true, multiselect: true, multipick: true });
    picklistOptions.searchValue = '';
    picklistOptions.selectedItems = [];
    picklistOptions.multipick = true;
    const modalRef = this.picklistModalService.openModal(picklistOptions, { ...options });
    if (modalRef) {
      modalRef.content.selectedRow$.subscribe(
        (selectedcases: any) => {
          if (selectedcases.length > 0) {
            const selectedCasesKey = _.pluck(selectedcases, 'key');
            this.newSelectedCases = this.newSelectedCases.concat(selectedCasesKey);
            this.casesInCaseList = this.casesInCaseList.concat(selectedCasesKey);
            this.deletingCases = _.difference(this.deletingCases, selectedCasesKey);
            this.form.markAsDirty();
            this.setFormStatus();
          }
        }
      );
      modalRef.content.onClose$.subscribe(
        () => {
          if (this.newSelectedCases.length > 0) {
            this.setFormStatus();
            this._caseGrid.search();
          }
        }
      );
    }
  }
}