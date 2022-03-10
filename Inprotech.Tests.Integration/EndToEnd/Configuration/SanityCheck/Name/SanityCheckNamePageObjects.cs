using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.SanityCheck.Name
{
    public class NameSearch : SanityCheckBaseSearchPageObject
    {
        readonly NgWebDriver _driver;
        readonly NgWebElement _container;

        public NameSearch(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            _driver = driver;
            _container = container;
        }

        public AngularCheckbox Individual => new AngularCheckbox(_driver).ByName("individual");

        public AngularCheckbox Staff => new AngularCheckbox(_driver).ByName("staff");

        public NameSanityCheckGrid SanityCheckGrid => new(Driver);
    }

    public class NameSanityCheckGrid : AngularKendoGrid
    {
        const string ExcludeIcon = "ipx-icon span.cpa-icon.cpa-icon-minus-circle";

        public NameSanityCheckGrid(NgWebDriver driver) : base(driver, "sanityChecksName")
        {
        }

        public NgWebElement AddButton => Grid.FindElement(By.CssSelector("ipx-add-button button"));

        public void Edit(int rowIndex)
        {
            var ruleDescriptionColumn = RuleDescriptionColumn(rowIndex);
            ruleDescriptionColumn.FindElement(By.TagName("a"))?.Click();
        }

        public NgWebElement RuleDescriptionColumn(int rowIndex)
        {
            return Cell(rowIndex, "Rule Description");
        }

        public NgWebElement NameGroupColumn(int rowIndex)
        {
            return Cell(rowIndex, "Name Group");
        }

        public NgWebElement NameColumn(int rowIndex)
        {
            return Cell(rowIndex, "Name");
        }

        public NgWebElement JurisdictionColumn(int rowIndex)
        {
            return Cell(rowIndex, "Jurisdiction");
        }

        public NgWebElement CategoryColumn(int rowIndex)
        {
            return Cell(rowIndex, "Category");
        }
    }

    public class NameMaintenancePage : PageObject
    {
        readonly NgWebElement _container;

        public NameMaintenancePage(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            _container = container;
        }

        public NgWebElement PreviousButton => Driver.FindElement(By.CssSelector("button.btn-icon span.cpa-icon-chevron-circle-left"));
        public NgWebElement NextButton => Driver.FindElement(By.CssSelector("button.btn-icon span.cpa-icon-chevron-circle-right"));

        public NgWebElement BackButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-arrow-circle-nw"));

        public NameCharacteristics NameCharacteristics => new(Driver, _container);

        public InstructionRelatedFields InstructionRelatedFields => new(Driver, _container);

        public SanityRuleRelatedFields SanityRuleRelatedFields => new(Driver, _container);

        public NgWebElement SaveButton => Driver.FindElement(By.ClassName("btn-save"));
    }

    public class NameCharacteristics : PageObject
    {
        readonly NgWebElement _container;

        public NameCharacteristics(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            _container = container;
        }

        public AngularPicklist Name => new AngularPicklist(Driver, _container).ByName("name");
        public AngularPicklist NameGroup => new AngularPicklist(Driver, _container).ByName("nameGroup");
        public AngularPicklist Jurisdiction => new AngularPicklist(Driver, _container).ByName("jurisdiction");
        public AngularPicklist Category => new AngularPicklist(Driver, _container).ByName("caseCategory");

        public AngularCheckbox IsOrganisation => new AngularCheckbox(Driver, _container).ByName("organisation");
        public AngularCheckbox IsIndividual => new AngularCheckbox(Driver, _container).ByName("individual");
        public AngularCheckbox IsClientOnly => new AngularCheckbox(Driver, _container).ByName("clientOnly");
        public AngularCheckbox IsStaff => new AngularCheckbox(Driver, _container).ByName("staff");
        public AngularCheckbox IsSupplier => new AngularCheckbox(Driver, _container).ByName("supplierOnly");
    }
}

