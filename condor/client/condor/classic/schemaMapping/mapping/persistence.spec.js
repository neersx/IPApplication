describe('Inprotech.SchemaMapping.persistence', function() {
    'use strict';

    var _notification, _scope, _http, _schema, _mappingEntries, _docItemDetails, _nodes, _persistence;

    beforeEach(function() {
        _nodes = [{
            id: 'n1',
            name: 'test',
            typeName: 'string'
        }, {
            id: 'n3',
            name: 'doc item error',
            typeName: 'string'
        }];

        _notification = {
            success: function() {},
            alert: function() {}
        };

        spyOn(_notification, 'success');
        spyOn(_notification, 'alert');

        _schema = {
            node: function(id) {
                return _.find(_nodes, function(n) { return n.id === id; });
            },

            type: function() {
                return { canHaveValue: true };
            },

            nodes: _nodes
        };

        _docItemDetails = {
            'di1': {
                id: 'di1',
                parameters: [{
                    index: 0,
                    name: 'p1'
                }, {
                    index: 1,
                    name: 'gstrEntryPoint'
                }],

                columns: [{
                    index: 0,
                    name: 'col1',
                    type: 'string',
                    sql: 'select * from cases'
                }]
            }
        };

        _mappingEntries = {
            'n1': {
                docItem: {
                    id: 'di1',
                    parameters: [{
                        id: 'p1',
                        type: 'fixed',
                        value: 'pVal'
                    }, {
                        id: 'gstrEntryPoint',
                        type: 'global'
                    }]
                },

                selectedUnionType: 'u1',

                fixedValue: 'fixedVal',

                docItemBinding: {
                    nodeId: 'n1',
                    columnId: 0,
                    docItemId: 'di1'
                }
            },

            'n2': {
                fixedValue: 'fixedVal'
            },

            'n3': {
                docItem: {
                    id: 'zz'
                }
            }
        };

        module('Inprotech.SchemaMapping', function($provide) {
            $provide.value('notificationService', _notification);
        });

        inject(function($rootScope, $httpBackend, persistence) {
            _scope = $rootScope.$new();
            _http = $httpBackend;

            _persistence = persistence;
        });

        _persistence.init(_scope, _schema, _mappingEntries, _docItemDetails);
    });

    afterEach(function() {
        _http.verifyNoOutstandingExpectation();
        _http.verifyNoOutstandingRequest();
    });

    describe('saving', function() {
        var _toSave;

        beforeEach(function() {
            _schema.dirty = true;
            _http.whenPUT('api/schemamappings/1').respond(function() {
                _toSave = JSON.parse(arguments[2]);
                return [200, {}, {}];
            });
        });

        it('should set dirty flag to false after success', function() {
            _persistence.save('1', 'ohim', { isDtdFile: false });

            _http.flush();

            expect(_schema.dirty).toBe(false);
        });

        it('should show notification after success', function() {
            _persistence.save('1', 'ohim', { isDtdFile: false });

            _http.flush();

            expect(_notification.success).toHaveBeenCalled();
        });

        it('should not save if node id does not exist', function() {
            _persistence.save('1', 'ohim', { isDtdFile: false });

            _http.flush();

            expect(_toSave.mappings.n2).toBeUndefined();
        });

        it('should build correct saving structure', function() {
            _scope.model.docItems.n1.parameters.push({
                id: 'gstrEntryPoint'
            });

            _persistence.save('1', 'ohim', { isDtdFile: true, fileRef: 'SomeFileRef' });

            _http.flush();

            expect(_toSave.name).toBe('ohim');
            expect(_toSave.fileRef).toBe('SomeFileRef');
            expect(_toSave.mappings.mappingEntries.n1.docItem.id).toBe(_mappingEntries.n1.docItem.id);
            expect(_toSave.mappings.mappingEntries.n1.docItem.parameters[0].id).toBe(_mappingEntries.n1.docItem.parameters[0].id);
            expect(_toSave.mappings.mappingEntries.n1.docItem.parameters[0].type).toBe(_mappingEntries.n1.docItem.parameters[0].type);
            expect(_toSave.mappings.mappingEntries.n1.docItem.parameters[0].value).toBe(_mappingEntries.n1.docItem.parameters[0].value);
            expect(_toSave.mappings.mappingEntries.n1.docItem.parameters[1].id).toBe(_mappingEntries.n1.docItem.parameters[1].id);
            expect(_toSave.mappings.mappingEntries.n1.docItem.parameters[1].type).toBe(_mappingEntries.n1.docItem.parameters[1].type);
            expect(_toSave.mappings.mappingEntries.n1.fixedValue).toBe(_mappingEntries.n1.fixedValue);
            expect(_toSave.mappings.mappingEntries.n1.selectedUnionType).toBe(_mappingEntries.n1.selectedUnionType);
            expect(_toSave.mappings.mappingEntries.n1.docItemBinding.nodeId).toBe(_mappingEntries.n1.docItemBinding.nodeId);
            expect(_toSave.mappings.mappingEntries.n1.docItemBinding.columnId).toBe(_mappingEntries.n1.docItemBinding.columnId);
            expect(_toSave.mappings.mappingEntries.n1.docItemBinding.docItemId).toBe(_mappingEntries.n1.docItemBinding.docItemId);
        });
    });

    describe('initialisation', function() {
        it('for fixed values', function() {
            expect(_scope.model.fixedValues.n1).toBe('fixedVal');
        });

        it('for doc items', function() {
            var param = _scope.model.docItems.n1.parameters[0];

            expect(param.name).toBe('p1');
            expect(param.value).toBe('pVal');
        });

        it('for doc item errors', function() {
            var error = _scope.model.docItems.n3.error;

            expect(error).toBe('NotFound');
        });

        it('for bound columns', function() {
            var column = _scope.model.docItemColumns.n1;

            expect(column.name).toBe('col1');
            expect(column.nodeId).toBe('n1');
        });

        it('for selected union types', function() {
            expect(_scope.model.selectedUnionTypes.n1).toBe('u1');
        });
    });
});