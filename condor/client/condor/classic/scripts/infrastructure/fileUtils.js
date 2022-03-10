angular
    .module('Inprotech.Infrastructure')
    .factory('fileUtils', [function() {
        'use strict';

        return {
            isValidSchemaFileName: function(filename) {
                return /.*\.xsd|dtd$/gi.test(filename);
            },
            isValidXsdFileName: function(filename) {
                return /.*\.xsd$/gi.test(filename);
            },

            isValidXsdContent: function(content) {
                var parser = new DOMParser();

                try {
                    var xml = parser.parseFromString(content, 'application/xml');
                    var schamaText = ':schema';
                    return _.any(xml.childNodes, function(item) {
                        return item.nodeName.indexOf(schamaText, item.nodeName.length - schamaText.length) !== -1;
                    });
                } catch (e) {
                    return false;
                }


            }
        };
    }]);