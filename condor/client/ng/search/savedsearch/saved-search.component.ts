import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { StateService } from '@uirouter/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { Hotkey } from 'angular2-hotkeys';
import { KeyBoardShortCutService } from 'core/keyboardshortcut.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { PresentationColumnView, SelectedColumn } from 'search/presentation/search-presentation.model';
import { SearchPresentationPersistenceService } from 'search/presentation/search-presentation.persistence.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { queryContextKeyEnum, SearchTypeConfigProvider } from '../common/search-type-config.provider';
import { SaveOperationType, SaveSearchData, SaveSearchEntity } from './saved-search.model';
import { SavedSearchService } from './saved-search.service';

@Component({
    selector: 'saved-search',
    templateUrl: './saved-search.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class SavedSearchComponent implements OnInit {
    formData: SaveSearchData;

    @ViewChild('form', { static: true }) ngForm: NgForm;

    selectedColumns = Array<PresentationColumnView>();
    updatePresentation: Boolean;
    filter: any;
    canMaintainPublicSearch: Boolean;
    queryContextKey: Number;
    queryKey?: Number;
    type: SaveOperationType;
    modalRef: BsModalRef;
    isCaseSearchSave = true;
    constructor(
        private readonly bsModalRef: BsModalRef,
        private readonly notificationService: NotificationService,
        private readonly saveSearchSerivce: SavedSearchService,
        private readonly stateService: StateService,
        private readonly keyBoardShortCutService: KeyBoardShortCutService,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly cdRef: ChangeDetectorRef,
        private readonly searchPresentationPersistenceService: SearchPresentationPersistenceService) {
        this.formData = {};
        this.initShortcuts();
    }

    ngOnInit(): void {
        this.isCaseSearchSave = (queryContextKeyEnum.taskPlannerSearch === this.queryContextKey) ? false : true;
        SearchTypeConfigProvider.getConfigurationConstants(this.queryContextKey);
        if (this.type === SaveOperationType.EditDetails || this.type === SaveOperationType.SaveAs) {
            this.saveSearchSerivce.getDetails$(this.queryKey, SearchTypeConfigProvider.savedConfig).subscribe((response: any) => {
                this.setFormData(response, this.type);
            });
        }
    }

    initShortcuts = () => {
        const hotkeys = [
            new Hotkey(
                'alt+shift+s',
                (event, combo): boolean => {
                    this.saveSearch();

                    return true;
                }, null, 'shortcuts.saveSearch', undefined, false)
        ];
        this.keyBoardShortCutService.add(hotkeys);
    };

    close = (): void => {
        if (this.ngForm.dirty) {
            this.modalRef = this.ipxNotificationService.openDiscardModal();
            this.modalRef.content.confirmed$.subscribe(() => {
                this.bsModalRef.hide();
            });
        } else {
            this.bsModalRef.hide();
        }
    };

    disable = (): boolean => {
        return !(this.ngForm.dirty && this.ngForm.valid);
    };

    extendSearchGroupPicklist = (query: any): any => {
        return {
            ...query,
            queryContext: this.queryContextKey
        };
    };

    extendedParamGroupPicklist = (query: any): any => {
        return {
            ...query,
            contextId: this.queryContextKey
        };
    };

    setFormData = (response: any, saveOperationType: SaveOperationType): void => {
        this.formData.searchName = saveOperationType === SaveOperationType.EditDetails ? response.searchName : '';
        this.formData.description = response.description;
        this.formData.includeInSearchMenu = {};
        this.formData.includeInSearchMenu.key = response.groupKey;
        this.formData.includeInSearchMenu.value = response.groupName;
        this.formData.public = saveOperationType === SaveOperationType.EditDetails ? response.isPublic : false;

        this.ngForm.form.markAsPristine();
        this.cdRef.markForCheck();
    };

    saveSearchEntity = (): SaveSearchEntity => {
        const saveSearchEntity: SaveSearchEntity = {
            id: this.queryKey,
            queryContext: this.queryContextKey,
            searchName: this.formData.searchName,
            description: this.formData.description,
            groupKey: this.formData.includeInSearchMenu ? this.formData.includeInSearchMenu.key : null,
            isPublic: this.formData.public,
            searchFilter: this.filter,
            updatePresentation: this.updatePresentation,
            selectedColumns: this.selectedColumns
        };

        return saveSearchEntity;
    };

    saveSearch = (): void => {
        if (this.ngForm.invalid) {
            return;
        }

        this.saveSearchSerivce.saveSearch(this.saveSearchEntity(), this.type, this.queryKey, SearchTypeConfigProvider.savedConfig).subscribe(res => {
            if (res.success) {
                this.bsModalRef.hide();
                this.searchPresentationPersistenceService.clear();
                const stateName = queryContextKeyEnum.taskPlannerSearch === this.queryContextKey ? 'taskPlannerSearchBuilder' : 'casesearch';
                this.stateService.go(stateName, {
                    queryKey: this.type === SaveOperationType.EditDetails ? this.queryKey : res.queryKey,
                    canEdit: true,
                    searchName: this.saveSearchEntity().searchName,
                    returnFromCaseSearchResults: false
                }, { reload: true });
                this.notificationService.success('saveMessage');
            } else {
                this.ngForm.controls.searchName.setErrors({ notunique: true });
            }
        });
    };
}
