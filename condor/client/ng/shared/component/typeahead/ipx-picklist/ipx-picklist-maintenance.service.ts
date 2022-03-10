import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { MaintenanceMetaData } from 'shared/component/grid/ipx-grid.models';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { CommonSearchParams, GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import * as _ from 'underscore';
import { TypeaheadConfig } from './../ipx-typeahead/typeahead.config.provider';

@Injectable()
export class IpxPicklistMaintenanceService {
    modalStates$: BehaviorSubject<any>;
    maintenanceMetaData$: BehaviorSubject<MaintenanceMetaData>;
    maintenanceMode$: BehaviorSubject<string>;
    navigationOptions: any;

    constructor(private readonly http: HttpClient, public notificationService: IpxNotificationService,
        readonly translate: TranslateService, private readonly gridNavigationService: GridNavigationService) {
        this.init();
    }

    private readonly searchMethod = (lastSearch: CommonSearchParams): Observable<any> => {
        const q: any = {
            criteria: lastSearch.criteria,
            params: lastSearch.params
        };

        return this.getItems$(this.navigationOptions.apiUrl, q.criteria, q.params, true);
    };

    initNavigationOptions = (apiUrl, keyField) => {
        this.navigationOptions = {
            apiUrl,
            keyField
        };
        this.gridNavigationService.init(this.searchMethod, this.navigationOptions.keyField);
    };

    nextModalState = (value: any): void => {
        this.modalStates$.next(value);
    };

    nextMaintenanceMetaData = (value: MaintenanceMetaData) => {
        this.maintenanceMetaData$.next(value);
    };

    nextMaintenanceMode = (value: string) => {
        this.maintenanceMode$.next(value);
    };

    getItem$(typeaheadOptions: TypeaheadConfig, model: any): Observable<any> {
        let apiUri = typeaheadOptions.apiUrl;
        apiUri = apiUri + '/' + model.key;

        if (typeaheadOptions.fetchItemUri) {
            apiUri = apiUri + '/' + typeaheadOptions.fetchItemUri;
            apiUri = apiUri.replace('{0}', model[typeaheadOptions.fetchItemParam]);
        }

        return this.http.get(apiUri).pipe(map((response: any) => {
            return response.data;
        }));
    }

    addOrUpdate$(uri: string, model: any, successCallback?: any, errorCallback?: any): any {
        if (!model) {
            throw new Error('Empty Data');
        } else if (model && !model.value) {
            throw new Error('Empty Value');
        }

        this.addOrUpdateAction(uri, model).subscribe((response: { result?: string, errors?: Array<any> }) => {
            let message = '';
            let errorModel = [];
            if (response && response.errors) {
                response.errors.forEach((err) => {
                    if (err.message === 'field.errors.notunique') {
                        message += this.translate.instant('modal.alert.notUnique').replace('{value}', model[err.field]) + '\n';
                        errorModel = [...errorModel, { field: err.field, error: 'notunique' }];
                    } else if (err.displayMessage) {
                        // TODO InlineGrid Mode
                        message += this.translate.instant(err.message) + '\n';
                        errorModel = [...errorModel, { field: err.field, error: err.customValidationMessage || err.field }];
                    } else if (err.message != null) {
                        message = '';
                    }
                });

                if (errorCallback) {
                    errorCallback(errorModel);
                }

                this.notificationService.openAlertModal('', message, response.errors.filter((e) => e.field == null).map((e) => e.message));
            } else if (response && response.result === 'success' && successCallback) {
                successCallback(response);
            } else if (response && response.result === 'confirmation' && successCallback) {
                successCallback();
            }
        });
    }

    delete$(uri: string, key: string, params: any, successCallback?: any, cancelCallBack?: any): any {

        const notificationRef = this.notificationService.openDeleteConfirmModal('picklistmodal.confirm.delete');
        if (!notificationRef) {
            throw new Error('Modal template is not found');
        }

        notificationRef.content.confirmed$.pipe(
            take(1))
            .subscribe((event) => {
                return this.http.delete(uri + '/' + key).subscribe((response: { result?: string, errors?: Array<any> }) => {
                    if (response && response.errors) {
                        this.notificationService.openAlertModal('', '', response.errors.map((e) => e.message));
                    } else if (response && response.result === 'success' && successCallback) {
                        successCallback();
                    }
                    // TODO handling confirmation senario
                    // else if (value && value.result === 'confirm') {

                    // }
                });
            });

        if (cancelCallBack) {
            notificationRef.content.cancelled$.pipe(
                take(1))
                .subscribe((event) => {
                    cancelCallBack();
                });
        }
    }

    getItems$(uri: string, criteria: any, queryParams: any, canNavigate: Boolean): Observable<any> {
        let parameters: any = {
            params: JSON.stringify(queryParams)
        };

        parameters = _.extend(parameters, criteria);

        const result = this.http.get(uri, { params: parameters }
        ).pipe(map(data => this.setMaintenance(data as unknown as MaintenanceMetaData)));

        if (!canNavigate) {
            return result;
        }

        return result.pipe(this.gridNavigationService.setNavigationData(criteria, queryParams));
    }

    discard$(successCallback: any): any {
        const notificationRef = this.notificationService.openDiscardModal();
        if (!notificationRef) {
            throw new Error('Modal template is not found');
        }
        notificationRef.content.confirmed$.subscribe(() => {
            successCallback();
        });
    }
    private readonly addOrUpdateAction = (uri: string, model: any): Observable<any> => {
        if (model.key == null) {
            delete model.key;

            return this.http.post(uri, model);
        }

        return this.http.put(uri + '/' + model.key, model);
    };
    private readonly setMaintenance = (data: MaintenanceMetaData): any => {
        if (data && data.maintainability) {
            this.nextModalState({
                isMaintenanceMode: false,
                canAdd: data.maintainability.canAdd && data.maintainabilityActions.allowAdd,
                canSave: false
            });
            this.nextMaintenanceMetaData(data);
        }

        return data;
    };

    private readonly init = (): void => {
        this.modalStates$ = new BehaviorSubject({
            isMaintenanceMode: false,
            canAdd: false,
            canSave: false
        });

        // tslint:disable-next-line: no-object-literal-type-assertion
        this.maintenanceMetaData$ = new BehaviorSubject({
            maintainability: {
                canAdd: false,
                canDelete: false,
                canEdit: false
            },
            maintainabilityActions: {
                allowAdd: false,
                allowDelete: false,
                allowDuplicate: false,
                allowEdit: false,
                allowView: false,
                action: ''
            }
        } as MaintenanceMetaData);
        this.maintenanceMode$ = new BehaviorSubject('');
    };
}
