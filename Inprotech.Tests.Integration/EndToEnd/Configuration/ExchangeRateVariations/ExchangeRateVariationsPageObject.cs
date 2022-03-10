using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.ExchangeRateVariations
{
    public class ExchangeRateVariationsPageObject : PageObject
    {
        public ExchangeRateVariationsPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public AngularKendoGrid CurrencyGrid => new AngularKendoGrid(Driver, "currenciesGrid");
        public AngularKendoGrid ExchangeRateScheduleGrid => new AngularKendoGrid(Driver, "exchangeRateScheduleGrid");
        public NgWebElement CurrenciesNavigationLink => Driver.FindElement(By.XPath("//tbody/tr[1]/td[2]/a[1]"));

        public NgWebElement ExchangeRateVariationMenu => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_exchangeRateVariation']"));

        public AngularKendoGrid ExchangeRateVariationGrid => new AngularKendoGrid(Driver, "exchangeRateVariationGrid");

        public NgWebElement SearchButton => Driver.FindElement(By.XPath("//span[@class='cpa-icon cpa-icon-search']"));
        public NgWebElement ClearButton => Driver.FindElement(By.XPath("//span[@class='cpa-icon cpa-icon-eraser']"));
        public NgWebElement ButtonAdd => Driver.FindElement(By.XPath("//span[contains(@class,'cpa-icon cpa-icon-plus-circle')]"));
        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
        public NgWebElement ModalSave => Driver.FindElement(By.CssSelector(".modal-dialog .btn-save"));
        public NgWebElement ModalCancel => Driver.FindElement(By.CssSelector(".modal-dialog .btn-discard"));

        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.searchCriteria.text']"));
        }

        public NgWebElement SearchTextBoxInCurrency(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("currencies")).FindElement(By.TagName("input"));
        }
        public NgWebElement SearchTextBoxInExchangeRateSchedule(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("exchangeRateSchedule")).FindElement(By.TagName("input"));
        }

        public AngularPicklist CurrencyPicklist => new AngularPicklist(Driver).ByName("currency");
        public AngularPicklist CurrencyPicklistField => new AngularPicklist(Driver).ByName("currencyPicklistField");
        public AngularPicklist CaseTypePicklist => new AngularPicklist(Driver).ByName("caseType");
        public AngularPicklist SubTypePicklist => new AngularPicklist(Driver).ByName("subType");
        public AngularPicklist PropertyTypePicklist => new AngularPicklist(Driver).ByName("propertyType");
        public AngularPicklist CountryPicklist => new AngularPicklist(Driver).ByName("jurisdiction");
        public NgWebElement DeleteMenu => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_delete']"));
        public AngularPicklist ExchRateSchdPicklist => new AngularPicklist(Driver).ByName("exchRateSch");
        public IpxTextField BuyFactor => new IpxTextField(Driver).ById("buyFactor");
        public IpxTextField SellFactor => new IpxTextField(Driver).ById("sellFactor");
        public IpxTextField BuyRate => new IpxTextField(Driver).ById("buyRate");
        public IpxTextField SellRate => new IpxTextField(Driver).ById("sellRate");
        public AngularDatePicker effectiveDate => new AngularDatePicker(Driver).ByName("effectiveDate");
    }
}