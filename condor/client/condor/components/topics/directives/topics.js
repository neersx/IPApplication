angular.module('inprotech.components.topics')
    .directive('ipTopics', function($timeout, $state, focusService, $transitions, StepsPersistenceService) {
        'use strict';
        var lastActive = {};

        return {
            restrict: 'E',
            templateUrl: function(element, attribute) {
                return (attribute && (attribute.type === 'simple' || attribute.type === 'simpleRestrictWidth')) ?
                    'condor/components/topics/directives/topics-simple.html' : 'condor/components/topics/directives/topics.html';
            },
            transclude: {
                'header': '?ipTopicsHeader'
            },
            scope: {
                options: '<',
                topicMenuItemTemplateUrl: '@?',
                onTopicSelected: '&',
                subTitleInfoTemplate: '@?',
                isMultiStepMode: '@?'
            },
            link: function(scope, element, attribute) {
                if (!_.any(StepsPersistenceService.topicsFormData)) {
                    StepsPersistenceService.initTopicsFormData();
                }

                if (!scope.topicMenuItemTemplateUrl) {
                    scope.topicMenuItemTemplateUrl = 'condor/components/topics/directives/topic-menu-item.html';
                }

                if (attribute && attribute.type === 'simpleRestrictWidth') {
                    scope.restrictWidth = true;
                }

                var lastActiveTopic = lastActive[$state.current.name];
                var flattenTopics = [];

                scope.options.topics = filterNulls(scope.options.topics);
                flatten(scope.options.topics, flattenTopics);

                _.each(flattenTopics, function(topic, index) {
                    topic.index = index;
                    if (lastActiveTopic != null) {
                        topic.isActive = topic.key === lastActiveTopic.key;
                    }

                    if (_.isFunction(topic.initialise)) {
                        topic.initialise();
                    }

                    if (topic.topics) {
                        topic.isGroupSection = true;
                    } else {
                        topic.isSubSection = true;
                    }
                });

                //set noSeparator
                _.each(flattenTopics, function(topic, index) {
                    var next = flattenTopics[index + 1];
                    if (!next || next.isGroupSection) {
                        topic.noSeparator = true;
                    }
                });

                var anyActiveTopics = _.any(flattenTopics, function(t) {
                    return t.isActive;
                });

                if (lastActiveTopic != null && !anyActiveTopics) {
                    if (flattenTopics.length <= lastActiveTopic.index) {
                        _.last(flattenTopics).isActive = true;
                    } else {
                        flattenTopics[lastActiveTopic.index].isActive = true;
                    }
                }

                scope.selectTopic = function(topic, scrollable) {
                    _.each(flattenTopics, function(t) {
                        t.isActive = false;
                    });

                    topic.isActive = true;

                    if (scrollable) {
                        scrollToTopic(element, topic, true);
                    }

                    lastActive[$state.current.name] = {
                        key: topic.key,
                        index: topic.index
                    };

                    scope.onTopicSelected({
                        topicKey: topic.key
                    });
                };

                scope.currentTab = 'topics';

                scope.selectTab = function(tab) {
                    scope.currentTab = tab;
                };

                scope.isActionsTabVisible = function() {
                    return _.any(scope.options.actions);
                }

                scope.hasSubSections = function() {
                    return _.any(scope.options.topics, {
                        isGroupSection: true
                    });
                }

                scope.$on('stepChanged', function(event, id) {
                    var stepsData = StepsPersistenceService.getStepTopicData(id.stepId);
                    _.each(scope.options.topics, function(topic) {
                        if (stepsData && _.any(stepsData)) {
                            var relevantTopicData = _.first(_.filter(stepsData, function(stepData) {
                                return stepData.topicKey === topic.key;
                            }));
                            topic.loadFormData(relevantTopicData.formData);
                        } else {
                            var defaultFormData = StepsPersistenceService.defaultTopicsFormData(topic.key);
                            topic.loadFormData(defaultFormData);
                        }
                        topic.isActive = false;
                        if (topic.key === 'References') {
                            topic.isActive = true;
                            scrollToTopic(element, topic, false);
                        }
                    });
                });

                scope.$on('stepsLoaded', function() {
                    _.each(StepsPersistenceService.steps, function(step) {
                        var stepsData = StepsPersistenceService.getStepTopicData(step.id);
                        _.each(scope.options.topics, function(topic) {
                            if (stepsData && _.any(stepsData)) {
                                var relevantTopicData = _.first(_.filter(stepsData, function(stepData) {
                                    return stepData.topicKey === topic.key;
                                }));

                                var filterData = topic.getFormData(relevantTopicData.formData);
                                relevantTopicData.filterData = filterData;
                            }
                        });
                    });
                });

                scope.$on('topicItemNumbers', function(event, data) {
                    if (data) {
                        var topic;
                        if (data.isSubSection) {
                            topic = _.find(scope.options.topics, function(i) {
                                return i.topics && _.find(i.topics, function(s) {
                                    return s.key === data.key
                                });
                            });
                        } else {
                            topic = _.find(scope.options.topics, function(i) {
                                return i.key === data.key
                            });
                        }
                        if (topic && element) {
                            var tabItem = element.find('.topics>.topic-menu .tab-content li[data-topic-ref="' + data.key + '"] #topicDataCount');
                            if (tabItem && tabItem.length > 0) {
                                tabItem[0].innerHTML = data.total ? data.total : '';
                            }
                            var headerItem = element.find('.topics .topics-container div[data-topic-key="' + data.key + '"] #topicDataCount');
                            if (headerItem && headerItem.length > 0) {
                                headerItem[0].innerHTML = data.total ? data.total : '';
                            }
                        }
                    }
                });

                var sensor;
                var scrollToActive = function() {
                    var activeTopic = _.findWhere(flattenTopics, {
                        isActive: true
                    });
                    if (activeTopic) {
                        scrollToTopic(element, activeTopic, false);
                    }
                    $timeout(sensor.detach, 5000);
                };

                sensor = new window.ResizeSensor(element.find('.topics-container'), scrollToActive);

                $transitions.onStart({}, function(trans) {
                    var toState = trans.to();
                    var fromState = trans.from();
                    if (!isParentState(fromState, toState) && toState.name !== fromState.name) {
                        delete lastActive[fromState.name];
                    }
                });

                scope.$on('$destroy', function() {
                    sensor.detach();
                });
            }
        };

        function filterNulls(topics) {
            topics = _.compact(topics);

            _.each(topics, function(topic) {
                if (topic.topics) {
                    topic.topics = filterNulls(topic.topics);
                }
            });

            return topics;
        }

        function flatten(topics, output) {
            _.each(topics, function(topic) {
                output.push(topic);
                if (topic.topics) {
                    flatten(topic.topics, output);
                }
            });
        }

        function scrollToTopic(rootElm, topic, animate) {
            var topicDiv = rootElm.find('.topic-container[data-topic-key="' + topic.key + '"]');
            if (!topicDiv.length) {
                return;
            }

            var scrollFixedTop = $('ip-sticky-header:visible').height() || 0;
            var scrollTop = topicDiv.position().top - 5;
            if (animate) {
                $('ip-topics div[name="topics"].main-content-scrollable').stop().animate({
                    scrollTop: scrollTop
                }, 100);
            } else {
                setTimeout(function() {
                    $('ip-topics div[name="topics"].main-content-scrollable').scrollTop(scrollTop - scrollFixedTop);
                }, 100);
            }

            focusService.autofocus(topicDiv);
        }

        function isParentState(state1, state2) {
            if (state1.name.length >= state2.name.length) {
                return false;
            }

            return state2.name.substring(0, state1.name.length) === state1.name;
        }
    });