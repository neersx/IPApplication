angular.module('inprotech.components.form').provider('typeaheadConfig', function() {
    'use strict';

    var globalOptions = {};
    var attrKeys = [
        'label',
        'placeholder',
        'keyField',
        'codeField',
        'textField',
        'tagField',
        'maxResults',
        'apiUrl',
        'restmodApi',
        'itemTemplateUrl',
        'picklistTemplateUrl',
        'picklistDisplayName',
        'picklistCanMaintain',
        'picklistColumns',
        'size',
        'columnMenu',
        'initFunction',
        'preSearch',
        'previewable',
        'dimmedColumnName',
        'displayCodeWithText'
    ];
    var defaultOptions = {
        keyField: 'id',
        codeField: 'code',
        textField: 'text',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-desc.html',
        maxResults: 30
    };

    this.config = function(key, options) {
        globalOptions[key] = angular.copy(options);
        return this;
    };

    this.$get = function(apiResolverService) {
        return {
            resolve: function(attrs, scope) {
                var configOptions = attrs.config && globalOptions[attrs.config] || scope && globalOptions[scope.config] || {};
                var attrOptions = _.pick(attrs, attrKeys);
                var options = angular.extend({}, defaultOptions, configOptions, attrOptions);

                if (options.restmodApi) {
                    options.apiUrl = apiResolverService.resolve(options.restmodApi).$url();
                }

                if (!options.tagField) {
                    options.tagField = options.textField || options.keyField;
                }

                return options;
            },
            $reveal: function() {
                return _.keys(globalOptions);
            }
        };
    };
});