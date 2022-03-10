using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows
{
    class WorkflowCharacteristicsPage : PageObject
    {
        readonly string _section;

        public WorkflowCharacteristicsPage(NgWebDriver driver, string section) : base(driver)
        {
            _section = section;
        }

        public PickList CasePl => new PickList(Driver).ByName(_section, "case");

        public PickList CaseTypePl => new PickList(Driver).ByName(_section, "caseType");
        public PickList JurisdictionPl => new PickList(Driver).ByName(_section, "jurisdiction");
        public PickList PropertyTypePl => new PickList(Driver).ByName(_section, "propertyType");
        public PickList ActionPl => new PickList(Driver).ByName(_section, "action");
        public PickList DateOfLawPl => new PickList(Driver).ByName(_section, "dateOfLaw");
        public PickList CaseCategoryPl => new PickList(Driver).ByName(_section, "caseCategory");
        public PickList SubTypePl => new PickList(Driver).ByName(_section, "subType");
        public PickList BasisPl => new PickList(Driver).ByName(_section, "basis");
        public PickList OfficePl => new PickList(Driver).ByName(_section, "office");
        public PickList ExaminationPl => new PickList(Driver).ByName(_section, "examinationType");
        public PickList RenewalPl => new PickList(Driver).ByName(_section, "renewalType");

        public DropDown LocalOrForeign => new DropDown(Driver, Driver.FindElement(By.TagName("ip-search-by-case"))).ByLabel("workflows.common.localOrForeignDropdown.label");
    }
}
