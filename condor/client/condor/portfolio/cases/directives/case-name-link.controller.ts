namespace inprotech.portfolio.cases {
  export class CaseNameLinkController {
    static $inject: string[] = ['caseviewNamesService'];
    public name: string;
    public nameCode: string;
    public nameKey: string;
    public caseKey: number;
    public nameType: string;
    public showCode: string;
    public showEmailLink: boolean;
    public email: inprotech.components.form.EmailTemplate;
    public vm: CaseNameLinkController;

    constructor(private service: ICaseviewNamesService) {
      this.vm = this;
     }

    $onInit() {
      if (this.showEmailLink) {
        this.service.getFirstEmailTemplate(this.caseKey, this.nameType)
                    .then((emailTemplate: inprotech.components.form.EmailTemplate) => {
                        this.email = emailTemplate;
                    });
      }
    }

    encodeLinkData = (data) => {
      return 'api/search/redirect?linkData=' + encodeURIComponent(JSON.stringify({ namekey: data }));
    };

    linkText = () => {
      if (this.vm.showCode === 'first') {
        return (this.vm.nameCode ? '{' + this.vm.nameCode + '} ' : '') + this.vm.name;
      }

      if (this.vm.showCode === 'last') {
        return this.vm.name + (this.vm.nameCode ? ' {' + this.vm.nameCode + '}' : '');
      }

      return this.vm.name;
    };
  }

  angular
    .module('inprotech.portfolio.cases')
    .component('ipCaseNameLink', {
      controllerAs: 'vm',
      bindings: {
        name: '<',
        nameCode: '<',
        nameKey: '<',
        canLink: '<',
        showEmailLink: '<',
        caseKey: '<',
        nameType: '<',
        showCode: '<'
      },
      templateUrl: 'condor/portfolio/cases/directives/case-name-link.html',
      controller: CaseNameLinkController
    });
}
