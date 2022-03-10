import { Injectable } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { TypeaheadConfig } from '../ipx-typeahead/typeahead.config.provider';
import { IpxModalOptions } from './ipx-picklist-modal-options';
import { IpxPicklistModalComponent } from './ipx-picklist-modal/ipx-picklist-modal.component';

@Injectable({
    providedIn: 'root'
})
export class IpxPicklistModalService {
    modalRef: BsModalRef;
    constructor(private readonly modalService: IpxModalService) { }

    openModal(modalOptions: IpxModalOptions, typeaheadOptions: TypeaheadConfig): BsModalRef {
        const modalClass = 'modal-' + (typeaheadOptions.size || 'lg');
        const initialState = {
            modalOptions,
            typeaheadOptions
        };
        this.modalRef = this.modalService.openModal(IpxPicklistModalComponent,
            { animated: false, class: modalClass, ignoreBackdropClick: true, initialState });

        return this.modalRef;
    }
}
