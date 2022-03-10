// tslint:disable:max-file-line-count
import { Injectable } from '@angular/core';
import { LocalSetting, LocalSettings } from 'core/local-settings';
import { DefaultColumnTemplateType, GridColumnDefinition, PageSettings } from 'shared/component/grid/ipx-grid.models';
import * as _ from 'underscore';
import { PicklistTemplateType, TemplateType, TypeaheadFieldType } from '../ipx-autocomplete/autocomplete/template.type';
@Injectable()
export class TypeAheadConfigProvider {
    globalOptions = {};
    attrKeys = [
        'label',
        'placeholder',
        'keyField',
        'codeField',
        'textField',
        'tagField',
        'maxResults',
        'apiUrl',
        'templateType',
        'picklistTemplateUrl',
        'picklistDisplayName',
        'picklistCanMaintain',
        'picklistColumns',
        'size',
        'columnMenu',
        'initFunction',
        'preSearch',
        'showDisplayField',
        'fieldType'
    ];

    constructor(private readonly localSettings: LocalSettings) {
    }

    defaultOptions: TypeaheadConfig = {
        keyField: 'id',
        codeField: 'code',
        textField: 'text',
        autobind: true,
        templateType: TemplateType.ItemDesc,
        maxResults: 30,
        picklistColumns: [],
        pageSizes: [5, 10, 15, 20],
        pageSizeSetting: this.localSettings.keys.typeahead.pageSize.default,
        allowEmptySearch: true
    };

    config = (key, options: TypeaheadConfig) => {
        this.globalOptions[key] = { ...options };
    };

    resolve = (attrs): TypeaheadConfig => {
        const configOptions = attrs.config && this.globalOptions[attrs.config] || {};
        const attrOptions = _.pick(attrs, this.attrKeys);
        const options = _.extend({}, this.defaultOptions, configOptions, attrOptions);

        if (!options.tagField) {
            options.tagField = options.textField || options.keyField;
        }

        if (options.pageSizes) {
            options.pageableOptions = {
                pageSizes: options.pageSizes
            };
        }

        return options as TypeaheadConfig;
    };

