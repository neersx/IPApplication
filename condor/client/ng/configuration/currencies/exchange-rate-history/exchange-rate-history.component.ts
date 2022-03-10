
import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { LocalSettings } from 'core/local-settings';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Observable } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import { CurrenciesService } from '../currencies.service';

@Component({
    selector: 'currencies',
    templateUrl: './exchange-rate-history.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class ExchangeRateHistoryComponent implements OnInit {

    @Input() currencyId: string;
    currencyDesc: Observable<string>;
    gridOptions: IpxGridOptions;
    canNavigate: Boolean;
    navData: {
        keys: Array<any>,
        totalRows: number,
        pageSize: number,
        fetchCallback(currentIndex: number): any
    };
    currentKey: number;

    constructor(private readonly service: CurrenciesService,
        private readonly sbsModalRef: BsModalRef,
        readonly localSettings: LocalSettings,
        private readonly gridNavService: GridNavigationService,
        private readonly destroy$: IpxDestroy,
        private readonly shortcutsService: IpxShortcutsService) {
    }

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
        this.currencyDesc = this.service.getCurrencyDesc(this.currencyId);
        this.canNavigate = true;
        this.navData = {
            ...this.gridNavService.getNavigationData(),
            fetchCallback: (currentIndex: number): any => {
                return this.gridNavService.fetchNext$(currentIndex).toPromise();
            }
        };
        this.currentKey = this.navData.keys.filter(k => k.value === this.currencyId)[0].key;
        this.handleShortcuts();
    }

    handleShortcuts(): void {
        const shortcutCallbacksMap = new Map(
            [[RegisterableShortcuts.REVERT, (): void => { this.cancel(); }]]);
        this.shortcutsService.observeMultiple$([RegisterableShortcuts.REVERT])
            .pipe(takeUntil(this.destroy$))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && shortcutCallbacksMap.has(key)) {
                    shortcutCallbacksMap.get(key)();
                }
            });
    }

    cancel = (): void => {
        this.sbsModalRef.hide();
    };

    getNextItemDetail = (next: string) => {
        this.currencyId = next;
        this.currencyDesc = this.service.getCurrencyDesc(this.currencyId);
        this.gridOptions._search();
    };

    buildGridOptions(): IpxGridOptions {

        return {
            autobind: true,
            navigable: true,
            sortable: true,
            reorderable: false,
            pageable: {
                pageSizes: [5, 10, 20, 50],
                pageSizeSetting: this.localSettings.keys.exchangeRateHistory.pageSize
            },
            read$: (queryParams) => {

                return this.service.getHistory(this.currencyId, queryParams);
            },
            columns: this.getColumns()
        };
    }

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: 'currencies.history.columns.effectiveDate',
            field: 'effectiveDate',
            template: true
        }, {
            title: 'currencies.history.columns.bankRate',
            field: 'bankRate',
            sortable: true,
            template: true
        }, {
            title: 'currencies.history.columns.buyFactor',
            field: 'buyFactor',
            sortable: true,
            template: true
        }, {
            title: 'currencies.history.columns.buyRate',
            field: 'buyRate',
            sortable: true,
            template: true
        }, {
            title: 'currencies.history.columns.sellFactor',
            field: 'sellFactor',
            sortable: true,
            template: true
        }, {
            title: 'currencies.history.columns.sellRate',
            field: 'sellRate',
            sortable: true,
            template: true
        }];

        return columns;
    };
}