import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, FormGroup, NgForm, Validators } from '@angular/forms';
import { StateService } from '@uirouter/angular';
import { ReplaySubject } from 'rxjs';
import { take } from 'rxjs/operators';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { PriorArtShortcuts } from '../helpers/prior-art-shortcuts';
import { LiteratureSearchResultComponent } from '../literature-search-result/literature-search-result.component';
import { IpoSearchType, PriorArtType } from '../priorart-model';
import { PriorArtService } from '../priorart.service';
import { PriorartSearchResultComponent } from '../search-result/priorart-search-result.component';
import { IpoSearch, PriorArtSearch, PriorArtSearchResult, PriorArtSearchType } from './priorart-search-model';

@Component({
    selector: 'ipx-priorart-search',
    templateUrl: './priorart-search.html',
    styleUrls: ['./priorart-search.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush,
    animations: [
        slideInOutVisible
    ]
})
export class PriorArtSearchComponent implements OnInit, OnDestroy {
    @Input() translationsList: any = {};
    @Input() priorArtSourceTableCodes: any;
    @Input() isIpDocument: boolean;
    @Input() isSourceDocument: boolean;
    caseKey: number;
    sourceId: number;
    inprotechData: Array<PriorArtSearchResult>;
    ipOneData: Array<PriorArtSearchResult>;
    combinedData: Array<PriorArtSearchResult>;
    caseReferenceData: Array<PriorArtSearchResult>;
    notFoundData: Array<PriorArtSearchResult>;
    hasIpd1Error = false;
    isLoaded = false;
    isDataLoaded?: boolean;
    showNotFoundGrid = false;
    request: PriorArtSearch;
    destroy: ReplaySubject<any> = new ReplaySubject<any>(1);
    formGroup: FormGroup;
    selectedIpoSearchType: IpoSearchType;
    get PriorArtTypeEnum(): typeof PriorArtType {
        return PriorArtType;
    }
    get IpoSearchTypeEnum(): typeof IpoSearchType {
        return IpoSearchType;
    }
    get selectedPriorArtType(): PriorArtType {
        return this.formGroup && this.formGroup.value.selectedPriorArtType;
    }
    @ViewChild('priorartSearchResult', { static: false }) priorartSearchResult: PriorartSearchResultComponent;
    @ViewChild('literatureSearchResult', { static: false }) literatureSearchResult: LiteratureSearchResultComponent;

    showSearchBar = true;
    @ViewChild('searchForm', { static: true }) ngForm: NgForm;

    constructor(private readonly service: PriorArtService,
        private readonly cdr: ChangeDetectorRef,
        private readonly stateService: StateService,
        private readonly notificationService: IpxNotificationService,
        private readonly priorArtShortcuts: PriorArtShortcuts,
        private readonly formBuilder: FormBuilder) {
    }

    ngOnInit(): void {
        this.registerHotkeysForSave();
        this.registerHotkeysForReset();
        this.registerHotkeysForSearch();
        this.sourceId = this.stateService.params.sourceId;
        this.caseKey = this.stateService.params.caseKey;
        this.service.hasPendingChanges$.next(false);
        this.formGroup = this.formBuilder.group({
            selectedPriorArtType: new FormControl((this.sourceId && !this.isSourceDocument) ? PriorArtType.Source : PriorArtType.Ipo),
            jurisdiction: new FormControl(),
            applicationNo: new FormControl(),
            kindCode: new FormControl(),
            description: new FormControl(),
            sourceType: new FormControl(),
            publication: new FormControl(),
            comments: new FormControl(),
            inventor: new FormControl(),
            publisher: new FormControl(),
            title: new FormControl(),
            multipleIpoText: new FormControl()
        });
        this.setSelectedIpoSearch(IpoSearchType.Single);
    }

    ngOnDestroy(): void {
        this.priorArtShortcuts.flushShortcuts();
        this.destroy.next(null);
        this.destroy.complete();
    }

    registerHotkeysForSave = (): void => {
        this.priorArtShortcuts.registerHotkeysForSave();
    };

    registerHotkeysForReset = (): void => {
        this.priorArtShortcuts.registerHotkeysForRevert();
    };

    registerHotkeysForSearch = (): void => {
        this.priorArtShortcuts.registerHotkeysForSearch();
    };

    clear(successfulCallback: () => void = null): void {
        const clearSearch = () => {
            this.service.hasPendingChanges$.next(false);
            const selectedPriorArtType = this.selectedPriorArtType;
            this.formGroup.reset({ selectedPriorArtType });
            this.inprotechData = [];
            this.ipOneData = [];
            this.combinedData = [];
            this.caseReferenceData = [];
            this.isLoaded = false;
            this.isDataLoaded = null;
            this.formGroup.markAsPristine();
            if (successfulCallback) {
                successfulCallback();
            }
            this.cdr.detectChanges();
        };
        if (this.service.hasPendingChanges$.value) {
            const modal = this.notificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    clearSearch();
                });
        } else {
            clearSearch();
        }
    }

    search(): void {
        if (this.selectedPriorArtType === PriorArtType.Ipo && this.selectedIpoSearchType === IpoSearchType.Multiple && !this.validateIpoSearchItems()) {
            return null;
        }
        const doSearch = () => {
            this.service.hasPendingChanges$.next(false);
            if (this.selectedIpoSearchType === IpoSearchType.Single && !this.formGroup.valid) {
                return;
            }

            this.isLoaded = false;
            this.isDataLoaded = false;
            this.showNotFoundGrid = false;
            this.hasIpd1Error = false;
            this.cdr.detectChanges();
            this.request = {
                caseKey: this.caseKey,
                sourceDocumentId: this.sourceId,
                country: this.formGroup.value.jurisdiction ? this.formGroup.value.jurisdiction.code : null,
                countryName: this.formGroup.value.jurisdiction ? this.formGroup.value.jurisdiction.value : null,
                officialNumber: this.formGroup.value.applicationNo ? this.formGroup.value.applicationNo.trim() : '',
                kind: this.formGroup.value.kindCode ? this.formGroup.value.kindCode.trim() : '',
                description: this.formGroup.value.description ? this.formGroup.value.description.trim() : '',
                sourceId: this.formGroup.value.sourceType ? this.formGroup.value.sourceType.id : null,
                publication: this.formGroup.value.publication ? this.formGroup.value.publication.trim() : '',
                comments: this.formGroup.value.comments ? this.formGroup.value.comments.trim() : '',
                inventor: this.formGroup.value.inventor ? this.formGroup.value.inventor.trim() : '',
                title: this.formGroup.value.title ? this.formGroup.value.title.trim() : '',
                publisher: this.formGroup.value.publisher ? this.formGroup.value.publisher.trim() : '',
                sourceType: this.formGroup.value.selectedPriorArtType,
                ipoSearchType: this.selectedIpoSearchType,
                multipleIpoSearch: this.selectedIpoSearchType === IpoSearchType.Multiple ? this.parseMultiSearchText(this.formGroup.controls.multipleIpoText.value) : null
            };
            this.getGridData(null);
        };
        if (this.service.hasPendingChanges$.value) {
            const modal = this.notificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    doSearch();
                });
        } else {
            doSearch();
        }
    }

    onRefresh(event: any): void {
        if (event.success) {
            if (!!this.priorartSearchResult) {
                this.priorartSearchResult.expandFirstRowOnRefresh = true;
            }
            if (!!this.literatureSearchResult) {
                this.literatureSearchResult.expandFirstRowOnRefresh = true;
                this.literatureSearchResult.grid.search();
            }
            this.getGridData(event.importedRef);
        }
    }

    getGridData(importedRef: any): void {
        this.service
            .getSearchedData$(this.request)
            .subscribe(data => {
                const inprotechDataSet = _.find(data.result, (t: any) => {
                    return t.source === PriorArtSearchType.ExistingPriorArtFinder;
                });
                this.inprotechData = inprotechDataSet !== undefined ? inprotechDataSet.matches.data : null;
                const ipOneDataSet = _.find(data.result, (t: any) => {
                    return t.source === PriorArtSearchType.IpOneDataDocumentFinder;
                });
                this.ipOneData = ipOneDataSet !== undefined ? ipOneDataSet.matches.data : null;
                if (ipOneDataSet.errors && ipOneDataSet.matches.data.length === 0) {
                    this.hasIpd1Error = true;
                }
                this.combinedData = [...this.inprotechData, ...this.ipOneData];
                _.each(this.combinedData, (dataitem: any) => {
                    dataitem.applicationDate = !!dataitem.applicationDate ? new Date(dataitem.applicationDate) : null;
                    dataitem.publishedDate = !!dataitem.publishedDate ? new Date(dataitem.publishedDate) : null;
                    dataitem.publishedDate = !!dataitem.published ? new Date(dataitem.published) : null;
                    dataitem.grantedDate = !!dataitem.grantedDate ? new Date(dataitem.grantedDate) : null;
                    dataitem.priorityDate = !!dataitem.priorityDate ? new Date(dataitem.priorityDate) : null;
                    dataitem.ptoCitedDate = !!dataitem.ptoCitedDate ? new Date(dataitem.ptoCitedDate) : null;
                    if (!!importedRef && dataitem.reference === importedRef) {
                        dataitem.imported = true;
                    }
                });

                const caseReferenceDataSet = _.find(data.result, (t: any) => {
                    return t.source === PriorArtSearchType.CaseEvidenceFinder;
                });
                this.caseReferenceData = caseReferenceDataSet !== undefined ? caseReferenceDataSet.matches.data : null;
                this.notFoundData = this.request.ipoSearchType === IpoSearchType.Single ? this.priorArtNotFound(this.request) : this.priorArtNotFoundMultiple(this.request);
                this.isDataLoaded = true;
                this.isLoaded = true;
                this.cdr.detectChanges();
            });
    }

    priorArtNotFound(request: PriorArtSearch): Array<PriorArtSearchResult> {
        const searchRequestsThatWereNotFound = new Array<PriorArtSearchResult>();
        const allResults = [...this.combinedData, ...this.caseReferenceData];
        if (_.any(allResults)) {
            return searchRequestsThatWereNotFound;
        }

        const result = new PriorArtSearchResult();
        this.showNotFoundGrid = true;
        result.countryName = request.countryName;
        result.officialNumber = request.officialNumber;
        result.country = request.country;
        result.kind = request.kind;
        result.reference = request.officialNumber;
        result.caseKey = this.caseKey;
        result.sourceId = this.sourceId;
        searchRequestsThatWereNotFound.push(result);

        return searchRequestsThatWereNotFound;
    }

    priorArtNotFoundMultiple(request: PriorArtSearch): Array<PriorArtSearchResult> {
        const searchRequestsThatWereNotFound = new Array<PriorArtSearchResult>();
        const allResults = [...this.combinedData, ...this.caseReferenceData];
        request.multipleIpoSearch.forEach(searchRequest => {
            const hit = _.any(allResults, (v) => {
                if (!!searchRequest.kind) {
                    return searchRequest.country === v.countryCode && v.reference.includes(searchRequest.officialNumber) && searchRequest.kind === v.kind;
                }

                return searchRequest.country === v.countryCode && v.reference.includes(searchRequest.officialNumber);
            });
            if (!hit) {
                const result = new PriorArtSearchResult();
                this.showNotFoundGrid = true;
                result.countryName = searchRequest.country;
                result.officialNumber = searchRequest.officialNumber;
                result.country = searchRequest.country;
                result.kind = searchRequest.kind;
                result.reference = searchRequest.officialNumber;
                result.caseKey = this.caseKey;
                result.sourceId = this.sourceId;
                searchRequestsThatWereNotFound.push(result);
            }
        });

        return searchRequestsThatWereNotFound;
    }

    toggleSourceType(sourceType: PriorArtType): void {
        if (this.formGroup.controls.selectedPriorArtType.value === sourceType) {

            return;
        }
        this.clear(() => {
            this.formGroup.controls.selectedPriorArtType.setValue(sourceType);

            if (this.formGroup.value.selectedPriorArtType === PriorArtType.Ipo) {
                this.formGroup.controls.applicationNo.setValidators(Validators.required);
                this.formGroup.controls.jurisdiction.setValidators(Validators.required);
            } else {
                this.formGroup.controls.applicationNo.clearValidators();
                this.formGroup.controls.jurisdiction.clearValidators();
            }
            this.formGroup.controls.jurisdiction.updateValueAndValidity();
            this.formGroup.controls.applicationNo.updateValueAndValidity();
            this.formGroup.updateValueAndValidity();
        });
    }

    disableSearch(): boolean {
        if (this.selectedPriorArtType === PriorArtType.Ipo) {
            if (this.selectedIpoSearchType === IpoSearchType.Single && !this.formGroup.controls.applicationNo.invalid && !this.formGroup.controls.jurisdiction.invalid) {
                return false;
            }

            if (this.selectedIpoSearchType === IpoSearchType.Multiple && !!this.formGroup.controls.multipleIpoText.value && this.validateIpoSearchItems()) {
                return false;
            }

            return true;
        }

        return false;
    }

    setSelectedIpoSearch(type: IpoSearchType): void {
        this.selectedIpoSearchType = type;
        this.cdr.detectChanges();
    }

    _normalise(input: string): Array<string> {
        if (!input) {

            return null;
        }
        const regex = /([A-Za-z]{2,4})[ \/\-]{1}([A-Za-z0-9]+)([ \/\-]?(?=[A-Za-z])([A-Za-z]?[0-9]?))?[\r\n]?/g;

        return input.match(regex);
    }

    _clean(input: string): string {
        const regex = /[\W]+/g;

        return input.replace(regex, '');
    }

    parseMultiSearchText(input: string): Array<IpoSearch> {
        const tokens = this._normalise(input);
        const searchItems = new Array<IpoSearch>();
        _.each(tokens, (v: string) => {
            const regex = /([A-Za-z]{2,4})[ \/\-]{1}([A-Za-z0-9]+)([ \/\-]?((?=[A-Za-z])([A-Za-z]?[0-9]?)))?/;
            const q = v.match(regex);
            const searchItem = new IpoSearch();
            if (!!q[1] && !!q[2]) {
                const referenceExists = _.findIndex(searchItems, (r: IpoSearch) => {
                    const l = r.country === q[1].trim().toUpperCase()
                    && r.officialNumber === this._clean(q[2]).trim().toUpperCase()
                    && r.kind === (!!q[4] ? q[4].trim().toUpperCase() : null);

                    return l;
                });

                if (referenceExists === -1) {
                    searchItem.country = q[1].trim().toUpperCase();
                    searchItem.officialNumber = this._clean(q[2]).trim().toUpperCase();
                    searchItem.kind = !!q[4] ? q[4].trim().toUpperCase() : null;
                    searchItems.push(searchItem);
                }
            }
        });

        return searchItems;
    }

    validateIpoSearchItems(): boolean {
        const query = this.formGroup.controls.multipleIpoText.value;
        const tokens = this.parseMultiSearchText(query);
        if (tokens.length < 1 && query.length > 0) {
            this.formGroup.controls.multipleIpoText.setErrors({ 'priorArt.invalidMultiSearch': true });

            return false;
        }

        this.formGroup.controls.multipleIpoText.setErrors(null);

        return true;
    }

    multiTextEnter(event: any): void {
        if (!this.validateIpoSearchItems()) {
            event.preventDefault();
        }
    }
}