import { ChangeDetectionStrategy, Component, OnInit, TemplateRef, ViewChild, ViewContainerRef } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TypeAheadConfigProvider } from 'shared/component/typeahead/ipx-typeahead/typeahead.config.provider';
import * as _ from 'underscore';
import { queryContextKeyEnum } from './../../search/common/search-type-config.provider';

@Component({
    selector: 'ipx-typeahead-examples',
    templateUrl: './ipx-typeahead.dev.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxDevTypeaheadComponent implements OnInit {
    vm: any;
    formData1: any;
    formData2: any;
    picklistConfigs: any;
    selectedPicklistConfig: any;
    picklistSelection: any;
    @ViewChild('nextForm', { static: true }) readonly nextForm: NgForm;
    @ViewChild('testPicklist') testPicklist: TemplateRef<any>;
    @ViewChild('vc', { read: ViewContainerRef }) vc: ViewContainerRef;
    childViewRef: any;
    userColumnTypehead: any;
    searchColumnTypeahead: any;
    filePart: any;
    webPart: any;
    taskList: any;
    subjectList: any;
    docGenTemplate: any;
    adHocTemplate: any;
    docGenOptions = {
        case: null,
        name: null,
        isWord: true,
        isCase: true
    };
    constructor(private readonly typeAheadConfigProvider: TypeAheadConfigProvider) {
        this.vm = {
            searchCriteria: {
                jurisdictions: [],
                jurisdiction1: [],
                nameRelationships: [],
                wipTemplateCase: {},
                wipTemplate: {},
                designationStage: {},
                names: [],
                propertyType: [],
                numberType: [],
                images: [],
                instructionType: [],
                profitCentre: {},
                taskPlannerSavedSearch: {}
            },
            extendJurisdictionQuery: this.extendQuery.bind(this),
            extendWipTemplatePicklist: this.extendWipTemplateQuery.bind(this),
            designationStageExtendQuery: this.extendDesignationStageQuery.bind(this),
            designationStageExternalScope: this.designationStageExternalScope.bind(this),
            columnGroupExtendQuery: this.extendColumnGroupQuery.bind(this),
            filePartExtendQuery: this.filePartExtendQuery.bind(this),
            taskExtendQuery: this.taskExtendQuery.bind(this),
            filePartExternalScopeData: this.filePartExternalScope(),
            docGenTemplatesExtendedQuery: this.docGenTemplatesExtendedQuery.bind(this)
        };

        this.picklistConfigs = _.map(_.zip(Object.keys(this.typeAheadConfigProvider.globalOptions),
            _.map(this.typeAheadConfigProvider.globalOptions, (item) => {
                const resolved = this.typeAheadConfigProvider.resolve({
                    config: item
                });

                return {
                    config: item,
                    label: resolved.label
                };
            })
        ), (config) => {
            const newConfig = config[1].config;
            newConfig.configKey = config[0];

            return newConfig;
        });
    }

    ngOnInit(): void {
        this.vm.searchCriteria.jurisdictions = [{ key: 'FM', code: 'FM', value: 'Micronesia (Federated States of)', isGroup: false },
        { key: 'MM', code: 'MM', value: 'Micronesia', isGroup: false }];
        this.vm.searchCriteria.jurisdictions2 = [{ key: 'FM', code: 'FM', value: 'Micronesia (Federated States of)', isGroup: false },
        { key: 'MM', code: 'MM', value: 'Micronesia', isGroup: false }];
        this.vm.searchCriteria.nameRelationships = {};
    }

    filePartExtendQuery(query): any {
        const extended = _.extend({}, query, {
            CaseId: -487
        });

        return extended;
    }

    taskExtendQuery(query): any {
        const extended = _.extend({}, query, {
            roleKey: -22
        });

        return extended;
    }

    filePartExternalScope(): any {
        return {
            value: '1234/A', label: 'Case Reference.'
        };
    }

    filePartextendedParam(query: any): any {
        return {
            ...query,
            caseId: -487
        };
    }

    docGenTemplatesExtendedQuery(query: any): any {

        const extended = _.extend({}, query, {
            options: JSON.stringify({
                InproDocOnly: this.docGenOptions.isWord,
                pdfOnly: !this.docGenOptions.isWord,
                caseKey: this.docGenOptions.case && this.docGenOptions.isCase ? this.docGenOptions.case.key : null,
                NameKey: this.docGenOptions.name && !this.docGenOptions.isCase ? this.docGenOptions.name.key : null
            })
        });

        return extended;
    }

    extendQuery(query): any {
        const extended = _.extend({}, query, {
            isGroup: true,
            excludeCountry: 'OA',
            latency: 888
        });
        this.vm.extendJurisdictionQuery.outgoingcall = extended;

        return extended;
    }

    extendWipTemplateQuery(query): any {
        const extended = _.extend({}, query, {
            caseId: !!this.vm.wipTemplateCase ? this.vm.wipTemplateCase.key : ''
        });

        return extended;
    }

    extendDesignationStageQuery(query): any {
        const extended = _.extend({}, query, {
            jurisdictionId: 'PCT',
            latency: 888
        });
        this.vm.designationStageExtendQuery.outgoingcall = extended;

        return extended;
    }

    designationStageExternalScope(): any {
        return {
            jurisdiction: 'Patent Cooperation Treaty'
        };
    }

    extendColumnGroupQuery(query): any {
        const extended = _.extend({}, query, {
            queryContext: queryContextKeyEnum.caseSearch,
            latency: 888
        });
        this.vm.columnGroupExtendQuery.outgoingcall = extended;

        return extended;
    }

    extendedParamGroupPicklist = (query: any): any => {
        return {
            ...query,
            contextId: queryContextKeyEnum.caseSearch
        };
    };

    byConfigKey = (index: number, item: any): string => item.configKey;
}