namespace inprotech.configuration.general.ede.datamapping {

    export class DataMappingTopicsController {
        static $inject = ['viewData', '$translate'];

        viewData;
        options;
        headerTitle;

        constructor(viewData, private $translate) {
            this.viewData = viewData;
            this.initTopics();
        }

        initTopics = () => {
            this.headerTitle = this.$translate.instant('dataMapping.headerTitle') + this.viewData.displayText;
            this.options = { topics: [], actions: [] };
            _.each(this.viewData.structures, (structure) => {
                this.options.topics.push({
                    key: structure,
                    title: structure,
                    template: '<ip-datamapping-structure data-topic="$topic">',
                    parentId: this.viewData.dataSource
                });
            })
        }

        onTopicSelected = (topicKey) => {
            let flattenTopics = [];
            this.flatten(this.options.topics, flattenTopics);
            _.each(flattenTopics, (topic) => {
                if (topic.key === topicKey) {
                    if (_.isFunction(topic.initShortcuts)) {
                        topic.initShortcuts();
                    }
                }
            });
        }

        flatten = (topics, output) => {
            _.each(topics, (topic: ITopicEntity) => {
                output.push(topic);
                if (topic.topics) {
                    this.flatten(topic.topics, output);
                }
            });
        }
    }

    angular.module('inprotech.configuration.general.ede.datamapping')
        .controller('DataMappingTopicsController', DataMappingTopicsController);
}