import { ChangeDetectionStrategy, Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { StateService } from '@uirouter/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { BsModalRef } from 'ngx-bootstrap/modal';
import * as _ from 'underscore';
import { IpxNotificationService } from '../notification/notification/ipx-notification.service';

@Component({
    selector: 'ipx-detail-page-nav',
    templateUrl: './detail-page-nav.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class DetailPageNavComponent implements OnInit {
    @Input() routerState: string;
    @Input() paramKey: string;
    @Input() lastSearch?: any;
    @Input() ids?: any;
    @Input() totalRows?: number;
    @Input() pageSize?: number;
    @Input() fetchNext: (currentIndex: number) => any;
    @Input() routerParams: any;
    @Input() currentKey: string;
    @Input() noParams = false;
    @Input() hasUnsavedChanges = false;
    @Input() refreshKey: any;
    @Output() readonly nextResult: EventEmitter<any> = new EventEmitter<any>();
    detailNavigate = new EventEmitter<any>();
    modalRef: BsModalRef;

    visible = false;
    current: number;
    total: number;
    prevId: string;
    nextId: string;
    canFetchNext: boolean;
    available: number;
    firstId: string;
    lastId: string;

    constructor(public $state: StateService,
        public ipxNotificationService: IpxNotificationService) { }

    ngOnInit(): void {
        this.paramKey = this.paramKey || 'id';
        this.pageSize = this.pageSize || 200;

        if (this.ids) {
            this.processIds(this.ids);
        } else if (this.lastSearch) {
            this.lastSearch.getAllIds().then((ids) => { this.processIds(ids); });
        }
    }

    navigate = (id: any, validateUnsaved: Boolean = true) => {
        if (!this.validateUnsaved(id, validateUnsaved)) {
            return;
        }

        let index = this.findIndex(id, this.ids);
        this.routerParams = this.noParams ? {} : this.routerParams ? this.routerParams : {};
        this.routerParams[this.paramKey] = (id && id.key) ? id.key : id;
        if (index !== -1) {
            this.routerParams.id = this.ids[index].value;
        }

        if (index === -1) {
            if (!this.canFetchNext) { return; }

            /* If last page ==> Get starting index of the last page, e.g total 38, Page size 10, start fetch from 31
             If remainder = 0 ==> Navigation is backwards, Get starting index of the previous page.
             e.g total 38, Page size 10, Navigate to last, then keep clicking previous, when it gets to 30, Id will not be available, code will reach here and remainder will be 0 */
            const nextPageFirstIndex =
                (+id % this.pageSize === 0) ? (+id - this.pageSize + 1) :
                    (+id === +this.total) ? (Math.floor(this.total / this.pageSize) * this.pageSize) + 1 : id;
            this.fetchNext(nextPageFirstIndex)
                .then((ids) => {
                    this.ids = ids;
                    index = this.findIndex(id, this.ids);
                    if (index !== -1) {
                        this.routerParams.id = this.ids[index].value;
                    }
                    this.executeNavigation(id, index, nextPageFirstIndex);
                });
        } else {
            this.executeNavigation(id, index);
        }
    };

    validateUnsaved = (id, validateUnsaved): Boolean => {
        if (this.hasUnsavedChanges && validateUnsaved) {
            this.modalRef = this.ipxNotificationService.openDiscardModal();
            this.modalRef.content.confirmed$.subscribe(() => {
                this.navigate(id, false);
            });

            return false;
        }

        return true;
    };

    executeNavigation = (id: string, index: number, nextPageFirstIndex?: any): any => {
        if (this.noParams) {
            this.currentKey = id;
            this.processIds(this.ids);
            this.nextResult.emit(this.ids[index].value);

            return;
        }

        if (nextPageFirstIndex) {
            this.$state.go(this.routerState, this.routerParams, { reload: true });
        } else {
            this.$state.go(this.routerState ? this.routerState : '.', this.routerParams, { reload: true });
        }
    };

    processIds = (ids: any) => {
        const param = this.noParams ? this.currentKey : !this.refreshKey ? this.$state.params[this.paramKey] : this.refreshKey;
        const index = this.findIndex(param, ids);
        if (index === -1) {
            return;
        }
        const isObject = ids[0].key;
        if (!this.ids) {
            this.ids = ids;
        }
        this.manageNavigation(ids, index, param, isObject);

    };

    manageNavigation(ids: any, index: number, param: any, isObject?: any): void {
        this.current = (this.noParams && +this.currentKey > ids.length) ? +this.currentKey : (this.noParams ? index + 1 : isObject ? +param : index + 1);
        this.total = this.totalRows || ids.length;
        this.firstId = (isObject ? 1 : ids[0]).toString();
        this.prevId = (this.current === 1 ? undefined : (isObject ? (this.current - 1) : ids[index - 1]).toString());
        this.nextId = (this.current === this.total ? undefined : (isObject ? (this.current + 1) : ids[index + 1]).toString());
        this.lastId = (isObject ? this.total : ids[ids.length - 1]).toString();
        this.canFetchNext = this.current < this.total && ids.length < this.total;
        this.available = ids.length;
        this.visible = true;
        this.detailNavigate.emit({ currentPage: (isObject) ? (this.current - 1) : index });
    }

    findIndex = (id: any, ids: any) => {
        let index = -1;
        if (ids && ids.length > 0 && id) {
            if (ids[0].key) {
                index = _.findIndex(ids, {
                    key: id
                });
            } else {
                // tslint:disable-next-line:radix
                let intId = parseInt(id);
                if (isNaN(intId)) {
                    intId = id;
                }
                index = _.indexOf(ids, intId);
            }
        }

        return index;
    };

    isLastDisabled = (): boolean => {
        return this.lastId === this.current.toString();
    };

    isFirstDisabled = (): boolean => {
        return this.firstId === this.current.toString();
    };

    isPreviousDisabled = (): boolean => {
        return this.prevId == null;
    };

    isNextDisabled = (): boolean => {
        return !this.canFetchNext && this.nextId == null;
    };
}
