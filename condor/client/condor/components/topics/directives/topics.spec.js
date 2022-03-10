xdescribe('inprotech.components.topics', function() {
    'use strict';

    beforeEach(module('inprotech.components'));
    beforeEach(module('condor/components/topics/directives/topics.html'));
    beforeEach(module('condor/components/topics/directives/topic-menu-item.html'));

    var scope, element, compileDirective, isolateScope, state, stepsPersistenceSvc;

    beforeEach(module(function() {
        test.mock('$timeout', _.noop);
        test.mock('$state', 'stateMock');
        test.mock('focusService', {});
        stepsPersistenceSvc = test.mock('StepsPersistenceService', 'StepsPersistenceServiceMock');
    }));

    beforeEach(inject(function($compile, $rootScope) {
        scope = $rootScope.$new();

        compileDirective = function(customTopics) {
            var defaultMarkup = angular.element('<ip-topics data-options="vm.topicOptions" is-multi-step-mode="true"></ip-topics>');
            scope.lastActive = {
                $state: state
            };
            scope.vm = {
                topicOptions: {
                    topics: customTopics || [{
                        key: 'overview',
                        title: 'Overview Title',
                        subTitle: 'Overview Subtitle',
                        template: '<div><span id="overview">Hello Overview</span></div>'
                    }, {
                        key: 'groupTopic',
                        title: 'Group Topic Title',
                        subTitle: 'Group Topic Subtitle',
                        topics: [{
                            key: 'subTopic',
                            title: 'Sub Topic Title',
                            subTitle: 'Sub Topic Subtitle',
                            template: '<div><span id="subTopic">Hello Sub Topic</span></div>'
                        }]
                    }],
                    actions: []
                }
            };
            element = $compile(defaultMarkup)(scope);
            scope.$digest();
            isolateScope = element.isolateScope();
        };
    }));

    describe('topics directive', function() {
        it('prunes null topics', function() {
            var topics = [{
                key: 'topic'
            }, null, {
                key: 'group',
                topics: [{
                    key: 'subtopic'
                }, null]
            }];
            compileDirective(topics);

            expect(isolateScope.options.topics.length).toEqual(2);
            expect(isolateScope.options.topics[1].topics.length).toEqual(1);
            expect(isolateScope.options.topics[0].key).toEqual('topic');
            expect(isolateScope.options.topics[1].key).toEqual('group');
            expect(isolateScope.options.topics[1].topics[0].key).toEqual('subtopic');
        });

        it('initialises topic', function() {
            var initSpy = jasmine.createSpy();
            var topics = [{
                key: 'topic',
                initialise: initSpy
            }]
            compileDirective(topics);
            expect(initSpy).toHaveBeenCalled();
        });

        it('marks group sections and sub sections', function() {
            compileDirective();
            expect(isolateScope.options.topics[1].isGroupSection).toBe(true);
            expect(isolateScope.options.topics[1].topics[0].isSubSection).toBe(true);
        });

        it('hides separator on last sub section', function() {
            var topics = [{
                key: 'topic',
                topics: [{
                    key: 'subtopic'
                }, {
                    key: 'subtopic1'
                }]
            }];
            compileDirective(topics);
            expect(isolateScope.options.topics[0].topics[0].noSeparator).toBeFalsy();
            expect(isolateScope.options.topics[0].topics[1].noSeparator).toBe(true);
        });

        it('hides separator section preceding group section', function() {
            var topics = [{
                key: 'topic'
            }, {
                key: 'topic1'
            }, {
                key: 'groupTopic',
                topics: [{}, {}]
            }];
            compileDirective(topics);
            expect(isolateScope.options.topics[0].noSeparator).toBeFalsy();
            expect(isolateScope.options.topics[1].noSeparator).toBe(true);
        });

        it('sets current tab when selected', function() {
            compileDirective();
            isolateScope.selectTab('abc');
            expect(isolateScope.currentTab).toBe('abc');
        });

        it('should hide actions tab when no action is present', function() {
            compileDirective();
            expect(isolateScope.isActionsTabVisible()).toBeFalsy();
        });

        it('should display actions tab when action is present', function() {
            compileDirective();
            scope.vm.topicOptions.actions = [{
                key: 'action1'
            }, {
                key: 'action2'
            }];
            expect(isolateScope.isActionsTabVisible()).toBeTruthy();
        });
        it('evaluate if topic options have sub sections', function() {
            var topics = [{
                key: 'topic'
            }, {
                key: 'topic1'
            }, {
                key: 'groupTopic',
                topics: [{}, {}]
            }];
            compileDirective(topics);
            expect(isolateScope.hasSubSections()).toBe(true);
        });
    });

    describe('topics multistep mode', function() {
        it('subscribe to step changed event on scope', function() {
            var initSpy = jasmine.createSpy();
            var topics = [{
                key: 'topic',
                initialise: initSpy,
                loadFormData: initSpy
            }];
            scope.isMultiStepMode = true;
            compileDirective(topics);

            scope.$broadcast('stepChanged', {
                stepId: 1
            });

            expect(stepsPersistenceSvc.initTopicsFormData).toHaveBeenCalled();
            expect(stepsPersistenceSvc.getStepTopicData).toHaveBeenCalled();
            expect(topics[0].loadFormData).toHaveBeenCalled();
        });

    });

    describe('topics menu', function() {
        it('renders the topic menu', function() {
            compileDirective();

            var firstLevelMenus = element.find('div.tab-pane > ul > li > div > ng-include > span');
            var subTopicMenu = element.find('div.tab-pane > ul > li > ul > li span');

            expect(angular.element(firstLevelMenus[0]).text()).toEqual('Overview Title');
            expect(angular.element(firstLevelMenus[2]).text()).toEqual('Group Topic Title');
            expect(subTopicMenu.text()).toEqual('Sub Topic Title');
        });

        it('renders groups and topics with titles', function() {
            compileDirective();

            var overviewTopic = element.find('div.topic-container[data-topic-key="overview"]');
            var groupSection = element.find('div.topic-group div.topic-container.group-section[data-topic-key="groupTopic"]');
            var subTopic = element.find('div.topic-group div.topic-container[data-topic-key="subTopic"]');

            expect(overviewTopic.find('h1').text()).toEqual('Overview Title');
            expect(overviewTopic.find('h2').text()).toEqual('Overview Subtitle');
            expect(overviewTopic.find('#overview').text()).toEqual('Hello Overview');

            expect(groupSection.find('h1').text()).toEqual('Group Topic Title');
            expect(groupSection.find('h2').text()).toEqual('Group Topic Subtitle');

            expect(subTopic.find('h1').text().trim()).toEqual('Sub Topic Title');
            expect(subTopic.find('h2').text().trim()).toEqual('Sub Topic Subtitle');
            expect(subTopic.find('#subTopic').text().trim()).toEqual('Hello Sub Topic');
        });
    });
});