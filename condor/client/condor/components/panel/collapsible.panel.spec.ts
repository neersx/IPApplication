describe('inprotech.components.panel.collapsiblePanel', () => {
    'use strict';

    let controller: CollapsiblePanelController;

    beforeEach(() => {
        angular.mock.module('inprotech.components.panel');
    });

    beforeEach(function() {
         controller = new CollapsiblePanelController();
    });

    it('should toggle pinned value', () => {
        controller.pinned = true;
        controller.togglePinned();
        expect(controller.pinned).toBeFalsy();
    });
});
