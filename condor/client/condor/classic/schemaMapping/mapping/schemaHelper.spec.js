describe('Inprotech.SchemaMapping.schemaHelper', function() {
    'use strict';

    var _schemaHelper, _schema, _element, _attribute, _root;

    beforeEach(module('Inprotech.SchemaMapping'));

    beforeEach(inject(['schemaHelper', function(schemaHelper) {
        _schemaHelper = schemaHelper;
        _schema = {
            structure: {
                nodeType: 'element',
                name: 'n1',
                typeName: 't1',
                minOccurs: '1',
                maxOccurs: '1',
                id: 1,
                parentId: null,
                children: [{
                    nodeType: 'element',
                    name: 'n2',
                    typeName: 't3',
                    minOccurs: '1',
                    maxOccurs: '1',
                    id: 2,
                    parentId: 1
                }, {
                    nodeType: 'attribute',
                    name: 'a1',
                    typeName: 't2',
                    use: 'Required',
                    id: 3,
                    parentId: 1
                }, {
                    nodeType: 'element',
                    name: 'n3',
                    typeName: 't4',
                    id: 4,
                    parentId: 1
                }]
            },
            types: [{
                name: 't1',
                dataType: 'Token'
            }, {
                name: 't2',
                dataType: 'Integer',
                restrictions: {
                    enumerations: ['e1']
                }
            }, {
                name: 't3',
                unionTypes: ['t1', 't2']
            }, {
                name: 't4',
                dataType: 'String'
            }]
        };

        _root = _element = _schema.structure;
        _attribute = _element.children[1];

        _schemaHelper.init(_schema);
    }]));

    describe('schema initialisation', function() {
        it('should convert types to lookup', function() {
            expect(_schema.types.t1.dataType).toBe('Token');
            expect(_schema.types.t2.dataType).toBe('Integer');
        });

        it('should initialise inputTypes', function() {
            expect(_schema.types.t1.inputType).toBe('text');
            expect(_schema.types.t2.inputType).toBe('list');
        });

        it('should collect all nodes', function() {
            expect(_schema.nodes.length).toBe(4);
        });

        it('should be able to find node by id', function() {
            expect(_schema.node(1)).toBe(_schema.structure);
        });
    });

    describe('extensions', function() {
        it('should add finding node method', function() {
            expect(_schema.node(1).name).toBe('n1');
        });

        it('should add finding path method', function() {
            expect(_schema.path(_schema.node(1))[0].name).toBe('n1');
            expect(_schema.path(1)[0].name).toBe('n1');
        });

        it('should add finding type method', function() {
            expect(_schema.type('t1').name).toBe('t1');
        });
    });

    describe('tree traversal', function() {
        it('should find path from root to current node', function() {
            var path = _schema.path(_attribute);

            expect(path[0]).toBe(_root);
            expect(path[1]).toBe(_attribute);
        });

        it('should set required flag for required nodes', function() {
            expect(_schema.structure.isRequired).toBeTruthy();
            expect(_schema.structure.children[0].isRequired).toBeTruthy();
            expect(_schema.structure.children[1].isRequired).toBeTruthy();
            expect(_schema.structure.children[2].isRequired).toBeFalsy();
        });
    });
});