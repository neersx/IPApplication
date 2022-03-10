'use strict';

class UploadController {

    topics: any = {
        mappings: {
            key: 'schemaMapping.usLblMappings',
            title: 'schemaMapping.usLblMappings',
            template: '<mappings-list data-topic="$topic"></mappings-list>'
        },
        schemapackages: {
            key: 'schemaMapping.usLblSchemaPackages',
            title: 'schemaMapping.usLblSchemaPackages',
            template: '<schemas-list data-topic="$topic" ></schemas-list>'
        }
    };

    public details: any;

    constructor() {
        this.init();
    }

    init = (): void => {
        this.details = {
            topicControl: {
                topics: [this.topics.mappings, this.topics.schemapackages],
                actions: []
            }
        };
    }
}

angular.module('Inprotech.SchemaMapping')
    .controller('uploadController', UploadController);