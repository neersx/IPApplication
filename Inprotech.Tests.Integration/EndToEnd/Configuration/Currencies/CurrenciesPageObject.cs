using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Currencies
{
    public class CurrenciesPageObject : PageObject
    {
        public CurrenciesPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public AngularKendoGrid CurrencyGrid => new AngularKendoGrid(Driver, "currenciesGrid");
        public NgWebElement CurrenciesNavigationLink => Driver.FindElement(By.XPath("//tbody/tr[1]/td[2]/a[1]"));

        public NgWebElement SearchButton => Driver.FindElement(By.XPath("//span[@class='cpa-icon cpa-icon-search']"));
        public NgWebElement DeleteMenu => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_delete']"));

        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.searchCriteria.text']"));
        }

        public NgWebElement SearchTextBoxInOffice(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("currencies")).FindElement(By.TagName("input"));
        }

        public NgWebElement ButtonAdd => Driver.FindElement(By.XPath("//span[contains(@class,'cpa-icon cpa-icon-plus-circle')]"));
        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
        public NgWebElement ModalSave => Driver.FindElement(By.CssSelector(".modal-dialog .btn-save"));
        public NgWebElement ModalCancel => Driver.FindElement(By.CssSelector(".modal-dialog .btn-discard"));
        public IpxTextField CurrencyCode => new IpxTextField(Driver).ById("currencyCode");
        public IpxTextField Description => new IpxTextField(Driver).ById("currencyDescription");
        public IpxTextField BankRate => new IpxTextField(Driver).ById("bankRate");
        public AngularKendoGrid HistoryGrid => new AngularKendoGrid(Driver, "historyGrid");
    }
}