module inprotech.portfolio.cases {
    export class CaseImageFullController {
        static $inject = ['$uibModalInstance', 'options'];
        imageKey: any;
        imageTitle: string;
        imageDesc: string;
        titleLimit: number;
        caseKey: number;
        public vm: CaseImageFullController;

        constructor(private $uibModalInstance, private options) {
            this.vm = this;
            this.vm.imageKey = this.options.imageKey;
            this.vm.imageTitle = this.options.imageTitle;
            this.vm.imageDesc = this.options.imageDesc;
            this.vm.caseKey = this.options.caseKey;
            this.vm.titleLimit = 80;
        }

        public close() {
            this.$uibModalInstance.close();
        }
    }

    angular.module('inprotech.portfolio.cases')
        .controller('CaseImageFullController', CaseImageFullController);

    angular.module('inprotech.portfolio.cases')
        .run(function (modalService) {
            modalService.register('CaseImageFull', 'CaseImageFullController', 'condor/portfolio/cases/directives/case-image-full.html', {
                windowClass: 'centered',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'xl'
            });
        });
}
