describe('Inprotech.SchemaMapping.schemaNode', function() {
    'use strict';

    var _http, _node, _docItems, _docItemColumns, _init, _parent, _schema;

    beforeEach(module('Inprotech.SchemaMapping'));

    beforeEach(inject(function($httpBackend, schemaNode, schemaHelper) {
        _schema = {
            structure: {
                id: '0',
                children: [{
                    id: '1',
                    parentId: '0',
                    name: 'n1',
                    nodeType: 'element',
                    minOccurs: 1,
                    typeName: 't1'
                }]
            },
            types: [{
                name: 't1',
                canHaveValue: true,
                unionTypes: ['token']
            }, {
                name: 'token',
                canHaveValue: true,
                dataType: 'token'
            }]
        };

        schemaHelper.init(_schema);

        var scope = {
            model: {
                docItems: {
                    '0': {
                        columns: ['0']
                    },
                    '1': {
                        columns: ['1']
                    }
                },
                docItemColumns: {},
                selectedUnionTypes: { '1': 'token' }
            }
        };

        _parent = _schema.structure;

        var node = _parent.children[0];

        _http = $httpBackend;
        _docItems = scope.model.docItems;
        _docItemColumns = scope.model.docItemColumns;

        _init = function() {
            _node = schemaNode(scope, _schema, node);
        };

        _init();
    }));

    afterEach(function() {
        _http.verifyNoOutstandingExpectation();
        _http.verifyNoOutstandingRequest();
    });

    describe('initialisation', function() {
        it('should set isRequired for element', function() {
            _node.node.nodeType = 'element';
            _node.node.minOccurs = 1;

            _init();

            expect(_node.isRequired).toBe(true);
        });

        it('should set isRequired for attribute', function() {
            _node.node.nodeType = 'attribute';
            _node.node.use = 'isRequire';

            expect(_node.isRequired).toBe(true);
        });
    });

    describe('doc item', function() {
        var response = {
            id: '1',
            columns: [{
                name: 'c1',
                type: 't1'
            }]
        };

        beforeEach(function() {
            _http.whenGET('api/schemamapping/docItem?id=1').respond(200, response);
            _node.docItem('1');
            _http.flush();
        });

        it('should be able to fetch doc item', function() {
            expect(_docItems['1'].id).toBe('1');
        });

        it('should initialise node id', function() {
            expect(_docItems['1'].columns[0].nodeId).toBe('1');
        });

        it('should initialise doc item id', function() {
            expect(_docItems['1'].columns[0].docItemId).toBe('1');
        });

        it('should select doc item column when single result and can have content', function() {
            expect(_docItemColumns['1'].name).toBe('c1');
        });
    });

    describe('bound doc item column', function() {
        it('should return all available columns', function() {
            var columns = _node.docItemColumns();

            expect(columns[0]).toBe('1');
            expect(columns[1]).toBe('0');
        });
    });

    describe('updating dirty flags', function() {
        beforeEach(function() {
            _schema.dirty = false;
        });

        it('should set dirty flag', function() {
            _node.setDirty();

            expect(_schema.dirty).toBe(true);
        });
    });
});