describe('ModalNavComponent', function() {

    var controller, notificationService;

    beforeEach(function() {
        module('inprotech.components.modal')
        module(function() {
            notificationService = test.mock('notificationService');
        });
    });

    beforeEach(inject(function($componentController) {
        controller = function(bindings) {
            return $componentController('ipModalNav', null, _.extend({
                notificationService: notificationService
            }, bindings));
        };
    }));

    it('initialises button status, current index and total number', function() {
        var current = 'b';
        var all = ['a', current, 'c'];
        var c = controller({
            allItems: all,
            currentItem: current
        });
        c.$onInit();

        expect(c.isFirstDisabled).toBe(false);
        expect(c.isPrevDisabled).toBe(false);
        expect(c.isNextDisabled).toBe(false);
        expect(c.isLastDisabled).toBe(false);
        expect(c.totalCount).toBe(3);
        expect(c.currentIndex).toBe(2);
    });

    describe('navigation', function() {
        var ctr, onNavigate;
        beforeEach(function() {
            onNavigate = jasmine.createSpy();
            var current = 'b';
            var all = ['a', current, 'c'];
            ctr = controller({
                allItems: all,
                currentItem: current,
                onNavigate: onNavigate
            });
            ctr.$onInit();
        });

        it('navigates to first item', function() {
            ctr.first();
            expect(onNavigate).toHaveBeenCalledWith('a');
        });

        it('navigates to previous item', function() {
            ctr.prev();
            expect(onNavigate).toHaveBeenCalledWith('a');
        });

        it('navigates to next item', function() {
            ctr.next();
            expect(onNavigate).toHaveBeenCalledWith('c');
        });

        it('navigates to last item', function() {
            ctr.last();
            expect(onNavigate).toHaveBeenCalledWith('c');
        });
    });
});