    configuration = () => {
        this.config('jurisdiction', {
            type: 'jurisdictions',
            label: 'picklist.jurisdiction.Type',
            size: 'xl',
            keyField: 'key',
            codeField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/jurisdictions',
            templateType: TemplateType.ItemCodeDesc,
            picklistTemplateType: PicklistTemplateType.Valid,
            picklistDisplayName: 'picklist.jurisdiction.Type',
            editUriState: 'jurisdictions.default',
            picklistColumns: [
                { title: 'picklist.jurisdiction.Description', field: 'value' },
                { title: 'picklist.jurisdiction.Code', field: 'code' },
                { title: null, field: 'isGroup', hidden: true, sortable: true },
                { title: null, field: 'key', hidden: true, sortable: true }
            ]
        });

        this.config('office', {
            type: 'offices',
            label: 'Office',
            keyField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/offices',
            templateType: TemplateType.ItemDesc,
            picklistColumns: [
                {
                    title: 'picklist.office.Description',
                    field: 'value',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.office.Organisation',
                    field: 'organisation',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.office.Country',
                    field: 'country',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.office.DefaultLanguage',
                    field: 'defaultLanguage',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                }
            ]
        });

        this.config('dataItemGroup', {
            type: 'dataItemGroup',
            label: 'picklist.dataitem.Group',
            keyField: 'key',
            codeField: 'code',
            textField: 'value',
            picklistDisplayName: 'picklist.dataitemgroup.Type',
            apiUrl: 'api/picklists/dataItemGroup',
            templateType: TemplateType.ItemDesc,
            picklistColumns: [
                { title: 'picklist.dataitem.Description', field: 'value' }
            ]
        });

        this.config('entryPoint', {
            type: 'entryPoint',
            label: 'picklist.dataitem.Group',
            keyField: 'name',
            textField: 'name',
            apiUrl: 'api/picklists/entrypoint/search',
            templateType: TemplateType.ItemNameDesc,
            picklistColumns: [
                { title: 'Entry Point No.', field: 'name' },
                { title: 'Description', field: 'description' }
            ]
        });

        this.config('caseType', {
            type: 'caseTypes',
            label: 'picklist.casetype.Type',
            keyField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/casetypes',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                {
                    title: 'picklist.casetype.Description',
                    field: 'value',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.casetype.Code',
                    field: 'code',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                }
            ]
        });

        this.config('roles', {
            type: 'roles',
            label: 'picklist.role.type',
            keyField: 'key',
            textField: 'value',
            picklistDisplayName: 'picklist.role.Type',
            apiUrl: 'api/picklists/roles',
            templateType: TemplateType.ItemDesc,
            picklistColumns: [
                { title: 'picklist.role.description', field: 'value' },
                { title: 'picklist.role.external', field: 'isExternal', defaultColumnTemplate: DefaultColumnTemplateType.selection, disabled: true }
            ]
        });

        this.config('tags', {
            type: 'tags',
            label: 'picklist.tag.Type',
            keyField: 'id',
            textField: 'tagName',
            apiUrl: 'api/picklists/tags',
            templateType: TemplateType.ItemCodeDesc
        });

        this.config('propertyType', {
            type: 'propertyTypes',
            label: 'picklist.propertytype.Type',
            keyField: 'code',
            codeField: 'code',
            textField: 'value',
            apiUrl: 'api/picklists/propertyTypes',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                {
                    title: 'picklist.propertytype.Description',
                    field: 'value',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.propertytype.Code',
                    field: 'code',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.propertytype.Icon',
                    field: 'image',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                }
            ]

        });

        this.config('validPropertyType', {
            type: 'propertyTypes',
            label: 'picklist.propertytype.Type',
            keyField: 'key',
            codeField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/propertyTypes',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                { title: 'picklist.propertytype.Icon', field: 'image', width: 10, sortable: false, defaultColumnTemplate: DefaultColumnTemplateType.icon }
            ]
        });

        this.config('alertTemplate', {
            type: 'propertyTypes',
            label: 'picklist.alertTemplate.Type',
            keyField: 'code',
            codeField: 'code',
            textField: 'message',
            apiUrl: 'api/picklists/adhoctemplates',
            templateType: TemplateType.ItemCode,
            picklistColumns: [
                { title: 'picklist.alertTemplate.code', field: 'code' },
                { title: 'picklist.alertTemplate.message', field: 'message' }
            ]
        });

        this.config('dateOfLaw', {
            type: 'datesOfLaw',
            label: 'picklist.dateoflaw.Type',
            keyField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/datesoflaw',
            templateType: TemplateType.ItemDesc
        });

        this.config('profile', {
            type: 'profile',
            label: 'picklist.profile.Type',
            keyField: 'key',
            textField: 'name',
            apiUrl: 'api/picklists/profile',
            templateType: TemplateType.ItemDesc,
            picklistColumns: [
                { title: 'picklist.profile.Name', field: 'name' },
                { title: 'picklist.profile.Description', field: 'description' }
            ]
        });

        this.config('taskPlannerSavedSearch', {
            type: 'taskPlannerSavedSearch',
            label: 'picklist.taskPlannerSavedSearch.type',
            keyField: 'key',
            codeField: 'key',
            textField: 'searchName',
            apiUrl: 'api/picklists/taskPlannerSavedSearch',
            templateType: TemplateType.ItemDesc,
            picklistNewSearch: true,
            picklistNavigateUri: 'taskPlannerSearchBuilder',
            hostingService: 'TaskPlannerPersistenceService',
            maintenanceTemplate: 'TaskPlannerPicklistComponent',
            picklistColumns: [
                { title: 'picklist.taskPlannerSavedSearch.name', field: 'searchName', sortable: true },
                { title: 'picklist.taskPlannerSavedSearch.description', field: 'description', width: 330 },
                {
                    title: 'picklist.taskPlannerSavedSearch.isPublic', field: 'isPublic', defaultColumnTemplate: DefaultColumnTemplateType.selection,
                    disabled: true,
                    preventCopy: true
                }

            ]
        });

        this.config('profitCentre', {
            type: 'profitCentre',
            label: 'picklist.profitCentre.type',
            keyField: 'code',
            codeField: 'code',
            textField: 'description',
            apiUrl: 'api/picklists/profitcentre',
            templateType: TemplateType.ItemCodeDesc,
            showDisplayField: true,
            picklistColumns: [
                { title: 'picklist.profitCentre.code', field: 'code' },
                { title: 'picklist.profitCentre.description', field: 'description' },
                { title: 'picklist.profitCentre.name', field: 'entityName', filter: true }
            ]
        });

        this.config('caseProgram', {
            type: 'caseProgram',
            label: 'picklist.caseProgram.Type',
            keyField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/program',
            templateType: TemplateType.ItemDesc,
            picklistColumns: [
                { title: 'picklist.caseProgram.Description', field: 'value' },
                { title: 'picklist.caseProgram.Code', field: 'key' }
            ],
            extendQuery: (query) => {
                return _.extend({}, query, {
                    programGroup: 'C'
                });
            }
        });

        this.config('nameGroup', {
            type: 'nameGroup',
            label: 'picklist.nameGroup.Type',
            keyField: 'key',
            textField: 'title',
            apiUrl: 'api/picklists/namegroup',
            templateType: TemplateType.ItemDesc,
            picklistColumns: [
                { title: 'picklist.nameGroup.Title', field: 'title' },
                { title: 'picklist.nameGroup.Comments', field: 'comments' }
            ]
        });

        this.config('action', {
            type: 'actions',
            label: 'picklist.action.Type',
            keyField: 'key',
            codeField: 'code',
            textField: 'value',
            apiUriName: 'actions',
            apiUrl: 'api/picklists/actions',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                {
                    title: 'picklist.action.Description',
                    field: 'value',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.action.Code',
                    field: 'code',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.action.Cycles',
                    field: 'cycles',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                }
            ]
        });

        this.config('caseCategory', {
            type: 'caseCategories',
            label: 'picklist.casecategory.Type',
            keyField: 'key',
            codeField: 'code',
            textField: 'value',
            apiUrl: 'api/picklists/caseCategories',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                {
                    title: 'picklist.casecategory.Description',
                    field: 'value',
                    sortable: true
                },
                {
                    title: 'picklist.casecategory.Code',
                    field: 'code',
                    sortable: true
                }
            ]
        });

        this.config('validCaseCategory', {
            type: 'caseCategories',
            label: 'picklist.casecategory.Type',
            keyField: 'key',
            codeField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/caseCategories',
            templateType: TemplateType.ItemCodeDesc
        });

        this.config('subType', {
            type: 'subTypes',
            label: 'picklist.subtype.Type',
            keyField: 'key',
            codeField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/subtypes',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                {
                    title: 'picklist.subtype.Description',
                    field: 'value',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.subtype.Code',
                    field: 'code',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                }
            ]
        });

        this.config('validSubType', {
            type: 'subTypes',
            label: 'picklist.subtype.Type',
            keyField: 'key',
            codeField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/subtypes',
            templateType: TemplateType.ItemCodeDesc
        });

        this.config('basis', {
            type: 'basis',
            label: 'picklist.basis.Type',
            keyField: 'key',
            codeField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/basis',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                {
                    title: 'picklist.basis.Description',
                    field: 'value',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.basis.Code',
                    field: 'code',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                }
            ]
        });

        this.config('validBasis', {
            type: 'basis',
            label: 'picklist.basis.Type',
            keyField: 'key',
            codeField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/basis',
            templateType: TemplateType.ItemCodeDesc
        });

        this.config('event', {
            type: 'events',
            label: 'picklist.event.Type',
            keyField: 'key',
            codeField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/events',
            templateType: TemplateType.ItemCodeDesc,
            size: 'xl',
            picklistColumns: [
                {
                    title: 'picklist.event.EventNo',
                    field: 'key',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.event.Code',
                    field: 'code',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.event.Description',
                    field: 'value',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false,
                    includeInChooser: false
                },
                {
                    title: 'picklist.event.Alias',
                    field: 'alias',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: false,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.event.MaxCycles',
                    field: 'maxCycles',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.event.Importance',
                    field: 'importance',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false,
                    filter: true
                },
                {
                    title: 'picklist.event.EventCategory',
                    field: 'eventCategory',
                    hidden: true,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false,
                    includeInChooser: true
                }, {
                    title: 'picklist.event.EventGroup',
                    field: 'eventGroup',
                    hidden: true,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false,
                    includeInChooser: true
                }, {
                    title: 'picklist.event.EventNotesGroup',
                    field: 'eventNotesGroup',
                    hidden: true,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: true,
                    hideByDefault: false,
                    includeInChooser: true
                }
            ]
        });

        this.config('dueDateEvent', {
            type: 'events',
            label: 'picklist.event.Type',
            keyField: 'key',
            codeField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/events',
            templateType: TemplateType.ItemCodeDesc,
            size: 'xl',
            picklistColumns: [
                {
                    title: 'picklist.event.Code',
                    field: 'code',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.event.Description',
                    field: 'value',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.event.maintenance.category',
                    field: 'eventCategory',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.event.Importance',
                    field: 'importance',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false,
                    filter: true
                },
                {
                    title: 'picklist.event.MaxCycles',
                    field: 'maxCycles',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.action.ImportanceLevel',
                    field: 'importanceLevel',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.event.EventNo',
                    field: 'key',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                }
            ]
        });

        this.config('caseEvent', {
            type: 'events',
            label: 'picklist.event.Type',
            keyField: 'key',
            codeField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/caseEvents',
            templateType: TemplateType.ItemCodeDesc,
            size: 'xl',
            picklistColumns: [
                {
                    title: 'picklist.event.Code',
                    field: 'code',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.event.Description',
                    field: 'value',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.event.Importance',
                    field: 'importance',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false,
                    filter: true
                },
                {
                    title: 'picklist.event.MaxCycles',
                    field: 'maxCycles',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.action.ImportanceLevel',
                    field: 'importanceLevel',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.event.EventNo',
                    field: 'key',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                }
            ]
        });

        this.config('case', {
            type: 'cases',
            label: 'picklist.case.Type',
            keyField: 'key',
            size: 'xl',
            codeField: 'code',
            textField: 'code',
            autobind: false,
            allowEmptySearch: false,
            extendedSearchFields: true,
            searchMoreInformation: 'caseSearch.moreInformation',
            apiUrl: 'api/picklists/cases',
            templateType: TemplateType.ItemCodeValue,
            picklistColumns: [
                {
                    title: 'picklist.case.CaseRef',
                    field: 'code',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.case.Title',
                    field: 'value',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.case.PropertyType',
                    field: 'propertyTypeDescription',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.case.Country',
                    field: 'countryName',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                }
            ]
        });

        this.config('caseWithName', {
            type: 'cases',
            label: 'picklist.case.Type',
            keyField: 'key',
            codeField: 'code',
            autobind: false,
            searchMoreInformation: 'caseSearch.moreInformation',
            textField: 'code',
            apiUrl: 'api/picklists/cases/instructor',
            allowEmptySearch: false,
            templateType: TemplateType.ItemCodeValue,
            picklistColumns: [
                {
                    title: 'picklist.case.CaseRef',
                    field: 'code',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.case.Title',
                    field: 'value',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.case.PropertyType',
                    field: 'propertyTypeDescription',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.case.Country',
                    field: 'countryName',
                    hidden: false,
                    key: null,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                }
            ]
        });

        this.config('relationship', {
            type: 'relationships',
            label: 'picklist.relationship.Type',
            keyField: 'key',
            codeField: 'code',
            textField: 'value',
            apiUrl: 'api/picklists/relationship',
            templateType: TemplateType.ItemCodeDesc
        });

        this.config('nameRelationship', {
            label: 'picklist.nameRelationship.type',
            keyField: 'key',
            codeField: 'code',
            textField: 'value',
            apiUrl: 'api/configuration/nameRelationships',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                { title: 'picklist.nameRelationship.description', field: 'relationDescription' },
                { title: 'picklist.nameRelationship.reverseDescription', field: 'reverseDescription' },
                { title: 'picklist.nameRelationship.code', field: 'code' }]
        });

        this.config('reverseNameRelationship', {
            label: 'namerelation.reverseNamerelationship',
            keyField: 'key',
            textField: 'reverseDescription',
            apiUrl: 'api/configuration/nameRelationships',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                { title: 'Description', field: 'reverseDescription' }
            ]
        });

        this.config('status', {
            label: 'picklist.status.label',
            keyField: 'key',
            codeField: 'code',
            textField: 'value',
            apiUrl: 'api/picklists/status',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                { title: 'picklist.status.Description', field: 'value' },
                { title: 'picklist.status.Code', field: 'code' },
                { title: 'picklist.status.Type', field: 'type' },
                { title: '', field: 'isPending', hidden: true },
                { title: '', field: 'isDead', hidden: true },
                { title: '', field: 'isRegistered', hidden: true },
                { title: '', field: 'isConfirmationRequired', hidden: true }
            ]
        });

        this.config('validAction', {
            type: 'actions',
            label: 'picklist.action.Type',
            keyField: 'key',
            codeField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/actions',
            templateType: TemplateType.ItemCodeDesc
        });

        this.config('checklist', {
            type: 'checklist',
            label: 'picklist.checklist.type',
            keyField: 'key',
            codeField: 'code',
            textField: 'value',
            apiUrl: 'api/picklists/checklist',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                { title: 'picklist.checklist.Description', field: 'value' },
                { title: 'picklist.checklist.Code', field: 'code' }
            ]
        });

        const namePicklistColumns = [
            { title: 'picklist.name.Name', field: 'displayName' },
            { title: 'picklist.name.Code', field: 'code' },
            { title: 'picklist.name.Remarks', field: 'remarks' }
        ];
        const namePageSizeOptions = [5, 10, 15, 20, 50];
        this.config('name', {
            label: 'picklist.name.Name',
            keyField: 'key',
            codeField: 'code',
            size: 'xl',
            textField: 'displayName',
            apiUrl: 'api/picklists/names',
            pageSizes: namePageSizeOptions,
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: namePicklistColumns,
            pageSizeSetting: this.localSettings.keys.typeahead.pageSize.names,
            autobind: false
        });

        this.config('instructor', {
            label: 'picklist.instructor',
            keyField: 'key',
            codeField: 'code',
            size: 'xl',
            textField: 'displayName',
            pageSizes: namePageSizeOptions,
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/names?filterNameType=I',
            picklistColumns: namePicklistColumns,
            pageSizeSetting: this.localSettings.keys.typeahead.pageSize.names,
            autobind: false
        });

        this.config('owner', {
            label: 'picklist.owner',
            keyField: 'key',
            codeField: 'code',
            size: 'xl',
            textField: 'displayName',
            pageSizes: namePageSizeOptions,
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/names?filterNameType=O',
            picklistColumns: namePicklistColumns,
            pageSizeSetting: this.localSettings.keys.typeahead.pageSize.names,
            autobind: false
        });

        this.config('agent', {
            label: 'picklist.agent',
            keyField: 'key',
            codeField: 'code',
            size: 'xl',
            textField: 'displayName',
            pageSizes: namePageSizeOptions,
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/names?filterNameType=A',
            picklistColumns: namePicklistColumns,
            pageSizeSetting: this.localSettings.keys.typeahead.pageSize.names,
            autobind: false
        });

        this.config('debtor', {
            label: 'picklist.debtor',
            keyField: 'key',
            codeField: 'code',
            size: 'xl',
            textField: 'displayName',
            pageSizes: namePageSizeOptions,
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/names?filterNameType=D',
            picklistColumns: namePicklistColumns,
            pageSizeSetting: this.localSettings.keys.typeahead.pageSize.names,
            autobind: false
        });

        this.config('staff', {
            label: 'picklist.staff',
            keyField: 'key',
            codeField: 'code',
            size: 'xl',
            textField: 'displayName',
            pageSizes: namePageSizeOptions,
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/names?filterNameType=EMP',
            picklistColumns: namePicklistColumns,
            pageSizeSetting: this.localSettings.keys.typeahead.pageSize.names,
            autobind: false
        });

        this.config('staffWithTimesheetViewAccess', {
            label: 'picklist.staff',
            keyField: 'key',
            codeField: 'code',
            textField: 'displayName',
            pageSizes: namePageSizeOptions,
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/names/timesheetViewAccess',
            picklistColumns: namePicklistColumns,
            pageSizeSetting: this.localSettings.keys.typeahead.pageSize.names,
            searchMoreInformation: 'accounting.time.staffPicklistInformation'
        });

        this.config('signatory', {
            label: 'picklist.signatory',
            keyField: 'key',
            codeField: 'code',
            size: 'xl',
            textField: 'displayName',
            pageSizes: namePageSizeOptions,
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/names?filterNameType=SIG',
            picklistColumns: namePicklistColumns,
            pageSizeSetting: this.localSettings.keys.typeahead.pageSize.names,
            autobind: false
        });

        this.config('nameFiltered', {
            label: 'picklist.name.Name',
            keyField: 'key',
            codeField: 'code',
            size: 'xl',
            previewable: true,
            textField: 'displayName',
            picklistDimmedColumnName: 'isGrayedRow',
            pageSizes: namePageSizeOptions,
            apiUrl: 'api/picklists/names',
            positionToShowCodeField: 'positionToShowCode',
            picklistTemplateType: PicklistTemplateType.NameFiltered,
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                { title: 'picklist.name.Name', field: 'displayName' },
                { title: 'picklist.name.Code', field: 'code' },
                { title: 'picklist.name.Remarks', field: 'remarks' },
                { title: '', field: 'isGrayedRow', hidden: true }
            ],
            pageSizeSetting: this.localSettings.keys.typeahead.pageSize.names,
            autobind: false
        });

        this.config('organisation', {
            label: 'picklist.client',
            keyField: 'key',
            codeField: 'code',
            size: 'xl',
            textField: 'displayName',
            pageSizes: namePageSizeOptions,
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/names',
            picklistColumns: [
                { title: 'picklist.name.Name', field: 'displayName' },
                { title: 'picklist.name.Code', field: 'code' },
                { title: 'picklist.name.Remarks', field: 'remarks' },
                { title: '', field: 'countryCode', hidden: true },
                { title: '', field: 'countryName', hidden: true }
            ],
            pageSizeSetting: this.localSettings.keys.typeahead.pageSize.names,
            extendQuery: (query) => {
                return _.extend({}, query, {
                    entityTypes: JSON.stringify({
                        isOrganisation: 'true'
                    })
                });
            },
            autobind: false
        });

        this.config('client', {
            label: 'picklist.client',
            keyField: 'key',
            codeField: 'code',
            size: 'xl',
            textField: 'displayName',
            pageSizes: namePageSizeOptions,
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/names',
            picklistColumns: namePicklistColumns,
            pageSizeSetting: this.localSettings.keys.typeahead.pageSize.names,
            extendQuery: (query) => {
                return _.extend({}, query, {
                    entityTypes: JSON.stringify({
                        isClient: 'true'
                    })
                });
            },
            autobind: false
        });

        this.config('supplier', {
            label: 'picklist.supplier',
            keyField: 'key',
            codeField: 'code',
            size: 'xl',
            textField: 'displayName',
            pageSizes: namePageSizeOptions,
            templateType: TemplateType.ItemCodeDesc,
            picklistTemplateType: PicklistTemplateType.Name,
            apiUrl: 'api/picklists/names',
            picklistColumns: namePicklistColumns,
            pageSizeSetting: this.localSettings.keys.typeahead.pageSize.names,
            extendQuery: (query) => {
                return _.extend({}, query, {
                    entityTypes: JSON.stringify({
                        isSupplier: 'true'
                    })
                });
            },
            autobind: false
        });

        this.config('edeNames', {
            label: 'picklist.name.Name',
            keyField: 'key',
            codeField: 'code',
            textField: 'displayName',
            pageSizes: namePageSizeOptions,
            picklistTemplateType: PicklistTemplateType.NameFiltered,
            apiUrl: 'api/picklists/names/aliastype/_E',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: namePicklistColumns,
            pageSizeSetting: this.localSettings.keys.typeahead.pageSize.names
        });

        this.config('document', {
            label: 'picklist.document.label',
            keyField: 'key',
            codeField: 'code',
            textField: 'value',
            templateType: TemplateType.ItemCodeDescKey,
            apiUrl: 'api/picklists/documents',
            searchMoreInformation: 'picklist.document.placeholder',
            picklistColumns: [
                { title: 'picklist.document.description', field: 'value' },
                { title: 'picklist.document.code', field: 'code' },
                { title: 'picklist.document.template', field: 'template' },
                { title: 'picklist.document.key', field: 'key' }
            ],
            pageSizeSetting: this.localSettings.keys.typeahead.pageSize.documents
        });

        this.config('numberType', {
            label: 'picklist.numberType.label',
            keyField: 'key',
            codeField: 'code',
            textField: 'value',
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/numbertypes',
            picklistColumns: [
                { title: 'Description', field: 'value' },
                { title: 'Code', field: 'code' },
                { title: 'picklist.numberType.relatedEvent', field: 'relatedEvent' },
                { title: 'picklist.numberType.issuedByIpOffice', field: 'issuedByIpOffice', defaultColumnTemplate: DefaultColumnTemplateType.selection, disabled: true }]
        });

        this.config('chargeType', {
            label: 'picklist.chargeType',
            keyField: 'key',
            textField: 'value',
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/chargeTypes',
            picklistColumns: [
                { title: 'Description', field: 'value' }
            ]
        });

        this.config('nameType', {
            label: 'picklist.nameType.type',
            keyField: 'key',
            codeField: 'code',
            textField: 'value',
            apiUrl: 'api/configuration/nametypepicklist',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                { title: 'picklist.nameType.description', field: 'value' },
                { title: 'picklist.nameType.code', field: 'code' }
            ]
        });

        this.config('nameTypeGroup', {
            type: 'nametypegroup',
            label: 'picklist.nameTypeGroup.label',
            keyField: 'key',
            codeField: 'code',
            textField: 'value',
            apiUrl: 'api/picklists/nameTypeGroup',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                { title: 'picklist.nameTypeGroup.description', field: 'value', width: 30 },
                { title: 'picklist.nameTypeGroup.members', field: 'nameTypes', sortable: false }
            ]
        });

        this.config('copyPresentation', {
            picklistDisplayName: 'caseSearch.presentationColumns.savedSearch',
            keyField: 'key',
            codeField: 'groupName',
            textField: 'value',
            apiUrl: 'api/picklists/copyPresentation',
            templateType: TemplateType.ItemCodeDesc,
            picklistColumns: [
                { title: 'caseSearch.presentationColumns.searchDescription', field: 'value' },
                { title: 'caseSearch.presentationColumns.searchGroup', field: 'groupName' }
            ]
        });

        this.config('instructionType', {
            type: 'instructionTypes',
            label: 'picklist.instructiontype.Type',
            keyField: 'key',
            codeField: 'code',
            textField: 'value',
            apiUrl: 'api/picklists/instructionTypes',
            templateType: TemplateType.ItemCodeDesc,
            maintenanceTemplate: 'IpxPicklistInstructionTypeComponent',
            picklistColumns: [
                { title: '', field: 'key', hidden: true, hideByDefault: false, key: true },
                { title: 'picklist.instructiontype.Code', field: 'code', preventCopy: true },
                { title: 'picklist.instructiontype.Description', field: 'value' },
                { title: 'picklist.instructiontype.RecordedAgainst', field: 'recordedAgainst' },
                { title: 'picklist.instructiontype.RestrictedBy', field: 'restrictedBy' },
                { title: '', field: 'recordedAgainstId', hidden: true },
                { title: '', field: 'restrictedById', hidden: true }
            ]
        });

        this.config('eventCategory', {
            type: 'eventCategories',
            label: 'picklist.eventCategory.label',
            keyField: 'key',
            textField: 'name',
            apiUriName: 'eventCategories',
            apiUrl: 'api/picklists/eventcategories',
            templateType: TemplateType.ItemDesc,
            picklistColumns: [
                { title: 'picklist.event.maintenance.category', field: 'name' }
            ]
        });

        this.config('fileLocation', {
            label: 'picklist.fileLocation.label',
            keyField: 'key',
            textField: 'value',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/fileLocations',
            picklistColumns: [
                { title: 'Description', field: 'value' },
                { title: 'Office', field: 'office' }
            ]
        });

        this.config('filePart', {
            label: 'caseview.fileLocations.filePart',
            keyField: 'key',
            textField: 'value',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/fileParts',
            picklistDisplayName: 'caseview.fileLocations.filePart',
            maintenanceDisplayName: 'caseview.fileLocations.filePart',
            maintenanceTemplate: 'FilePartPicklistComponent',
            fetchItemUri: 'case/{0}',
            fetchItemParam: 'caseId',
            picklistColumns: [
                {
                    title: 'Description',
                    field: 'value'
                }
            ]
        });

        this.config('instruction', {
            label: 'picklist.instruction.label',
            keyField: 'id',
            textField: 'description',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/instructions',
            picklistColumns: [{ title: 'Description', field: 'description' }]
        });

        this.config('characteristic', {
            label: 'picklist.characteristic.label',
            keyField: 'id',
            textField: 'description',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/characteristics',
            picklistColumns: [{ title: 'Description', field: 'description' }]
        });

        this.config('availableTopic', {
            label: 'picklist.availableTopic.label',
            keyField: 'key',
            textField: 'defaultTitle',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/availableTopic',
            picklistColumns: [
                { title: 'picklist.availableTopic.step', field: 'defaultTitle' },
                { title: 'picklist.availableTopic.category', field: 'typeDescription' },
                { title: 'picklist.availableTopic.availableInWeb', field: 'isWebEnabled', defaultColumnTemplate: DefaultColumnTemplateType.selection, disabled: true }]
        });

        this.config('textType', {
            label: 'picklist.textType.label',
            keyField: 'key',
            textField: 'value',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/texttypes',
            picklistColumns: [
                { title: 'picklist.textType.description', field: 'value' },
                { title: 'picklist.textType.code', field: 'key' }
            ]
        });

        this.config('modules', {
            label: 'picklist.program.label',
            keyField: 'key',
            textField: 'name',
            apiUrl: 'api/picklists/modules',
            templateType: TemplateType.ItemDesc,
            picklistColumns: [
                { title: 'picklist.program.description', field: 'name' }
            ]
        });

        this.config('kotStatus', {
            label: 'picklist.statusSummary.label',
            keyField: 'key',
            textField: 'name',
            apiUrl: 'api/picklists/kot-status',
            templateType: TemplateType.ItemDesc,
            picklistColumns: [
                { title: 'picklist.statusSummary.description', field: 'name' }
            ]
        });

        this.config('caseTextType', {
            label: 'picklist.textType.label',
            keyField: 'key',
            textField: 'value',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/texttypes',
            extendQuery: (query) => {
                return _.extend({}, query, {
                    mode: 'case'
                });
            },
            picklistColumns: [
                { title: 'picklist.textType.description', field: 'value' },
                { title: 'picklist.textType.code', field: 'key' }
            ]
        });

        this.config('nameTextType', {
            label: 'picklist.textType.label',
            keyField: 'key',
            textField: 'value',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/texttypes',
            extendQuery: (query) => {
                return _.extend({}, query, {
                    mode: 'name'
                });
            },
            picklistColumns: [
                { title: 'picklist.textType.description', field: 'value' },
                { title: 'picklist.textType.code', field: 'key' }
            ]
        });

        this.config('eventNoteGroup', {
            type: 'tablecodes',
            label: 'picklist.event.maintenance.eventNoteGroup',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'tablecodes',
            apiUrl: 'api/picklists/tablecodes',
            qualifiers: {
                type: 'notesharinggroup'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'notesharinggroup'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('eventNoteType', {
            label: 'picklist.eventNoteType.type',
            keyField: 'key',
            codeField: 'code',
            textField: 'value',
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/eventNoteType',
            picklistColumns: [
                { title: 'picklist.eventNoteType.description', field: 'value' },
                { title: 'picklist.eventNoteType.isExternal', field: 'IsExternal', defaultColumnTemplate: DefaultColumnTemplateType.selection, disabled: true }]
        });

        this.config('eventGroup', {
            label: 'picklist.event.maintenance.group',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'tablecodes',
            apiUrl: 'api/picklists/tablecodes',
            qualifiers: {
                type: 'eventgroup'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'eventgroup'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('language', {
            label: 'picklist.classitem.Language',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'tablecodes',
            apiUrl: 'api/picklists/tablecodes',
            qualifiers: {
                type: 'language'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'language'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('attachmentType', {
            label: 'picklist.classitem.AttachmentType',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'tablecodes',
            apiUrl: 'api/picklists/tablecodes',
            qualifiers: {
                type: 'attachmentType'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'attachmentType'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('countryTexts', {
            label: 'picklist.textType.label',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'tablecodes',
            apiUrl: 'api/picklists/tablecodes',
            qualifiers: {
                type: 'countryTextType'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'countryTextType'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('nameAddressReason', {
            label: 'picklist.textType.label',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'tablecodes',
            apiUrl: 'api/picklists/tablecodes',
            qualifiers: {
                type: 'nameAddressChangeReason'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'nameAddressChangeReason'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('predefinedNote', {
            label: 'taskPlanner.eventNotes.predefinedEventNotes',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'tablecodes',
            apiUrl: 'api/picklists/tablecodes',
            qualifiers: {
                type: 'EventNotes'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'EventNotes'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('staffClassification', {
            label: 'caseSearch.topics.names.staffClassification',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'tablecodes',
            apiUrl: 'api/picklists/tablecodes',
            qualifiers: {
                type: 'staffClassification'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'staffClassification'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('additionalNumberValidation', {
            type: 'tableCodes',
            label: 'picklist.additionalNumberPatternValidation.label',
            keyField: 'key',
            textField: 'value',
            templateType: TemplateType.ItemDesc,
            qualifiers: {
                type: 'officialNumberAdditionalValidation'
            },
            apiUrl: 'api/picklists/tablecodes',
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'officialNumberAdditionalValidation'
                });
            },
            picklistColumns: [
                { title: 'picklist.additionalNumberPatternValidation.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('designationStage', {
            label: 'picklist.designationStage.label',
            keyField: 'key',
            textField: 'value',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/designationstage',
            picklistColumns: [{ title: 'picklist.designationStage.description', field: 'value' }],
            picklistTemplateType: PicklistTemplateType.DesignationStage
        });

        this.config('images', {
            label: 'picklist.image.label',
            keyField: 'key',
            textField: 'description',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/images',
            picklistColumns: [
                { title: 'picklist.image.description', field: 'description', width: 60 },
                { title: 'picklist.image.status', field: 'imageStatus', width: 30 },
                { title: 'picklist.image.image', field: 'image', width: 10, defaultColumnTemplate: DefaultColumnTemplateType.image, sortable: false }]
        });

        this.config('dataDownloadCaseQueries', {
            label: 'picklist.dataDownloadCaseQueries.label',
            keyField: 'key',
            textField: 'name',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/dataDownloadCaseQueries',
            picklistColumns: [
                { title: 'picklist.dataDownloadCaseQueries.name', field: 'name', width: 50 },
                { title: 'picklist.dataDownloadCaseQueries.description', field: 'description' }
            ]
        });

        this.config('internalUsers', {
            label: 'picklist.internalUsers.label',
            keyField: 'key',
            codeField: 'name',
            textField: 'username',
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/internalUsers',
            picklistColumns: [
                { title: 'picklist.internalUsers.username', field: 'username' },
                { title: 'picklist.internalUsers.name', field: 'name' }
            ]
        });

        this.config('examinationType', {
            type: 'tablecodes',
            label: 'picklist.examinationType',
            keyField: 'key',
            textField: 'value',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/tablecodes',
            qualifiers: {
                type: 'examinationtype'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'examinationtype'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('renewalType', {
            type: 'tablecodes',
            label: 'picklist.renewalType',
            keyField: 'key',
            textField: 'value',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/tablecodes',
            qualifiers: {
                type: 'renewaltype'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'renewaltype'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('caseFamily', {
            label: 'picklist.casefamily.type',
            keyField: 'key',
            textField: 'value',
            apiUriName: 'caseFamilies',
            apiUrl: 'api/picklists/CaseFamilies',
            templateType: TemplateType.ItemDesc,
            picklistColumns: [
                {
                    title: 'picklist.casefamily.key',
                    field: 'key'
                },
                {
                    title: 'picklist.casefamily.description',
                    field: 'value'
                },
                {
                    title: 'picklist.casefamily.inUse',
                    field: 'inUse',
                    defaultColumnTemplate: DefaultColumnTemplateType.selection,
                    disabled: true,
                    preventCopy: true
                }
            ]
        });

        this.config('caseList', {
            type: 'caseList',
            label: 'picklist.caselist.type',
            keyField: 'key',
            textField: 'value',
            apiUriName: 'caseLists',
            codeField: 'value',
            size: 'lg',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/CaseLists',
            picklistDisplayName: 'picklist.caselist.type',
            maintenanceDisplayName: 'picklist.caselist.type',
            maintenanceTemplate: 'CaseListPicklistComponent',
            picklistColumns: [
                {
                    title: 'picklist.caselist.caseList',
                    field: 'value',
                    hidden: false,
                    key: true,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                },
                {
                    title: 'picklist.caselist.description',
                    field: 'description',
                    hidden: false,
                    key: true,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false,
                    width: 200
                },
                {
                    title: 'picklist.caselist.primeCase',
                    field: 'primeCaseName',
                    hidden: false,
                    key: true,
                    description: null,
                    preventCopy: null,
                    sortable: true,
                    menu: false,
                    hideByDefault: false
                }
            ]
        });

        this.config('typeOfMark', {
            type: 'tablecodes',
            label: 'picklist.typeOfMark',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            apiUrl: 'api/picklists/tablecodes',
            templateType: TemplateType.ItemDesc,
            qualifiers: {
                type: 'typeOfMark'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'typeOfMark'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('keyword', {
            type: 'keywords',
            label: 'picklist.keyword.type',
            keyField: 'key',
            codeField: 'id',
            textField: 'key',
            apiUrl: 'api/picklists/Keywords',
            templateType: TemplateType.ItemDesc,
            picklistColumns: [
                {
                    title: 'picklist.keyword.keyword',
                    field: 'key'
                },
                {
                    title: 'picklist.keyword.caseStopWord',
                    field: 'caseStopWord',
                    disabled: true,
                    defaultColumnTemplate: DefaultColumnTemplateType.selection
                },
                {
                    title: 'picklist.keyword.nameStopWord',
                    field: 'nameStopWord',
                    disabled: true,
                    defaultColumnTemplate: DefaultColumnTemplateType.selection
                }
            ]
        });

        this.config('tmClass', {
            label: 'picklist.tmClass.label',
            keyField: 'key',
            codeField: 'code',
            textField: 'code',
            templateType: TemplateType.ItemCodeValue,
            apiUrl: 'api/picklists/tmclass',
            picklistColumns: [
                { title: 'picklist.tmClass.class', field: 'code', width: 20 },
                { title: 'picklist.tmClass.heading', field: 'value' }
            ]
        });

        this.config('nameStyle', {
            label: 'jurisdictions.maintenance.addressSettings.nameStyle',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'tablecodes',
            apiUrl: 'api/picklists/tablecodes',
            qualifiers: {
                type: 'nameStyle'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'nameStyle'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('addressStyle', {
            label: 'jurisdictions.maintenance.addressSettings.addressStyle',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'tablecodes',
            apiUrl: 'api/picklists/tablecode',
            qualifiers: {
                type: 'addressStyle'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'addressStyle'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('postCodeSearch', {
            label: 'jurisdictions.maintenance.addressSettings.populateCityFromPostcode',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'tablecodes',
            apiUrl: 'api/picklists/tablecode',
            qualifiers: {
                type: 'postCodeSearch'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'postCodeSearch'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('currency', {
            label: 'picklist.currency.title',
            keyField: 'code',
            codeField: 'code',
            textField: 'description',
            showDisplayField: true,
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/currency',
            picklistColumns: [
                { title: 'picklist.currency.title', field: 'code', width: 20 },
                { title: 'picklist.currency.description', field: 'description' }
            ]
        });

        this.config('purchaseCurrency', {
            picklistDisplayName: 'picklist.currency.title',
            label: 'picklist.currency.title',
            keyField: 'code',
            codeField: 'code',
            textField: 'description',
            showDisplayField: true,
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/currency',
            picklistColumns: [
                { title: 'picklist.purchaseCurrency.code', field: 'code' },
                { title: 'picklist.purchaseCurrency.description', field: 'description' }
            ]
        });

        this.config('narrative', {
            label: 'picklist.narrative.label',
            keyField: 'key',
            codeField: 'code',
            textField: 'value',
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/narratives',
            picklistColumns: [
                { title: 'picklist.narrative.code', field: 'code' },
                { title: 'picklist.narrative.title', field: 'value' },
                { title: 'picklist.narrative.text', field: 'text' }
            ]
        });

        this.config('wipTemplate', {
            label: 'picklist.wipTemplate.label',
            keyField: 'key',
            codeField: 'key',
            textField: 'value',
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/wiptemplates',
            picklistColumns: [{ title: 'picklist.wipTemplate.description', field: 'value' }, { title: 'picklist.wipTemplate.code', field: 'key' }, { title: 'picklist.wipTemplate.type', field: 'type', filter: true }]
        });

        this.config('criteria', {
            label: 'Criteria',
            keyField: 'id',
            tagField: 'id',
            textField: 'description',
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/criteria',
            picklistColumns: [{ title: 'Criteria No', field: 'id' }, { title: 'Description', field: 'description' }],
            extendQuery: (query) => {
                return _.extend({}, query, {
                    purposeCode: 'E'
                });
            }
        });

        this.config('windowControlCriteria', {
            label: 'Criteria',
            keyField: 'id',
            tagField: 'id',
            textField: 'description',
            templateType: TemplateType.ItemIdDesc,
            apiUrl: 'api/picklists/criteria',
            picklistColumns: [{ title: 'Criteria No', field: 'id' }, { title: 'Description', field: 'description' }],
            extendQuery: (query) => {
                return _.extend({}, query, {
                    purposeCode: 'W'
                });
            }
        });

        this.config('checklistCriteria', {
            label: 'Criteria',
            keyField: 'id',
            tagField: 'id',
            textField: 'description',
            templateType: TemplateType.ItemIdDesc,
            apiUrl: 'api/picklists/criteria',
            picklistColumns: [{ title: 'Criteria No', field: 'id' }, { title: 'Description', field: 'description' }],
            extendQuery: (query) => {
                return _.extend({}, query, {
                    purposeCode: 'C'
                });
            }
        });

        this.config('dataItem', {
            type: 'dataItems',
            label: 'picklist.dataitem.Type',
            keyField: 'key',
            textField: 'code',
            size: 'lg',
            codeField: 'code',
            templateType: TemplateType.ItemCodeDesc,
            apiUriName: 'dataItems',
            apiUrl: 'api/picklists/dataItems',
            picklistDisplayName: 'picklist.dataitem.Type',
            maintenanceDisplayName: 'picklist.dataitem.Type',
            maintenanceTemplate: 'DataItemPicklistComponent',
            picklistColumns: [
                { title: 'picklist.dataitem.Code', field: 'code', width: 40 },
                { title: 'picklist.dataitem.Description', field: 'value', width: 275 },
                { title: null, field: 'key', hidden: true }
            ]
        });

        this.config('searchColumn', {
            type: 'searchColumn',
            label: 'picklist.searchColumn.Type',
            keyField: 'key',
            textField: 'description',
            size: 'lg',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/searchColumn',
            picklistDisplayName: 'picklist.searchColumn.Type',
            picklistColumns: [
                { title: 'picklist.searchColumn.Description', field: 'description' },
                { title: 'picklist.searchColumn.Format', field: 'dataFormat' }
            ]
        });

        this.config('searchGroup', {
            type: 'searchgroup',
            label: 'picklist.searchGroup.searchMenuGroup',
            keyField: 'key',
            textField: 'value',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'searchgroup',
            apiUrl: 'api/picklists/searchgroup',
            picklistDisplayName: 'picklist.searchGroup.searchMenuGroup',
            maintenanceDisplayName: 'picklist.searchGroup.searchMenuGroup',
            maintenanceTemplate: 'IpxPicklistSaveSearchMenuComponent',
            picklistColumns: [
                { title: 'picklist.searchGroup.description', field: 'value' },
                { title: null, field: 'contextId', hidden: true }
            ]
        });

        this.config('columnGroup', {
            type: 'columngroup',
            label: 'picklist.columnGroup.queryColumnGroup',
            keyField: 'key',
            textField: 'value',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/columngroup',
            picklistDisplayName: 'picklist.columnGroup.queryColumnGroup',
            maintenanceDisplayName: 'picklist.columnGroup.queryColumnGroup',
            maintenanceTemplate: 'IpxPicklistColumnGroupComponent',
            picklistColumns: [
                { title: 'picklist.columnGroup.description', field: 'value' },
                { title: null, field: 'contextId', hidden: true }
            ]
        });

        this.config('exchangeRateSchedule', {
            label: 'picklist.exchangeRateSchedule.label',
            keyField: 'id',
            codeField: 'code',
            textField: 'description',
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/exchangeRateSchedule',
            picklistColumns: [
                { title: 'picklist.exchangeRateSchedule.code', field: 'code' },
                { title: 'picklist.exchangeRateSchedule.description', field: 'description' }
            ]
        });

        this.config('ledgerAccount', {
            label: 'picklist.ledgerAccount.label',
            keyField: 'id',
            codeField: 'code',
            textField: 'description',
            size: 'xl',
            templateType: TemplateType.ItemCodeDesc,
            apiUrl: 'api/picklists/ledgerAccount',
            showDisplayField: true,
            picklistColumns: [
                { title: null, field: 'Id', hidden: true },
                { title: 'picklist.ledgerAccount.code', field: 'code' },
                { title: 'picklist.ledgerAccount.description', field: 'description' },
                { title: 'picklist.ledgerAccount.accountType', field: 'accountType' },
                { title: 'picklist.ledgerAccount.parentAccountCode', field: 'parentAccountCode' },
                { title: 'picklist.ledgerAccount.parentAccountDesc', field: 'parentAccountDesc' },
                { title: 'picklist.ledgerAccount.disburseToWip', field: 'disburseToWip', defaultColumnTemplate: DefaultColumnTemplateType.selection, disabled: true },
                { title: 'picklist.ledgerAccount.budgetMovement', field: 'budgetMovement' }
            ]
        });

        this.config('address', {
            label: 'picklist.address.label',
            keyField: 'id',
            textField: 'address',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/address',
            picklistColumns: [
                { title: 'picklist.address.address', field: 'address', defaultColumnTemplate: DefaultColumnTemplateType.textarea },
                { title: 'picklist.address.type', field: 'addressType' },
                { title: 'picklist.address.status', field: 'status' }
            ],
            fieldType: TypeaheadFieldType.TextArea
        });

        this.config('recordalTypes', {
            type: 'recordalTypes',
            label: 'picklist.recordalTypes.label',
            keyField: 'key',
            textField: 'value',
            templateType: TemplateType.ItemDesc,
            apiUrl: 'api/picklists/recordalTypes',
            picklistColumns: [
                { title: null, field: 'key', hidden: true },
                { title: 'picklist.recordalTypes.label', field: 'value' },
                { title: 'picklist.recordalTypes.requestEvent', field: 'requestEvent' },
                { title: 'picklist.recordalTypes.recordEvent', field: 'recordEvent' }
            ]
        });

        this.config('priorArtStatus', {
            label: 'Prior Art Status',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'tablecodes',
            apiUrl: 'api/picklists/tablecodes',
            qualifiers: {
                type: 'priorArtStatus'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'priorArtStatus'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' },
                { title: 'picklist.tableCode.code', field: 'code' }
            ]
        });

        this.config('webParts', {
            label: 'picklist.webParts.label',
            keyField: 'key',
            textField: 'title',
            apiUrl: 'api/picklists/web-parts',
            picklistColumns: [
                { title: null, field: 'key', hidden: true },
                { title: 'picklist.webParts.title', field: 'title', sortable: true },
                { title: 'picklist.webParts.description', field: 'description', sortable: true },
                { title: 'picklist.webParts.internal', field: 'isInternal', defaultColumnTemplate: DefaultColumnTemplateType.selection, disabled: true, sortable: true },
                { title: 'picklist.webParts.external', field: 'isExternal', defaultColumnTemplate: DefaultColumnTemplateType.selection, disabled: true, sortable: true }
            ]
        });

        this.config('taskList', {
            label: 'picklist.taskList.label',
            keyField: 'key',
            textField: 'taskName',
            apiUrl: 'api/picklists/Tasks',
            picklistColumns: [
                { title: null, field: 'key', hidden: true },
                { title: 'picklist.taskList.taskName', field: 'taskName' },
                { title: 'picklist.taskList.description', field: 'description' }
            ]
        });

        this.config('subjectList', {
            label: 'picklist.subjectList.label',
            keyField: 'key',
            textField: 'name',
            apiUrl: 'api/picklists/Subjects',
            picklistColumns: [
                { title: null, field: 'key', hidden: true },
                { title: 'picklist.subjectList.subjectName', field: 'name', sortable: true },
                { title: 'picklist.subjectList.description', field: 'description', sortable: true },
                { title: 'picklist.subjectList.internal', field: 'internalUse', defaultColumnTemplate: DefaultColumnTemplateType.selection, disabled: true, sortable: true },
                { title: 'picklist.subjectList.external', field: 'externalUse', defaultColumnTemplate: DefaultColumnTemplateType.selection, disabled: true, sortable: true }
            ]
        });

        this.config('tableColumnCase', {
            label: 'picklist.tableColumn.label',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'tablecodes',
            apiUrl: 'api/picklists/tablecodes',
            qualifiers: {
                type: 'validateColumn'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'validateColumn',
                    userCode: 'C'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' }
            ]
        });

        this.config('tableColumnName', {
            label: 'picklist.tableColumn.label',
            keyField: 'key',
            textField: 'value',
            codeField: 'code',
            templateType: TemplateType.ItemDesc,
            apiUriName: 'tablecodes',
            apiUrl: 'api/picklists/tablecodes',
            qualifiers: {
                type: 'validateColumn'
            },
            extendQuery: (query) => {
                return _.extend({}, query, {
                    tableType: 'validateColumn',
                    userCode: 'N'
                });
            },
            picklistColumns: [
                { title: 'picklist.tableCode.description', field: 'value' }
            ]
        });

        this.config('question', {
            label: 'picklist.questions.label',
            keyField: 'key',
            textField: 'question',
            codeField: 'code',
            apiUrl: 'api/picklists/questions',
            templateType: TemplateType.ItemDesc,
            size: 'xl',
            columnSelectionSetting: this.localSettings.keys.typeahead.columnSelection.questions,
            apiUriName: 'questions',
            maintenanceDisplayName: 'picklist.question.type',
            maintenanceTemplate: 'QuestionPicklistComponent',
            picklistColumns: [
                { title: 'picklist.question.number', field: 'key', sortable: true, hidden: true, hideByDefault: true, includeInChooser: true },
                { title: 'picklist.question.code', field: 'code', sortable: true, menu: false, includeInChooser: false },
                { title: 'picklist.question.question', field: 'question', sortable: true, menu: false, includeInChooser: false },
                { title: 'picklist.question.yesNo', field: 'yesNoValue', sortable: true, hideByDefault: false, menu: true, includeInChooser: true },
                { title: 'picklist.question.count', field: 'countValue', sortable: true, hideByDefault: false, menu: true, includeInChooser: true },
                { title: 'picklist.question.amount', field: 'amountValue', sortable: true, hideByDefault: false, menu: true, includeInChooser: true },
                { title: 'picklist.question.text', field: 'textValue', sortable: true, hideByDefault: false, menu: true, includeInChooser: true },
                { title: 'picklist.question.period', field: 'periodValue', sortable: true, hidden: true, hideByDefault: true, menu: true, includeInChooser: true },
                { title: 'picklist.question.list', field: 'list', sortable: true, hidden: true, hideByDefault: true, menu: true, includeInChooser: true },
                { title: 'picklist.question.staff', field: 'staffValue', sortable: true, hidden: true, hideByDefault: true, menu: true, includeInChooser: true },
                { title: 'picklist.question.instructions', field: 'instructions', sortable: true, hideByDefault: true, menu: true, includeInChooser: true }
            ]
        });
    };
}

export class TypeaheadConfig {
    label?: string;
    textField?: string;
    keyField?: string;
    apiUrl?: string;
    placeholder?: string;
    pageableOptions?: PageSettings;
    tagField?: string;
    codeField?: string;
    pageSizes?: Array<number>;
    templateType?: TemplateType;
    picklistTemplateType?: PicklistTemplateType;
    maintenanceTemplate?: string;
    maintenanceDisplayName?: string;
    apiUriName?: string;
    maxResults?: number;
    picklistColumns?: Array<GridColumnDefinition>;
    picklistCanMantain?: boolean;
    picklistDisplayName?: string;
    picklistTemplateUrl?: string;
    picklistDimmedColumnName?: string;
    editUriState?: string;
    size?: 'lg' | 'xl';
    qualifiers?: any;
    previewable?: boolean;
    extendQuery?: (query: any) => void;
    extendedParams?: (value: any) => void;
    externalScope?: any;
    pageSizeSetting?: LocalSetting;
    type?: string;
    showDisplayField?: boolean;
    fieldType?: string;
    positionToShowCodeField?: string;
    autobind?: boolean;
    searchMoreInformation?: string;
    fetchItemUri?: string;
    fetchItemParam?: string;
    picklistNewSearch?: boolean;
    picklistNavigateUri?: string;
    hostingService?: string;
    extendedSearchFields?: boolean;
    columnSelectionSetting?: LocalSetting;
    allowEmptySearch?: boolean;
}

export class TagsErrorValidator {
    validator: any;
    keys: Array<any>;
    keysType: 'key' | 'code';
    applyOnChange?: boolean;
}