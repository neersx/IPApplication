using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.ExchangeRateSchedule
{
    public class ExchangeRateSchedulePageObject : PageObject
    {
        public ExchangeRateSchedulePageObject(NgWebDriver driver) : base(driver)
        {
        }

        public AngularKendoGrid ExchangeRateScheduleGrid => new AngularKendoGrid(Driver, "exchangeRateScheduleGrid");
        public NgWebElement ExchangeRateScheduleNavigationLink => Driver.FindElement(By.XPath("//tbody/tr[1]/td[2]/a[1]"));

        public NgWebElement SearchButton => Driver.FindElement(By.XPath("//span[@class='cpa-icon cpa-icon-search']"));

        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.searchCriteria.text']"));
        }

        public NgWebElement SearchTextBoxInOffice(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("exchangeRateSchedule")).FindElement(By.TagName("input"));
        }

        public NgWebElement ButtonAdd => Driver.FindElement(By.XPath("//span[contains(@class,'cpa-icon cpa-icon-plus-circle')]"));
        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
        public NgWebElement ModalSave => Driver.FindElement(By.CssSelector(".modal-dialog .btn-save"));
        public NgWebElement ModalCancel => Driver.FindElement(By.CssSelector(".modal-dialog .btn-discard"));
        public IpxTextField Code => new IpxTextField(Driver).ById("code");
        public IpxTextField Description => new IpxTextField(Driver).ById("description");
        public NgWebElement DeleteMenu => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_delete']"));
    }
}