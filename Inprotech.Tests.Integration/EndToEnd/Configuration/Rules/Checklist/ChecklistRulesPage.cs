using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Checklist
{
    class ChecklistRulesPage : PageObject
    {
        readonly NgWebElement _container;
        readonly string _section;
        public ChecklistRulesPage(NgWebDriver driver, string section) : base(driver)
        {
            _section = section;
            _container = driver.FindElement(By.TagName(section));
        }
        public AngularPicklist CasePl => new AngularPicklist(Driver, _container).ByName("case");
        public AngularPicklist CaseTypePl => new AngularPicklist(Driver, _container).ByName("caseType");
        public AngularPicklist JurisdictionPl => new AngularPicklist(Driver, _container).ByName("jurisdiction");
        public AngularPicklist PropertyTypePl => new AngularPicklist(Driver, _container).ByName("propertyType");
        public AngularPicklist ChecklistPl => new AngularPicklist(Driver, _container).ByName("checklist");
        public NgWebElement SubmitButton => Driver.FindElements(By.XPath("//button/span[@class='cpa-icon cpa-icon-search']/..")).SingleOrDefault(_=>_.Displayed);
        public AngularKendoGrid Grid => new AngularKendoGrid(Driver, "searchResults");
        public IpxRadioButton BestMatchOption => new IpxRadioButton(Driver, _container).ByValue("characteristics-best-match");
        public IpxRadioButton BestCriteriaOption => new IpxRadioButton(Driver, _container).ByValue("best-criteria-only");
        public IpxRadioButton ExactMatchOption => new IpxRadioButton(Driver, _container).ByValue("exact-match");
        public AngularPicklist Criteria => new AngularPicklist(Driver, _container).ByName("criteria");
        public AngularPicklist Question => new AngularPicklist(Driver, _container).ByName("question");
        public NgWebElement AddButton => Driver.FindElement(By.Id("add"));
    }

    class ChecklistSearchOptions : PageObject
    {
        public ChecklistSearchOptions(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }
        public IpxRadioButton CaseSearchOption => new IpxRadioButton(Driver).ByValue("case");
        public IpxRadioButton CriteriaSearchOption => new IpxRadioButton(Driver).ByValue("criteria");
        public IpxRadioButton QuestionSearchOption => new IpxRadioButton(Driver).ByValue("question");
    }
}
