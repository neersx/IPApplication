import { Injectable } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { IpxCaselistPicklistService } from 'shared/component/typeahead/ipx-picklist/ipx-picklist-modal-maintenance/case-list-picklist/ipx-caselist-picklist.service';
import { IpxModalOptions } from 'shared/component/typeahead/ipx-picklist/ipx-picklist-modal-options';
import { IpxPicklistModalService } from 'shared/component/typeahead/ipx-picklist/ipx-picklist-modal.service';
import { TypeAheadConfigProvider } from 'shared/component/typeahead/ipx-typeahead/typeahead.config.provider';
import * as _ from 'underscore';

@Injectable()
export class CaseListModalService {
  modalRefCaseList: any;

  constructor(
    private readonly notificationService: NotificationService,
    private readonly typeaheadConfigProvider: TypeAheadConfigProvider,
    private readonly picklistModalService: IpxPicklistModalService,
    private readonly caselistPicklistService: IpxCaselistPicklistService
  ) { }

  openCaselistModal = (selectedCaseKeys: string) => {
    const picklistOptions = new IpxModalOptions(false, '', [], false, false, '', '', null, null, false, false, false, '', false, false, false);
    const options = this.typeaheadConfigProvider.resolve({ config: 'caseList', autoBind: true, multiselect: false, multipick: false });
    picklistOptions.searchValue = '';
    picklistOptions.selectedItems = [];
    picklistOptions.extendedParams = () => {
      return {
        value: '',
        description: '',
        primeCase: null,
        caseKeys: selectedCaseKeys.split(',').map((key) => { return Number(key); }),
        newlyAddedCaseKeys: [],
        callbackSuccess: this.callbackSuccessCaseList,
        extendedActions: {
          picklistCanMaintain: true
        }
      };
    };
    this.modalRefCaseList = this.picklistModalService.openModal(picklistOptions, { ...options });
  };

  private readonly callbackSuccessCaseList = () => {
    if (this.modalRefCaseList) {
      this.modalRefCaseList.hide();
      this.notificationService.success();
    }
  };
}
