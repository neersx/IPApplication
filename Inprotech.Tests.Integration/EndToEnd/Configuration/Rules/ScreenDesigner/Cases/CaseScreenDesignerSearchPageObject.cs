using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.ScreenDesigner.Cases
{
    class CaseScreenDesignerSearchPageObject : PageObject
    {
        public CaseScreenDesignerSearchPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement ResetButton => Driver.FindElement(By.XPath("//ipx-search-by-characteristic//span[@class='cpa-icon cpa-icon-eraser']"));
        public NgWebElement SubmitButton => Driver.FindElement(By.XPath("//ipx-search-by-characteristic//span[@class='cpa-icon cpa-icon-search']"));
        public NgWebElement SubmitButtonCriteria => Driver.FindElements(By.XPath("//button/span[@class='cpa-icon cpa-icon-search']/..")).SingleOrDefault(_=>_.Displayed);
        public IpxRadioButton CharacteristicsRadioButton => new IpxRadioButton(Driver).ByValue("characteristic");
        public IpxRadioButton CaseRadioButton => new IpxRadioButton(Driver).ByValue("case");
        public IpxRadioButton CriteriaRadioButton => new IpxRadioButton(Driver).ByValue("criteria");
        public AngularCheckbox ProtectedCriteria => new AngularCheckbox(Driver).ByName("protectedCriteria");
        public AngularCheckbox CriteriaNotInUse => new AngularCheckbox(Driver).ByName("criteriaNotInUse");
        public bool PageIsShown => Driver.FindElements(By.CssSelector("ipx-page-title")).Any();
        public AngularPicklist Criteria => new AngularPicklist(Driver).ByName("criteria");
        public AngularPicklist Case => new AngularPicklist(Driver).ByName("case");
        public ScreenDesignerPicklistSection Characteristics => new ScreenDesignerPicklistSection(Driver, "ipx-search-by-characteristic");
        public ScreenDesignerPicklistSection Cases => new ScreenDesignerPicklistSection(Driver, "ipx-search-by-case");
        public class ScreenDesignerPicklistSection
        {
            string componentName;
            public ScreenDesignerPicklistSection(NgWebDriver driver, string componentName)
            {
                Driver = driver;
                this.componentName = componentName;
            }

            public NgWebDriver Driver { get; set; }

            public AngularPicklist Office => new AngularPicklist(Driver).ByName(componentName, "office");
            public AngularPicklist Program => new AngularPicklist(Driver).ByName(componentName, "program");

            public AngularPicklist CaseType => new AngularPicklist(Driver).ByName(componentName, "caseType");
            public AngularPicklist Jurisdiction => new AngularPicklist(Driver).ByName(componentName, "jurisdiction");
            public AngularPicklist PropertyType => new AngularPicklist(Driver).ByName(componentName, "propertyType");
            public AngularPicklist CaseCategory => new AngularPicklist(Driver).ByName(componentName, "caseCategory");
            public AngularPicklist SubType => new AngularPicklist(Driver).ByName(componentName, "subType");
            public AngularPicklist Basis => new AngularPicklist(Driver).ByName(componentName, "basis");
            public AngularPicklist Profile => new AngularPicklist(Driver).ByName(componentName, "profile");
        }

        public AngularKendoGrid Grid => new AngularKendoGrid(Driver, "searchResults");
    }
}
