namespace inprotech.configuration.notification {
    class IeRequiredController implements ng.IController {
        transalationPrefix = 'modal.iePopup.';
        copyStatus: string;
        copySupported: boolean;
        constructor(public options, private $uibModalInstance, private $timeout, private clipboard) {
            this.copyStatus = this.transalationPrefix + 'copy';
            this.copySupported = clipboard.supported;
        }
        cancel = () => {
            this.$timeout(() => {
                this.$uibModalInstance.dismiss('Cancel');
            }, 0);
        }

        copyUrl = () => {
            if (!this.copySupported) {
                return;
            }
            this.clipboard.copyText(this.options.url);
            this.copyStatus = this.transalationPrefix + 'copied';

            this.$timeout(() => {
                this.copyStatus = this.transalationPrefix + 'copy';
            }, 5000);
        }
    }

    angular.module('inprotech.components.notification').controller('IeRequiredController', ['options', '$uibModalInstance', '$timeout', 'clipboard', IeRequiredController])
}

