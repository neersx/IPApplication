module inprotech.portfolio.cases {
    export class CaseImageController {
        static $inject: string[] = ['$scope', '$window', 'CaseImageService', 'modalService'];
        public vm: CaseImageController;
        public imageKey: number;
        public maxWidth?: number;
        public maxHeight?: number;
        public isThumbnail: boolean;
        public isClickable: boolean;
        public tooltipOptions: any;
        private tooltipWidth: number;
        private tooltipHeight: number;
        public image: any;
        public tooltipInstance: any;
        public isFullImage: boolean;
        public imageTitle: string;
        public imageDesc: string;
        public caseKey: number

        constructor(private $scope: ng.IScope, private $window: ng.IWindowService, private caseImageService: ICaseImageService, private modalService) {
        }

        $onInit() {
            this.vm = this;

            this.$scope.$watch('vm.imageKey', () => {
                this.loadImage();
            });
        }

        private loadImage() {
            if (!this.isThumbnail && !this.isFullImage) {
                this.maxWidth = this.$window.innerWidth - 40;
                this.maxHeight = this.$window.innerHeight - 40;
            }
            this.caseImageService.getImage(this.imageKey, this.caseKey, this.maxWidth, this.maxHeight)
                .then((data) => {
                    this.image = data.image;

                    if (this.isThumbnail && !this.isClickable) {
                        // pre-calculate the dimensions so kendo can adjust the placement
                        this.tooltipHeight = data.originalHeight + 10;
                        this.tooltipWidth = data.originalWidth + 10;
                        if (data.originalHeight > this.$window.innerHeight) {
                            this.tooltipHeight = this.$window.innerHeight - 30;
                            this.tooltipWidth = (data.originalWidth * this.tooltipHeight / data.originalHeight);
                        }
                        if (this.tooltipWidth > this.$window.innerWidth) {
                            this.tooltipWidth = this.$window.innerWidth - 30;
                            this.tooltipHeight = (data.originalHeight * this.tooltipWidth / data.originalWidth);
                        }

                        this.tooltipOptions = {
                            position: 'left', width: this.tooltipWidth, height: this.tooltipHeight,
                            show: this.onShow,
                            content: '<ip-case-image data-image-key="vm.imageKey" data-case-key="vm.caseKey"  data-is-thumbnail="false">'
                        };
                    }
                });
        }

        private onShow(e) {
            // typescript thinks 'this' is the controller, but this method is called in the tooltip's scope.
            let that: any = this;
            let parentVm = that.$angular_scope.$parent.vm;
            parentVm.tooltipInstance = e.sender.popup.wrapper;
        }

        public mouseOff() {
            // hack to fix an issue with IE not triggering kendo's mouse off
            if (this.tooltipInstance) {
                this.tooltipInstance.hide();
            }
        }

        public mouseClick() {
            this.modalService.openModal({
                id: 'CaseImageFull',
                controllerAs: 'vm',
                bindToController: true,
                imageKey: this.imageKey,
                imageTitle: this.imageTitle,
                imageDesc: this.imageDesc,
                caseKey: this.caseKey,
                type: 'case'
            });
        }
    }

    angular.module('inprotech.portfolio.cases')
        .component('ipCaseImage', {
            templateUrl: 'condor/portfolio/cases/case-image.html',
            controllerAs: 'vm',
            bindings: {
                imageKey: '<',
                maxWidth: '<',
                maxHeight: '<',
                isThumbnail: '<',
                isResponsive: '<',
                isClickable: '<',
                isFullImage: '<',
                imageTitle: '<',
                imageDesc: '<',
                caseKey: '<'
            },
            controller: CaseImageController
        });
}