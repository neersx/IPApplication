namespace inprotech.portfolio.cases {
    export interface IEfilingPreview {
        preview(response: any): void;
    }

    export class EfilingPreview implements IEfilingPreview {
        constructor(public $window: ng.IWindowService) {}
        public preview = (response: any) => {
            let headers = response.headers();
            let contentType = headers['content-type'];
            let fileType = headers['x-filetype'];
            let urlCreator = this.$window.URL;
            let blob = new Blob([response.data], {
                type: contentType
            });
            let url = urlCreator.createObjectURL(blob);
            let fileName = headers['x-filename'];
            if (this.$window.navigator && this.$window.navigator.msSaveOrOpenBlob) {
                this.$window.navigator.msSaveOrOpenBlob(blob, fileName);
            } else {
                if (_.contains(['zip', 'mpx', ''], fileType.toLowerCase())) {
                    let anchor = this.$window.document.createElement('a');
                    anchor.download = fileName;
                    anchor.href = url;
                    anchor.click();
                } else {
                    this.$window.open(url);
                }
            }
        };
    }
    angular
        .module('inprotech.portfolio.cases')
        .service('eFilingPreview', ['$window', EfilingPreview]);
}