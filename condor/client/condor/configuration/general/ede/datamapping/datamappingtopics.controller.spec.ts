namespace inprotech.configuration.general.ede.datamapping {

    describe('inprotech.configuration.general.general.ede.datamapping', () => {
        'use strict';

        let controller: (dependencies?: any) => DataMappingTopicsController;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.general.ede.datamapping');
        });

        beforeEach(inject(($translate: any) => {
            controller = (dependencies?) => {
                dependencies = angular.extend({
                    viewData: {
                        dataSource: 'File',
                        structures: ['Events', 'Documents']
                    }
                }, dependencies);
                return new DataMappingTopicsController(dependencies.viewData, $translate);
            };
        }));

        describe('initialize topics', () => {
            let c: DataMappingTopicsController;
            it('should initialize grid builder options along with search criteria', () => {
                c = controller();

                c.initTopics();
                let eventsTopic: any = _.first(c.options.topics),
                    documentsTopic: any = _.last(c.options.topics);

                expect((<Array<any>>c.options.topics).length).toBe(2);
                expect(eventsTopic.key).toBe('Events');
                expect(documentsTopic.key).toBe('Documents');
                expect(documentsTopic.parentId).toBe('File');
                expect(eventsTopic.parentId).toBe('File');
            });
        });
    });
}