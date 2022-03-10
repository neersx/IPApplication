import { ChangeDetectionStrategy, Component, EventEmitter, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { RoleSearchService, RoleSearchState } from '../role-search.service';
import { RoleSearch } from '../roles.model';

@Component({
    selector: 'role-search',
    templateUrl: './role-search-maintenance.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class RoleSearchMaintenanceComponent implements OnInit {
    formData = new RoleSearch();
    modalRef: BsModalRef;
    states: string;
    dataItem: any;
    roleSearchState = RoleSearchState;
    @Output() readonly searchRecord: EventEmitter<any> = new EventEmitter();
    @ViewChild('roleSearch', { static: true }) ngForm: NgForm;

    constructor(private readonly roleSearchService: RoleSearchService,
        private readonly notificationService: NotificationService, private readonly ipxNotificationService: IpxNotificationService) { }

    ngOnInit(): void {
        this.formData.isExternal = false;
        if (this.states === RoleSearchState.DuplicateRole) {
            this.formData.description = this.dataItem.description;
            this.formData.isExternal = this.dataItem.isExternal;
        }
    }

    save(): void {
        if (!this.validate()) {
            return;
        }

        this.roleSearchService.saveRole(this.formData, this.states, this.dataItem && this.dataItem.roleId).subscribe(r => {
            if (r.result === 'success') {
                this.notificationService.success();
                this.searchRecord.emit({ runSearch: true, roleId: r.roleId });
            } else {
                const errors = r.errors;
                const error = _.find(errors, (er: any) => {
                    return er.field === 'rolename';
                });
                const message = error.message;
                this.ipxNotificationService.openAlertModal('modal.unableToComplete', message, errors);
                this.ngForm.controls.rolename.markAsTouched();
                this.ngForm.controls.rolename.markAsDirty();
                this.ngForm.controls.rolename.setErrors({ notunique: true });
            }
        });
    }

    title = () => {
        switch (this.states) {
            case RoleSearchState.DuplicateRole: {
                return 'roleDetails.duplicateRole';
            }
            case RoleSearchState.Adding: {
                return 'roleDetails.addrole';
            }
            case RoleSearchState.Updating: {
                return 'roleDetails.editRol';
            }
            default: {
                return 'roleDetails.addrole';
            }
        }
    };

    validate = () => {
        return this.ngForm.valid;
    };

    disable = (): boolean => {
        return !this.ngForm.dirty || !this.ngForm.valid;
    };

    onClose(): void {
        if (this.ngForm.dirty) {
            this.modalRef = this.ipxNotificationService.openDiscardModal();
            this.modalRef.content.confirmed$.subscribe(() => {
                this.searchRecord.emit({ runSearch: false });

            });
        } else {
            this.searchRecord.emit({ runSearch: false });
        }
    }
}