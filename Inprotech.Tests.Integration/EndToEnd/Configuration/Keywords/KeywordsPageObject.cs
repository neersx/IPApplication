using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Keywords
{
    public class KeywordsPageObject : PageObject
    {
        public KeywordsPageObject(NgWebDriver driver) : base(driver)
        {
        }
        public AngularKendoGrid KeywordsGrid => new AngularKendoGrid(Driver, "keywordsGrid");
        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.searchCriteria.text']"));
        }

        public NgWebElement KeywordNavigationLink => Driver.FindElement(By.XPath("//tbody/tr[1]/td[2]/a[1]"));

        public NgWebElement SearchTextBoxInKeywords(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("keyword")).FindElement(By.TagName("input"));
        }

        public NgWebElement DeleteMenu => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_delete']"));
        public NgWebElement EditMenu => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_edit']"));
        public NgWebElement SearchButton => Driver.FindElement(By.XPath("//span[@class='cpa-icon cpa-icon-search']"));

        public NgWebElement ButtonAddOffice => Driver.FindElement(By.XPath("//span[contains(@class,'cpa-icon cpa-icon-plus-circle')]"));
        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
        public NgWebElement ModalSave => Driver.FindElement(By.CssSelector(".modal-dialog .btn-save"));
        public NgWebElement ModalCancel => Driver.FindElement(By.CssSelector(".modal-dialog .btn-discard"));

        public IpxTextField Keyword => new IpxTextField(Driver).ById("keyword");
    }
}
