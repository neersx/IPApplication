module inprotech.portfolio.cases {
    'use strict';
    export interface CommonCaseViewData {
        importanceLevel: number,
        importanceLevelOptions: any[],
        requireImportanceLevel: boolean,
        eventNoteTypes: any[]
    }

    export interface FileAvailability {
        isEnabled: boolean,
        canView: boolean,
        canInstruct: boolean
    }

    export interface IppAvailability {
        file: FileAvailability
    }

    export interface ICaseViewService {
        getOverview(id: any, rowKey: Number): any;
        caseViewData(): any;
        getPropertyTypeIcon(imageKey): any;
        getScreenControl(criteriaKey, programId?): any;
        getIppAvailability(caseKey): ng.IPromise<IppAvailability>;
        getCaseSupportUri(caseKey: Number): ng.IPromise<any>;
        getImportanceLevelAndEventNoteTypes(): ng.IPromise<CommonCaseViewData>;
        getCaseWebLinks(caseKey): any;
    }

    export class CaseViewService implements ICaseViewService {
        static $inject: string[] = ['$http', 'CaseSharedService'];
        constructor(private $http: angular.IHttpService, private sharedService: ICaseSharedService) { }

        getOverview(id: any, rowKey: Number, ) {
            let caseKey = this.sharedService.getCaseKeyFromRowKey(rowKey);
            return this.$http.get('api/case/' + encodeURI((caseKey) ? caseKey.toString() : id) + '/overview')
                .then(response => response.data);
        }

        caseViewData() {
            return this.$http.get('api/case/caseview')
                .then(response => response.data);
        }

        getPropertyTypeIcon(imageKey: Number) {
            return this.$http.get('api/shared/image/' + encodeURI(imageKey.toString()) + '/20/20',
                { cache: true })
                .then(response => response.data);
        }

        getScreenControl(caseKey: Number, programId?: string) {
            return this.$http.get('api/case/screencontrol/' + encodeURI(caseKey.toString()) + '/' + encodeURI(programId || ''))
                .then(response => response.data);
        }

        getIppAvailability(caseKey: Number) {
            return this.$http.get('api/case/' + encodeURI(caseKey.toString()) + '/ipp-availability')
                .then((response: any) => {
                    return <IppAvailability>response.data;
                });
        }

        getCaseSupportUri(caseKey: Number) {
            return this.$http.get('api/case/' + encodeURI(caseKey.toString()) + '/support-email')
                .then(response => response.data);
        }

        getImportanceLevelAndEventNoteTypes() {
            return this.$http.get('api/case/importance-levels-note-types', {
                cache: true
            })
                .then((response: any) => {
                    return {
                        importanceLevel: response.data.importanceLevel,
                        importanceLevelOptions: response.data.importanceLevelOptions,
                        requireImportanceLevel: response.data.requireImportanceLevel,
                        eventNoteTypes: response.data.eventNoteTypes
                    }
                });
        }

        getCaseWebLinks(caseKey: Number) {
            return this.$http.get('api/case/' + encodeURI(caseKey.toString()) + '/weblinks')
                .then(response => response.data);
        }
    }

    angular.module('inprotech.portfolio.cases')
        .service('CaseViewService', CaseViewService);
}
