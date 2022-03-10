using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.SanityCheck.Case
{
    public class CaseMaintenancePage : PageObject
    {
        readonly NgWebElement _container;

        public CaseMaintenancePage(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            _container = container;
        }

        public NgWebElement PreviousButton => Driver.FindElement(By.CssSelector("button.btn-icon span.cpa-icon-chevron-circle-left"));
        public NgWebElement NextButton => Driver.FindElement(By.CssSelector("button.btn-icon span.cpa-icon-chevron-circle-right"));

        public NgWebElement BackButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-arrow-circle-nw"));

        public CaseCharacteristics CaseCharacteristics => new(Driver, _container);

        public NameRelatedFields NameRelatedFields => new(Driver, _container);

        public InstructionRelatedFields InstructionRelatedFields => new(Driver, _container);

        public EventRelatedFields EventRelatedFields => new(Driver, _container);

        public SanityRuleRelatedFields SanityRuleRelatedFields => new(Driver, _container);

        public NgWebElement SaveButton => Driver.FindElement(By.ClassName("btn-save"));
    }

    public class CaseSearch : SanityCheckBaseSearchPageObject
    {
        readonly NgWebElement _container;

        public CaseSearch(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            _container = container;
        }

        public CaseCharacteristics CaseCharacteristics => new(Driver, _container);

        public NameRelatedFields NameRelatedFields => new(Driver, _container);

        public InstructionRelatedFields InstructionRelatedFields => new(Driver, _container);

        public EventRelatedFields EventRelatedFields => new(Driver, _container);

        public StatusFields StatusFields => new(Driver, _container);

        public CaseSanityCheckGrid CaseSanityCheckGrid => new(Driver);
    }

    public class CaseCharacteristics : PageObject
    {
        readonly NgWebElement _container;

        public CaseCharacteristics(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            _container = container;
        }

        public AngularPicklist Office => new AngularPicklist(Driver, _container).ByName("office");
        public AngularPicklist CaseType => new AngularPicklist(Driver, _container).ByName("caseType");
        public AngularPicklist Jurisdiction => new AngularPicklist(Driver, _container).ByName("jurisdiction");
        public AngularPicklist PropertyType => new AngularPicklist(Driver, _container).ByName("propertyType");
        public AngularPicklist CaseCategory => new AngularPicklist(Driver, _container).ByName("caseCategory");
        public AngularPicklist SubType => new AngularPicklist(Driver, _container).ByName("subType");
        public AngularPicklist Basis => new AngularPicklist(Driver, _container).ByName("basis");

        public AngularCheckbox CaseOfficeExclude => new AngularCheckbox(Driver, _container).ByName("caseOfficeExclude");
        public AngularCheckbox CaseTypeExclude => new AngularCheckbox(Driver, _container).ByName("caseTypeExclude");
        public AngularCheckbox JurisdictionExclude => new AngularCheckbox(Driver, _container).ByName("jurisdictionExclude");
        public AngularCheckbox PropertyTypeExclude => new AngularCheckbox(Driver, _container).ByName("propertyTypeExclude");
        public AngularCheckbox CaseCategoryExclude => new AngularCheckbox(Driver, _container).ByName("caseCategoryExclude");
        public AngularCheckbox SubTypeExclude => new AngularCheckbox(Driver, _container).ByName("subTypeExclude");
        public AngularCheckbox BasisExclude => new AngularCheckbox(Driver, _container).ByName("basisExclude");
    }

    public class NameRelatedFields : PageObject
    {
        readonly NgWebElement _container;

        public NameRelatedFields(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            _container = container;
        }

        public AngularPicklist NameGroup => new AngularPicklist(Driver, _container).ByName("nameGroup");

        public AngularPicklist Name => new AngularPicklist(Driver, _container).ByName("name");

        public AngularPicklist NameType => new AngularPicklist(Driver, _container).ByName("nameType");
    }

    public class EventRelatedFields : PageObject
    {
        readonly NgWebElement _container;

        public EventRelatedFields(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            _container = container;
        }

        public AngularPicklist Event => new AngularPicklist(Driver, _container).ByName("event");

        public AngularPicklist TableColumn => new AngularPicklist(Driver, _container).ByName("tableColumn");

        public AngularCheckbox EventIncludeDue => new AngularCheckbox(Driver, _container).ByName("eventIncludeDue");
        public AngularCheckbox EventIncludeOccurred => new AngularCheckbox(Driver, _container).ByName("eventIncludeOccurred");
    }

    public class StatusFields : PageObject
    {
        readonly NgWebElement _container;

        public StatusFields(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            _container = container != null ? container.FindElement(By.Name("status")) : Driver.FindElement(By.Name("status"));
        }

        public AngularCheckbox Pending => new AngularCheckbox(Driver, _container).ByName("pending");
        public AngularCheckbox Registered => new AngularCheckbox(Driver, _container).ByName("registered");
        public AngularCheckbox Dead => new AngularCheckbox(Driver, _container).ByName("dead");
    }

    public class CaseSanityCheckGrid : AngularKendoGrid
    {
        const string ExcludeIcon = "ipx-icon span.cpa-icon.cpa-icon-minus-circle";

        public CaseSanityCheckGrid(NgWebDriver driver) : base(driver, "sanityChecks")
        {
        }

        public void Edit(int rowIndex)
        {
            var ruleDescriptionColumn = RuleDescriptionColumn(rowIndex);
            ruleDescriptionColumn.FindElement(By.TagName("a"))?.Click();
        }

        public NgWebElement RuleDescriptionColumn(int rowIndex) => Cell(rowIndex, "Rule Description");

        public NgWebElement CaseTypeColumn(int rowIndex) => Cell(rowIndex, "Case Type");

        public NgWebElement CaseOfficeColumn(int rowIndex) => Cell(rowIndex, "Case Office");

        public NgWebElement PropertyTypeColumn(int rowIndex) => Cell(rowIndex, "Property Type");

        public NgWebElement CaseCategoryColumn(int rowIndex) => Cell(rowIndex, "Case Category");

        public NgWebElement SubTypeColumn(int rowIndex) => Cell(rowIndex, "Sub Type");

        public NgWebElement BasisColumn(int rowIndex) => Cell(rowIndex, "Basis");

        public NgWebElement JurisdictionColumn(int rowIndex) => Cell(rowIndex, "Jurisdiction");

        public bool CaseTypeExcludeIcon(int rowIndex) => CaseTypeColumn(rowIndex).FindElements(By.CssSelector(ExcludeIcon)).Count == 1;
        public bool PropertyTypeExcludeIcon(int rowIndex) => PropertyTypeColumn(rowIndex).FindElements(By.CssSelector(ExcludeIcon)).Count == 1;
        public bool CaseCategoryExcludeIcon(int rowIndex) => CaseCategoryColumn(rowIndex).FindElements(By.CssSelector(ExcludeIcon)).Count == 1;
        public bool SubTypeExcludeIcon(int rowIndex) => SubTypeColumn(rowIndex).FindElements(By.CssSelector(ExcludeIcon)).Count == 1;
        public bool BasisExcludeIcon(int rowIndex) => JurisdictionColumn(rowIndex).FindElements(By.CssSelector(ExcludeIcon)).Count == 1;
        public bool JurisdictionExcludeIcon(int rowIndex) => JurisdictionColumn(rowIndex).FindElements(By.CssSelector(ExcludeIcon)).Count == 1;
    }
}