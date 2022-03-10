using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.SanityCheck
{
    public class SanityCheckBaseSearchPageObject : PageObject
    {
        readonly NgWebElement _container;

        public SanityCheckBaseSearchPageObject(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            _container = container;
        }

        public SanityRuleRelatedFields SanityRuleRelatedFields => new(Driver, _container);
        public NgWebElement SearchButton => Driver.FindElement(By.XPath("//span[@class='cpa-icon cpa-icon-search']"));
        public NgWebElement ClearButton => Driver.FindElement(By.XPath("//span[@class='cpa-icon cpa-icon-eraser']"));
        public NgWebElement AddButton => Driver.FindElement(By.XPath("//em[text()='Add New Item']/.."));
        public NgWebElement BulkMenuButton => Driver.FindElement(By.Name("list-ul"));
        public NgWebElement SelectAllOption => Driver.FindElement(By.Name("selectall"));
        public NgWebElement EditSelectedOption => Driver.FindElement(By.XPath("//span[@title='Edit']"));
        public NgWebElement DeleteSelectedOption => Driver.FindElement(By.XPath("//span[@title='Delete']"));
        public NgWebElement DeletePopup => Driver.FindElement(By.XPath("//button[@name='delete']"));
    }

    public class SanityRuleRelatedFields : PageObject
    {
        readonly NgWebElement _container;

        public SanityRuleRelatedFields(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            _container = container;
        }

        public IpxTextField DisplayMessage => new IpxTextField(Driver, _container).ByName("displayMessage");

        public IpxTextField RuleDescription => new IpxTextField(Driver, _container).ByName("ruleDescription");

        public NgWebElement RuleDescriptionElement => Driver.FindElement(By.XPath("//label[text()='Rule Description']/following-sibling::input"));

        public IpxTextField Notes => new IpxTextField(Driver, _container).ByName("notes");

        public AngularPicklist SanityCheckSql => new AngularPicklist(Driver, _container).ByName("sanityCheckSql");

        public AngularPicklist MayBypassError => new AngularPicklist(Driver, _container).ByName("mayBypassError");

        public AngularCheckbox InformationOnly => new AngularCheckbox(Driver, _container).ByName("informationOnly");

        public AngularCheckbox IncludeInUse => new AngularCheckbox(Driver, _container).ByName("inUse");

        public AngularCheckbox IncludeDeferred => new AngularCheckbox(Driver, _container).ByName("deferred");
    }

    public class InstructionRelatedFields : PageObject
    {
        readonly NgWebElement _container;

        public InstructionRelatedFields(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            _container = container;
        }

        public AngularPicklist InstructionType => new AngularPicklist(Driver, _container).ByName("instructionType");

        public AngularPicklist Characteristic => new AngularPicklist(Driver, _container).ByName("characteristic");
    }
}