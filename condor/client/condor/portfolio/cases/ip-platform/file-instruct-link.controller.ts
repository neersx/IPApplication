namespace inprotech.portfolio.cases {
    export class FileInstructResponse {
        public progressUri: string;
        public errorDescription: string;
    }

    export class FileInstructLinkController {
        static $inject = ['$http', 'notificationService', '$window'];
        public caseKey: string;
        public isFiled: Boolean;
        public canAccess: Boolean;
        public showLink: Boolean;
        public showIconOnly: Boolean;
        public vm: FileInstructLinkController;

        constructor(private $http, private notificationService, private $window) {
        }

        $onInit() {
            this.vm = this;
            this.init();
        }

        link = () => {
            return this.$http.put('api/ip-platform/file/view-filing-instruction?caseKey=' + this.caseKey)
                .then((response) => {
                    let r = <FileInstructResponse> response.data.result;
                    if (r.progressUri) {
                        return this.$window.open(r.progressUri, '_blank');
                    }

                    return this.notificationService.alert({
                        title: 'modal.unableToComplete',
                        message: r.errorDescription
                    });
                });
        };

        init = () => {
            this.vm.showLink = this.vm.isFiled && this.vm.canAccess;
            this.vm.showIconOnly = this.vm.isFiled && !this.vm.canAccess;
        }
    }

    angular
        .module('inprotech.portfolio.cases')
        .component('ipFileInstructLink', {
            controllerAs: 'vm',
            bindings: {
                caseKey: '<',
                isFiled: '<',
                canAccess: '<'
            },
            templateUrl: 'condor/portfolio/cases/ip-platform/file-instruct-link.html',
            transclude: true,
            controller: FileInstructLinkController
        });
}