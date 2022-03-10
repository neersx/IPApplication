angular.module('inprotech.components.topics')
    .directive('ipTopicContent', function($compile, utils) {
        'use strict';

        return {
            restrict: 'E',
            scope: true,
            link: function(scope, element) {

                var topic = scope.subTopic || scope.topic;

                if (topic.template) {
                    var childScope = scope.$new(true);
                    childScope.$topic = topic;
                    //childScope.$formData = topic.formData;
                    //extend childScope with scope.topic.params	
                    var elm = $compile(topic.template)(childScope);

                    element.append(elm);
                }

                setTimeout(function() {
                    if (topic) {
                        var el = element.find('input,textarea,select');
                        el.focus(function() {
                            utils.safeApply(scope);
                            scope.selectTopic(topic, false);
                        });
                    }
                }, 2000);
            }
        };
    });