angular.module('inprotech.components.form', []);
angular.module('inprotech.components.form').config(function(typeaheadConfigProvider) {
    'use strict';

    typeaheadConfigProvider.config('dataItem', {
        label: 'picklist.dataitem.Type',
        keyField: 'key',
        textField: 'code',
        codeField: 'code',
        restmodApi: 'dataItems',
        itemTemplateUrl: 'condor/components/form/autocomplete-data-item.html',
        picklistDisplayName: 'picklist.dataitem.Type'
    });

    typeaheadConfigProvider.config('jurisdiction', {
        label: 'picklist.jurisdiction.Type',
        keyField: 'key',
        codeField: 'key',
        textField: 'value',
        restmodApi: 'jurisdictions',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-template.html',
        picklistDisplayName: 'picklist.jurisdiction.Type',
        editUriState: 'jurisdictions.default'
    });

    typeaheadConfigProvider.config('office', {
        label: 'Office',
        keyField: 'key',
        textField: 'value',
        restmodApi: 'offices',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        picklistDisplayName: 'Office'
    });

    typeaheadConfigProvider.config('dataItemGroup', {
        label: 'picklist.dataitem.Group',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        restmodApi: 'dataItemGroup',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        picklistDisplayName: 'picklist.dataitemgroup.Type'
    });

    typeaheadConfigProvider.config('tags', {
        label: 'picklist.tag.Type',
        keyField: 'id',
        textField: 'tagName',
        restmodApi: 'tags',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistDisplayName: 'picklist.tags.Type'
    });

    typeaheadConfigProvider.config('propertyType', {
        label: 'picklist.propertytype.Type',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        restmodApi: 'propertyTypes',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-template.html',
        picklistDisplayName: 'picklist.propertytype.Type',
        picklistColumns: '[{title: "picklist.propertytype.Icon", field:"image", width:"10%", template:"<ip-property-type-icon data-ng-if=\'dataItem.image\' data-image-key=\'dataItem.image\'></ip-property-type-icon>", sortable: false}]'
    });

    typeaheadConfigProvider.config('caseType', {
        label: 'picklist.casetype.Type',
        keyField: 'key',
        textField: 'value',
        restmodApi: 'caseTypes',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-template.html',
        picklistDisplayName: 'picklist.casetype.Type'
    });

    typeaheadConfigProvider.config('validPropertyType', {
        label: 'picklist.propertytype.Type',
        keyField: 'key',
        codeField: 'key',
        textField: 'value',
        restmodApi: 'propertyTypes',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-template.html',
        picklistDisplayName: 'picklist.propertytype.Type',
        picklistColumns: '[{title: "picklist.propertytype.Icon", field:"image", width:"10%", template:"<ip-property-type-icon data-ng-if=\'dataItem.image\' data-image-key=\'dataItem.image\'></ip-property-type-icon>", sortable: false}]'
    });

    typeaheadConfigProvider.config('dateOfLaw', {
        label: 'picklist.dateoflaw.Type',
        keyField: 'key',
        textField: 'value',
        restmodApi: 'datesOfLaw',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-template.html',
        picklistDisplayName: 'picklist.dateoflaw.Type'
    });

    typeaheadConfigProvider.config('action', {
        label: 'picklist.action.Type',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        restmodApi: 'actions',
        apiUriName: 'actions',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-template.html',
        picklistDisplayName: 'picklist.action.Type'
    });

    typeaheadConfigProvider.config('caseCategory', {
        label: 'picklist.casecategory.Type',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        restmodApi: 'caseCategories',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-template.html',
        picklistDisplayName: 'picklist.casecategory.Type'
    });

    typeaheadConfigProvider.config('validCaseCategory', {
        label: 'picklist.casecategory.Type',
        keyField: 'key',
        codeField: 'key',
        textField: 'value',
        restmodApi: 'caseCategories',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-template.html',
        picklistDisplayName: 'picklist.casecategory.Type'
    });


    typeaheadConfigProvider.config('subType', {
        label: 'picklist.subtype.Type',
        keyField: 'key',
        codeField: 'key',
        textField: 'value',
        restmodApi: 'subTypes',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-template.html',
        picklistDisplayName: 'picklist.subtype.Type'
    });

    typeaheadConfigProvider.config('validSubType', {
        label: 'picklist.subtype.Type',
        keyField: 'key',
        codeField: 'key',
        textField: 'value',
        restmodApi: 'subTypes',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-template.html',
        picklistDisplayName: 'picklist.subtype.Type'
    });

    typeaheadConfigProvider.config('basis', {
        label: 'picklist.basis.Type',
        keyField: 'key',
        codeField: 'key',
        textField: 'value',
        restmodApi: 'basis',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-template.html',
        picklistDisplayName: 'picklist.basis.Type'
    });

    typeaheadConfigProvider.config('validBasis', {
        label: 'picklist.basis.Type',
        keyField: 'key',
        codeField: 'key',
        textField: 'value',
        restmodApi: 'basis',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-template.html',
        picklistDisplayName: 'picklist.basis.Type'
    });

    typeaheadConfigProvider.config('event', {
        label: 'picklist.event.Type',
        keyField: 'key',
        codeField: 'key',
        textField: 'value',
        restmodApi: 'events',
        apiUriName: 'events',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistColumns: "[{title:'picklist.event.Description', field:'value', width:'35%'}]",
        picklistDisplayName: 'picklist.event.Type',
        size: 'xl',
        columnMenu: true
    });

    typeaheadConfigProvider.config('case', {
        label: 'picklist.case.Type',
        keyField: 'key',
        codeField: 'code',
        textField: 'code',
        restmodApi: 'cases',
        itemTemplateUrl: 'condor/picklists/cases/cases-typeahead-template.html',
        picklistDisplayName: 'picklist.case.Type'
    });

    typeaheadConfigProvider.config('relationship', {
        label: 'picklist.relationship.Type',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        restmodApi: 'relationships',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistDisplayName: 'picklist.relationship.Type'
    });

    typeaheadConfigProvider.config('nameRelationship', {
        label: 'picklist.nameRelationship.type',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        apiUrl: 'api/configuration/nameRelationships',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistColumns: '[{title:\'picklist.nameRelationship.description\', field:\'relationDescription\'}, {title:\'picklist.nameRelationship.reverseDescription\', field:\'reverseDescription\'}, {title:\'picklist.nameRelationship.code\', field:\'code\'}]',
        picklistDisplayName: 'picklist.nameRelationship.type'
    });

    typeaheadConfigProvider.config('reverseNameRelationship', {
        label: 'namerelation.reverseNamerelationship',
        keyField: 'key',
        textField: 'reverseDescription',
        apiUrl: 'api/configuration/nameRelationships',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistColumns: '[{title:\'Description\', field:\'reverseDescription\'}]',
        picklistDisplayName: 'namerelation.reversenamerelationship'
    });

    typeaheadConfigProvider.config('status', {
        label: 'picklist.status.label',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        apiUrl: 'api/picklists/status',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-template.html',
        picklistColumns: "[{title:'picklist.status.Description', field:'value', width: '50%'}, {title:'picklist.status.Code', field:'code', width:'20%'},{title:'picklist.status.Type', field:'type', width:'30%'}]",
        picklistDisplayName: 'picklist.status.label'
    });

    typeaheadConfigProvider.config('validAction', {
        label: 'picklist.action.Type',
        keyField: 'key',
        codeField: 'key',
        textField: 'value',
        restmodApi: 'actions',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-template.html',
        picklistDisplayName: 'picklist.action.Type'
    });

    typeaheadConfigProvider.config('checklist', {
        label: 'picklist.checklist.type',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        restmodApi: 'checklist',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistDisplayName: 'picklist.checklist.type'
    });

    typeaheadConfigProvider.config('name', {
        label: 'picklist.name.Name',
        keyField: 'key',
        codeField: 'code',
        textField: 'displayName',
        apiUrl: 'api/picklists/names',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistDisplayName: 'picklist.name.Name',
        picklistColumns: '[{title:\'picklist.name.Name\', field:\'displayName\'}, {title:\'picklist.name.Code\', field:\'code\'}, {title:\'picklist.name.Remarks\', field:\'remarks\'}]'
    });

    typeaheadConfigProvider.config('instructor', {
        label: 'picklist.instructor',
        keyField: 'key',
        codeField: 'code',
        textField: 'displayName',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistDisplayName: 'picklist.instructor',
        apiUrl: 'api/picklists/names?filterNameType=I',
        picklistColumns: '[{title:\'picklist.name.Name\', field:\'displayName\'}, {title:\'picklist.name.Code\', field:\'code\'}, {title:\'picklist.name.Remarks\', field:\'remarks\'}]'
    });

    typeaheadConfigProvider.config('owner', {
        label: 'picklist.owner',
        keyField: 'key',
        codeField: 'code',
        textField: 'displayName',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistDisplayName: 'picklist.owner',
        apiUrl: 'api/picklists/names?filterNameType=O',
        picklistColumns: '[{title:\'picklist.name.Name\', field:\'displayName\'}, {title:\'picklist.name.Code\', field:\'code\'}, {title:\'picklist.name.Remarks\', field:\'remarks\'}]'
    });

    typeaheadConfigProvider.config('agent', {
        label: 'picklist.agent',
        keyField: 'key',
        codeField: 'code',
        textField: 'displayName',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistDisplayName: 'picklist.agent',
        apiUrl: 'api/picklists/names?filterNameType=A',
        picklistColumns: '[{title:\'picklist.name.Name\', field:\'displayName\'}, {title:\'picklist.name.Code\', field:\'code\'}, {title:\'picklist.name.Remarks\', field:\'remarks\'}]'
    });

    typeaheadConfigProvider.config('staff', {
        label: 'picklist.staff',
        keyField: 'key',
        codeField: 'code',
        textField: 'displayName',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistDisplayName: 'picklist.staff',
        apiUrl: 'api/picklists/names?filterNameType=EMP',
        picklistColumns: '[{title:\'picklist.name.Name\', field:\'displayName\'}, {title:\'picklist.name.Code\', field:\'code\'}, {title:\'picklist.name.Remarks\', field:\'remarks\'}]'
    });

    typeaheadConfigProvider.config('signatory', {
        label: 'picklist.signatory',
        keyField: 'key',
        codeField: 'code',
        textField: 'displayName',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistDisplayName: 'picklist.signatory',
        apiUrl: 'api/picklists/names?filterNameType=SIG',
        picklistColumns: '[{title:\'picklist.name.Name\', field:\'displayName\'}, {title:\'picklist.name.Code\', field:\'code\'}, {title:\'picklist.name.Remarks\', field:\'remarks\'}]'
    });

    typeaheadConfigProvider.config('nameFiltered', {
        size: 'xl',
        previewable: true,
        dimmedColumnName: 'isGrayedRow',
        label: 'picklist.name.Name',
        keyField: 'key',
        codeField: 'code',
        textField: 'displayName',
        apiUrl: 'api/picklists/names',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/search/case/casesearch/name-filtered-picklist-template.html',
        picklistDisplayName: 'picklist.name.Name',
        picklistColumns: '[{title:\'picklist.name.Name\', field:\'displayName\'}, {title:\'picklist.name.Code\', field:\'code\'}, {title:\'picklist.name.Remarks\', field:\'remarks\'}, {title:\'\', field:\'isGrayedRow\', hidden:\'true\'}]'
    });

    typeaheadConfigProvider.config('edeNames', {
        label: 'picklist.name.Name',
        keyField: 'key',
        codeField: 'code',
        textField: 'displayName',
        apiUrl: 'api/picklists/names/aliastype/_E',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/search/case/casesearch/name-filtered-picklist-template.html',
        picklistDisplayName: 'picklist.name.Name',
        picklistColumns: '[{title:\'picklist.name.Name\', field:\'displayName\'}, {title:\'picklist.name.Code\', field:\'code\'}, {title:\'picklist.name.Remarks\', field:\'remarks\'}]'
    });

    typeaheadConfigProvider.config('document', {
        label: 'picklist.document.label',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        apiUrl: 'api/picklists/documents',
        picklistDisplayName: 'picklist.document.label',
        picklistColumns: '[{title: "picklist.document.description", field: "value"}, {title: "picklist.document.code", field: "code"}, {title: "picklist.document.template", field: "template"}, {title:"picklist.document.key", field:"key"}]'
    });

    typeaheadConfigProvider.config('numberType', {
        label: 'picklist.numberType.label',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        apiUrl: 'api/picklists/numbertypes',
        picklistDisplayName: 'picklist.numberType.label',
        picklistColumns: '[{title: "Description", field: "value"}, {title: "Code", field: "code"}, {title: "picklist.numberType.relatedEvent", field: "relatedEvent"}, {title: "picklist.numberType.issuedByIpOffice", field:"issuedByIpOffice", template: \'<ip-checkbox ng-model="dataItem.issuedByIpOffice" disabled><ip-checkbox\>\'}]'
    });

    typeaheadConfigProvider.config('chargeType', {
        label: 'picklist.chargeType',
        keyField: 'key',
        textField: 'value',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        apiUrl: 'api/picklists/chargeTypes',
        picklistDisplayName: 'picklist.chargeType',
        picklistColumns: '[{title: "Description", field: "value"}]'
    });

    typeaheadConfigProvider.config('nameType', {
        label: 'picklist.nameType.type',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        apiUrl: 'api/configuration/nametypepicklist',
        picklistDisplayName: 'picklist.nameType.type',
        picklistColumns: "[{title:'picklist.nameType.description', field:'value'}, {title:'picklist.nameType.code', field:'code'}]"
    });

    typeaheadConfigProvider.config('nameTypeGroup', {
        label: 'picklist.nameTypeGroup.label',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        restmodApi: 'nametypegroup',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistDisplayName: 'picklist.nameTypeGroup.label',
        picklistColumns: "[{title:'picklist.nameTypeGroup.description', field:'value', width:'30%'}, {title:'picklist.nameTypeGroup.members', field:'nameTypes', sortable: false}]"
    });

    typeaheadConfigProvider.config('instructionType', {
        label: 'picklist.instructiontype.Type',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        restmodApi: 'instructionTypes',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistDisplayName: 'picklist.instructiontype.Type'
    });

    typeaheadConfigProvider.config('eventCategory', {
        label: 'picklist.eventCategory.label',
        keyField: 'key',
        textField: 'name',
        restmodApi: 'eventCategories',
        apiUriName: 'eventCategories',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        picklistColumns: '[{title:"picklist.eventCategory.name", field:"name"}, {title:"picklist.eventCategory.description", field:"description"}, {title: "picklist.eventCategory.image", field:"image", width:"10%", template:"<img ng-src=\'data:image/jpeg;base64, {{dataItem.image}}\' style=\'max-width: 32px\'>", sortable: false}, {title:"picklist.eventCategory.imageDescription", field:"imageDescription"}]',
        picklistDisplayName: 'picklist.eventCategory.label'
    });

    typeaheadConfigProvider.config('fileLocation', {
        label: 'picklist.fileLocation.label',
        keyField: 'key',
        textField: 'value',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        apiUrl: 'api/picklists/fileLocations',
        picklistDisplayName: 'picklist.fileLocation.label',
        picklistColumns: '[{title: "Description", field: "value"}, {title:"Office", field:"office"}]'
    });

    typeaheadConfigProvider.config('instruction', {
        label: 'picklist.instruction.label',
        keyField: 'id',
        textField: 'description',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        apiUrl: 'api/picklists/instructions',
        picklistDisplayName: 'picklist.instruction.label',
        picklistColumns: '[{title: "Description", field: "description"}]'
    });

    typeaheadConfigProvider.config('characteristic', {
        label: 'picklist.characteristic.label',
        keyField: 'id',
        textField: 'description',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        apiUrl: 'api/picklists/characteristics',
        picklistDisplayName: 'picklist.characteristic.label',
        picklistColumns: '[{title: "Description", field: "description"}]'
    });

    typeaheadConfigProvider.config('availableTopic', {
        label: 'picklist.availableTopic.label',
        keyField: 'key',
        textField: 'defaultTitle',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        apiUrl: 'api/picklists/availableTopic',
        picklistDisplayName: 'picklist.availableTopic.label',
        picklistColumns: '[{title: "picklist.availableTopic.step", field:"defaultTitle"}, {title: "picklist.availableTopic.category", field:"typeDescription"}, {title: "picklist.availableTopic.availableInWeb", field: "isWebEnabled", template: \'<ip-checkbox ng-model="dataItem.isWebEnabled" disabled><ip-checkbox\>\'}]'
    });

    typeaheadConfigProvider.config('textType', {
        label: 'picklist.textType.label',
        keyField: 'key',
        textField: 'value',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        apiUrl: 'api/picklists/texttypes',
        picklistDisplayName: 'picklist.textType.label',
        picklistColumns: "[{title:'picklist.textType.description', field:'value'}, {title:'picklist.textType.code', field:'key'}]"
    });

    typeaheadConfigProvider.config('eventNoteGroup', {
        label: 'picklist.event.maintenance.eventNoteGroup',
        keyField: 'key',
        textField: 'value',
        codeField: 'code',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        restmodApi: 'tablecodes',
        apiUriName: 'tablecodes',
        qualifiers: {
            type: 'notesharinggroup'
        },
        extendQuery: function(query) {
            return angular.extend({}, query, {
                tableType: 'notesharinggroup'
            });
        },
        picklistDisplayName: 'picklist.event.maintenance.eventNoteGroup',
        picklistColumns: '[{title: "picklist.tableCode.description", field: "value"}, {title: "picklist.tableCode.code", field: "code"}]'
    });

    typeaheadConfigProvider.config('eventNoteType', {
        label: 'picklist.eventNoteType.type',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistDisplayName: 'picklist.eventNoteType.type',
        apiUrl: 'api/picklists/eventNoteType',
        picklistColumns: '[{title:\'picklist.eventNoteType.description\', field:\'value\'}, {title:\'picklist.eventNoteType.isExternal\', field:\'IsExternal\', template: \'<ip-checkbox ng-model="dataItem.isExternal" disabled><ip-checkbox\>\'}]'
    });

    typeaheadConfigProvider.config('eventGroup', {
        label: 'picklist.event.maintenance.group',
        keyField: 'key',
        textField: 'value',
        codeField: 'code',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        restmodApi: 'tablecodes',
        apiUriName: 'tablecodes',
        qualifiers: {
            type: 'eventgroup'
        },
        extendQuery: function(query) {
            return angular.extend({}, query, {
                tableType: 'eventgroup'
            });
        },
        picklistDisplayName: 'picklist.event.maintenance.group',
        picklistColumns: '[{title: "picklist.tableCode.description", field: "value"}, {title: "picklist.tableCode.code", field: "code"}]'
    });

    typeaheadConfigProvider.config('language', {
        label: 'picklist.classitem.Language',
        keyField: 'key',
        textField: 'value',
        codeField: 'code',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        restmodApi: 'tablecodes',
        apiUriName: 'tablecodes',
        qualifiers: {
            type: 'language'
        },
        extendQuery: function(query) {
            return angular.extend({}, query, {
                tableType: 'language'
            });
        },
        picklistDisplayName: 'picklist.classitem.Language',
        picklistColumns: '[{title: "picklist.tableCode.description", field: "value"}, {title: "picklist.tableCode.code", field: "code"}]'
    });

    typeaheadConfigProvider.config('countryTexts', {
        label: 'picklist.textType.label',
        keyField: 'key',
        textField: 'value',
        codeField: 'code',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        restmodApi: 'tablecodes',
        apiUriName: 'tablecodes',
        qualifiers: {
            type: 'countryTextType'
        },
        extendQuery: function(query) {
            return angular.extend({}, query, {
                tableType: 'countryTextType'
            });
        },
        picklistDisplayName: 'picklist.textType.label',
        picklistColumns: '[{title: "picklist.tableCode.description", field: "value"}, {title: "picklist.tableCode.code", field: "code"}]'
    });

    typeaheadConfigProvider.config('additionalNumberValidation', {
        label: 'picklist.additionalNumberPatternValidation.label',
        keyField: 'key',
        textField: 'value',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        restmodApi: 'tablecodes',
        qualifiers: {
            type: 'officialNumberAdditionalValidation'
        },
        extendQuery: function(query) {
            return angular.extend({}, query, {
                tableType: 'officialNumberAdditionalValidation'
            });
        },
        picklistDisplayName: 'picklist.additionalNumberPatternValidation.picklistDisplayName',
        picklistColumns: "[{title: 'picklist.additionalNumberPatternValidation.description', field:'value'}, {title: 'picklist.tableCode.code', field:'code'}]"
    });

    typeaheadConfigProvider.config('designationStage', {
        label: 'picklist.designationStage.label',
        keyField: 'key',
        textField: 'value',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        apiUrl: 'api/picklists/designationstage',
        picklistDisplayName: 'picklist.designationStage.label',
        picklistTemplateUrl: 'condor/components/common-templates/designation-stage-picklist-template.html',
        picklistColumns: "[{title:'picklist.designationStage.description', field:'value'}]"
    });

    typeaheadConfigProvider.config('images', {
        label: 'picklist.image.label',
        keyField: 'key',
        textField: 'description',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        apiUrl: 'api/picklists/images',
        picklistDisplayName: 'picklist.image.label',
        picklistColumns: '[{title: "picklist.image.description", field: "description", width: "60%"}, {title: "picklist.image.status", field: "imageStatus", width: "30%"}, {title: "picklist.image.image", field: "image", width: "10%", template: "<img ng-src=\'data:image/jpeg;base64,{{dataItem.image}}\' style=\'max-width: 32px\'>", sortable: false}]'
    });

    typeaheadConfigProvider.config('dataDownloadCaseQueries', {
        label: 'picklist.dataDownloadCaseQueries.label',
        keyField: 'key',
        textField: 'name',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        apiUrl: 'api/picklists/dataDownloadCaseQueries',
        picklistDisplayName: 'picklist.dataDownloadCaseQueries.label',
        picklistColumns: '[{title: "picklist.dataDownloadCaseQueries.name", field: "name", width: "50%"}, {title: "picklist.dataDownloadCaseQueries.description", field: "description"}]'
    });

    typeaheadConfigProvider.config('internalUsers', {
        label: 'picklist.internalUsers.label',
        keyField: 'key',
        codeField: 'name',
        textField: 'username',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        apiUrl: 'api/picklists/internalUsers',
        picklistDisplayName: 'picklist.internalUsers.label',
        picklistColumns: '[{title:"picklist.internalUsers.username", field:\'username\'}, {title: "picklist.internalUsers.name", field: "name"}]'
    });

    typeaheadConfigProvider.config('examinationType', {
        label: 'picklist.examinationType',
        keyField: 'key',
        textField: 'value',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        restmodApi: 'tablecodes',
        qualifiers: {
            type: 'examinationtype'
        },
        extendQuery: function(query) {
            return angular.extend({}, query, {
                tableType: 'examinationtype'
            });
        },
        picklistDisplayName: 'picklist.examinationType',
        picklistColumns: '[{title: "picklist.tableCode.description", field: "value"}, {title: "picklist.tableCode.code", field: "code"}]'
    });

    typeaheadConfigProvider.config('renewalType', {
        label: 'picklist.renewalType',
        keyField: 'key',
        textField: 'value',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        restmodApi: 'tablecodes',
        qualifiers: {
            type: 'renewaltype'
        },
        extendQuery: function(query) {
            return angular.extend({}, query, {
                tableType: 'renewaltype'
            });
        },
        picklistDisplayName: 'picklist.renewalType',
        picklistColumns: '[{title: "picklist.tableCode.description", field: "value"}, {title: "picklist.tableCode.code", field: "code"}]'
    });

    typeaheadConfigProvider.config('caseFamily', {
        label: 'picklist.casefamily.type',
        keyField: 'key',
        textField: 'value',
        restmodApi: 'caseFamilies',
        apiUriName: 'caseFamilies',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        picklistDisplayName: 'picklist.casefamily.type'
    });

    typeaheadConfigProvider.config('caseList', {
        label: 'picklist.caselist.type',
        keyField: 'key',
        textField: 'value',
        restmodApi: 'caseLists',
        apiUriName: 'caseLists',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        picklistDisplayName: 'picklist.caselist.type'
    });

    typeaheadConfigProvider.config('typeOfMark', {
        label: 'picklist.typeOfMark',
        keyField: 'key',
        textField: 'value',
        codeField: 'code',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        restmodApi: 'tablecodes',
        qualifiers: {
            type: 'typeOfMark'
        },
        extendQuery: function(query) {
            return angular.extend({}, query, {
                tableType: 'typeOfMark'
            });
        },
        picklistDisplayName: 'picklist.typeOfMark',
        picklistColumns: '[{title: "picklist.tableCode.description", field: "value"}, {title: "picklist.tableCode.code", field: "code"}]'
    });

    typeaheadConfigProvider.config('keyword', {
        label: 'picklist.keyword.type',
        keyField: 'key',
        textField: 'key',
        restmodApi: 'keywords',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        picklistDisplayName: 'picklist.keyword.type'
    });

    typeaheadConfigProvider.config('tmClass', {
        label: 'picklist.tmClass.label',
        keyField: 'key',
        codeField: 'code',
        textField: 'code',
        itemTemplateUrl: 'condor/components/form/autocomplete-tmclass-code-desc.html',
        apiUrl: 'api/picklists/tmclass',
        picklistDisplayName: 'picklist.tmClass.label',
        picklistColumns: '[{title: "picklist.tmClass.class", field: "code", width: "20%"}, {title: "picklist.tmClass.heading", field: "value"}]'
    });

    typeaheadConfigProvider.config('nameStyle', {
        label: 'jurisdictions.maintenance.addressSettings.nameStyle',
        keyField: 'key',
        textField: 'value',
        codeField: 'code',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        restmodApi: 'tablecodes',
        apiUriName: 'tablecodes',
        qualifiers: {
            type: 'nameStyle'
        },
        extendQuery: function(query) {
            return angular.extend({}, query, {
                tableType: 'nameStyle'
            });
        },
        picklistDisplayName: 'jurisdictions.maintenance.addressSettings.nameStyle',
        picklistColumns: '[{title: "picklist.tableCode.description", field: "value"}, {title: "picklist.tableCode.code", field: "code"}]'
    });

    typeaheadConfigProvider.config('addressStyle', {
        label: 'jurisdictions.maintenance.addressSettings.addressStyle',
        keyField: 'key',
        textField: 'value',
        codeField: 'code',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        restmodApi: 'tablecodes',
        apiUriName: 'tablecodes',
        qualifiers: {
            type: 'addressStyle'
        },
        extendQuery: function(query) {
            return angular.extend({}, query, {
                tableType: 'addressStyle'
            });
        },
        picklistDisplayName: 'jurisdictions.maintenance.addressSettings.addressStyle',
        picklistColumns: '[{title: "picklist.tableCode.description", field: "value"}, {title: "picklist.tableCode.code", field: "code"}]'
    });

    typeaheadConfigProvider.config('postCodeSearch', {
        label: 'jurisdictions.maintenance.addressSettings.populateCityFromPostcode',
        keyField: 'key',
        textField: 'value',
        codeField: 'code',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        restmodApi: 'tablecodes',
        apiUriName: 'tablecodes',
        qualifiers: {
            type: 'postCodeSearch'
        },
        extendQuery: function(query) {
            return angular.extend({}, query, {
                tableType: 'postCodeSearch'
            });
        },
        picklistDisplayName: 'jurisdictions.maintenance.addressSettings.populateCityFromPostcode',
        picklistColumns: '[{title: "picklist.tableCode.description", field: "value"}, {title: "picklist.tableCode.code", field: "code"}]'
    });

    typeaheadConfigProvider.config('currency', {
        label: 'picklist.currency.title',
        keyField: 'id',
        codeField: 'code',
        textField: 'description',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        apiUrl: 'api/picklists/currency',
        picklistDisplayName: 'picklist.currency.title',
        picklistColumns: '[{title: "picklist.currency.title", field: "code", width: "20%"}, {title: "picklist.currency.description", field: "description"}]'
    });

    typeaheadConfigProvider.config('wipTemplate', {
        label: 'picklist.wipTemplate.label',
        keyField: 'key',
        codeField: 'key',
        textField: 'value',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        apiUrl: 'api/picklists/wiptemplates',
        picklistDisplayName: 'picklist.wipTemplate.label',
        picklistColumns: "[{title:'picklist.wipTemplate.description', field:'value'}, {title:'picklist.wipTemplate.code', field:'key'}, {title:'picklist.wipTemplate.type', field:'type', filterable: true, filterApi:'api/picklists/wiptemplates'}]"
    });

    typeaheadConfigProvider.config('narratives', {
        label: 'picklist.narrative.label',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        apiUrl: 'api/picklists/narratives',
        picklistDisplayName: 'picklist.narrative.label',
        picklistColumns: '[{title: "picklist.narrative.code", field: "code"}, {title: "picklist.narrative.title", field: "value"}, {title: "picklist.narrative.text", field: "text"}]'
    });
});