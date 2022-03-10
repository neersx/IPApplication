using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting
{
    public class VatPage : PageObject
    {
        public VatPage(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }
        public Checkbox OpenCheckbox => new Checkbox(Driver).ByName("open");
        public Checkbox FulfilledCheckbox => new Checkbox(Driver).ByName("fulfilled");
        public DropDown EntityDropDown => new DropDown(Driver).ByName("entityName");
        public NgWebElement TaxCode => Driver.FindElement(By.Id("taxCode"));
        public DatePicker FromDate => new DatePicker(Driver, "fromDate");
        public DatePicker ToDate => new DatePicker(Driver, "toDate");
        public KendoGrid Obligations => new KendoGrid(Driver, "accounting-vat-obligations");
        public NgWebElement ResultsTitle => Driver.FindElement(By.CssSelector("div#results-header h2 span:last-child"));
        public ButtonInput SubmitButton => new ButtonInput(Driver).ById("submit");
        public ButtonInput ClearButton => new ButtonInput(Driver).ById("clear");
        public ButtonInput ConfigureSettings => new ButtonInput(Driver).ById("configureHMRC");
    }

    public class HmrcSettingsPage : PageObject
    {
        public HmrcSettingsPage(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }
        public TextInput HmrcApplicationName => new TextInput(Driver).ByName("hmrcApplicationName");
        public TextInput ClientId => new TextInput(Driver).ByName("clientId");
        public TextInput ClientSecret => new TextInput(Driver).ByName("clientSecret");
        public TextInput RedirctUri => new TextInput(Driver).ByName("redirectUri");
        public ButtonInput DiscardButton => new ButtonInput(Driver).ByCssSelector(".btn-warning");
        public ButtonInput SaveButton => new ButtonInput(Driver).ByCssSelector(".btn-save");
    }
}
