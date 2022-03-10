/*eslint no-unused-vars: 0*/
describe('Inprotech.SchemaMapping.mappingController', function() {
    'use strict';

    var _scope, _controller, _initView, _timeout, _schemaHelper, _q;

    var _testSchema = {
        structure: {
            name: 'parent',
            id: 'parentid',
            children: [{
                name: 'child1',
                id: 'childid1',
                children: []
            }, {
                name: 'child2',
                id: 'childid2',
                children: [{
                    name: 'grandchild1',
                    id: 'grandchild1',
                    children: []
                }]
            }]
        },
        types: [{
            dataType: 'String',
            name: 'String'
        }]
    };

    var _persistence = {
        save: function() {
            return {
                then: function() {}
            }
        },
        init: function() {}
    };

    var initController = function(additionalData) {
        var data = _.extend({}, {
            id: '1',
            name: 'ohim',
            isDtdFile: false,
            fileRef: null,
            schema: _testSchema
        }, additionalData);
        _controller('mappingController', {
            '$scope': _scope,
            'persistence': _persistence,
            'viewInitialiser': {
                data: data
            }
        });
    };

    beforeEach(module('Inprotech.SchemaMapping'));

    beforeEach(inject(['$rootScope', '$controller', '$timeout', 'schemaHelper', '$q', function($rootScope, $controller, $timeout, schemaHelper, $q) {
        _q = $q;
        _timeout = $timeout;
        _schemaHelper = schemaHelper;

        _scope = $rootScope.$new();

        _scope.model = {
            fixedValues: {},
            docItems: {},
            docItemColumns: {}
        };

        _initView = _testSchema;

        _controller = $controller;

        initController();
    }]));

    describe('initialisation', function() {
        describe('scope initialisation', function() {
            it('should initialise expandedNodes to empty', function() {
                expect(_scope.expandedNodes).toEqual([]);
            });

            it('should not set selectedNode', function() {
                expect(_scope.selectedNode).not.toBeDefined();
            });

            it('should expand all nodes after timeout', function() {
                _timeout.flush();
                expect(_scope.expandedNodes.length).toBe(4);
            });
        });

        describe('schema retrieval', function() {
            it('should set structure to the schema', function() {
                expect(_scope.structure).toEqual([_testSchema.structure]);
            });
        });

        it('should set mapping name', function() {
            expect(_scope.mappingInfo.name).toBe('ohim');
        });
    });

    describe('node equality function', function() {
        it('should be true for nodes with equal ids', function() {
            var nodeb = {
                id: 'ida'
            };
            var nodea = {
                id: 'ida'
            };

            expect(nodea === nodeb).toBe(false);
            expect(_scope.opts.equality(nodea, nodeb)).toBe(true);
        });

        it('should be false for nodes without equal ids', function() {
            var nodea = {
                id: 'ida'
            };
            var nodeb = {
                id: 'idb'
            };

            expect(_scope.opts.equality(nodea, nodeb)).toBe(false);
        });

        it('should be false for a node that is undefined', function() {
            expect(_scope.opts.equality(undefined, {
                id: 'a'
            })).toBe(false);
            expect(_scope.opts.equality({
                id: 'a'
            }, undefined)).toBe(false);
        });

        it('should be false for a node without an id property', function() {
            expect(_scope.opts.equality({
                id: 'a'
            }, {})).toBe(false);
        });
    });

    describe('current node', function() {
        it('should be set when showDetails called with a node', function() {
            var node = {
                id: 'a',
                name: 'nodea',
                type: 'String'
            };
            _scope.showDetails(node);
            expect(_scope.current.node).toBe(node);
        });
    });

    describe('saving', function() {
        it('should call component for persistence', function() {
            spyOn(_persistence, 'save').and.returnValue(_q.when({}));

            _scope.save({ form: { $invalid: false } });

            expect(_persistence.save).toHaveBeenCalledWith('1', 'ohim', { isDtdFile: false, fileRef: null });
        });
    });

    describe('isMapped', function() {
        it('should be true if default value is available', function() {
            _scope.model.fixedValues[_testSchema.structure.id] = 'value';

            expect(_scope.isMapped(_testSchema.structure)).toBeTruthy();
        });

        it('should be true if doc item column is available', function() {
            _scope.model.docItems[_testSchema.structure.id] = 'value';
            _scope.model.docItemColumns[_testSchema.structure.id] = 'value';

            expect(_scope.isMapped(_testSchema.structure)).toBeTruthy();
        });

        it('should be false if nothing mapped', function() {
            _scope.model.fixedValues[_testSchema.structure.id] = undefined;
            _scope.model.docItemColumns[_testSchema.structure.id] = undefined;

            expect(_scope.isMapped(_testSchema.structure)).toBeFalsy();
        });
    });

    describe('node expansion', function() {
        it('should expand all if nodes are less then 500', function() {
            _schemaHelper.init(_testSchema);
            _scope.expandAll();
            _timeout.flush(100);
            expect(_scope.expandedNodes).toEqual(_testSchema.nodes);
        });

        describe('more then 500 nodes', function() {

            beforeEach(function() {
                var childern500 = [];
                for (var i = 0; i < 500; i++) {
                    childern500.push({
                        name: 'node' + i,
                        id: 'node' + i,
                        parentId: 'grandchild1',
                        children: []
                    });
                }

                _testSchema = {
                    structure: {
                        name: 'parent',
                        id: 'parentid',
                        children: [{
                            name: 'child1',
                            id: 'childid1',
                            parentId: 'parentid',
                            children: []
                        }, {
                            name: 'child2',
                            id: 'childid2',
                            parentId: 'parentid',
                            children: [{
                                name: 'grandchild1',
                                id: 'grandchild1',
                                parentId: 'childid2',
                                children: childern500
                            }]
                        }]
                    },
                    types: [{
                        dataType: 'String',
                        name: 'String'
                    }]
                };

                initController();
                _schemaHelper.init(_testSchema);
            });

            it('should expand only first node if nothing is mapped', function() {
                _scope.expandAll();
                _timeout.flush(100);
                expect(_scope.expandedNodes.length).toEqual(1);
                expect(_scope.expandedNodes[0].id).toEqual(_testSchema.nodes[0].id);
            });

            it('should expand mapped nodes by default', function() {
                _scope.model.docItemColumns = {
                    'node0': 'docItemValue'
                };
                _scope.model.fixedValues = {
                    'node1': 'fixedValue'
                };
                _scope.expandAll();
                _timeout.flush(100);
                var ids = _.pluck(_scope.expandedNodes, 'id');
                expect(_scope.expandedNodes.length).toEqual(5);
                expect(ids).toEqual(['parentid', 'node0', 'grandchild1', 'childid2', 'node1']);
            });

        });
    });

    describe('dtd specific data saving', function() {
        beforeEach(function() {
            initController({ isDtdFile: true, fileName: 'dtdPackageFileName.dtd' });
        });

        it('saves fileRef if selected', function() {
            spyOn(_persistence, 'save').and.returnValue(_q.when({}));

            _scope.mappingInfo.shouldAddDocType = true;
            _scope.save({ form: { $invalid: false } });

            expect(_persistence.save).toHaveBeenCalledWith('1', 'ohim', { isDtdFile: true, fileRef: 'dtdPackageFileName.dtd' });
        });
    });
});