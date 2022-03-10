angular.module('inprotech.portfolio.cases', [
    'inprotech.core',
    'inprotech.api',
    'inprotech.components'
]).run(['modalService', function (modalService) {
    modalService.register('CaseTextHistory', 'CaseTextHistoryController', 'condor/portfolio/cases/texts/case-text-history.html', {
        windowClass: 'centered picklist-window',
        backdropClass: 'centered',
        backdrop: 'static',
        size: 'lg'
    });
}]);
