describe('Inprotech.SchemaMapping.docItemHelper', function() {
    'use strict';

    var _docItemHelper;

    beforeEach(module('Inprotech.SchemaMapping'));

    beforeEach(inject(['docItemHelper', function(docItemHelper) {
        _docItemHelper = docItemHelper;
    }]));

    it('should initialise doc item columns', function() {
        var column = {
            name: 'column',
            type: 'type'
        };

        _docItemHelper.initColumns({ id: 1, code: 'docitem', columns: [column] }, { id: 1, name: 'node' });

        expect(column.nodeId).toBe(1);
        expect(column.docItemId).toBe(1);
        expect(column.group).toBe('node - docitem');
        expect(column.label).toBe('column (type)');
    });
});