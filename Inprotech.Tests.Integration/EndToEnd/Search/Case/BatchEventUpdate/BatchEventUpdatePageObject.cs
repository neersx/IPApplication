using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.BatchEventUpdate
{
    public class BatchEventUpdatePageObject : PageObject
    {
        public BatchEventUpdatePageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement SearchTextField => Driver.FindElement(By.CssSelector("input[name='quickSearch']"));

        public NgWebElement FirstCheckbox => Driver.FindElement(By.CssSelector("tr:nth-child(1)>td:nth-child(1)"));
        public NgWebElement SecondCheckbox => Driver.FindElement(By.CssSelector("tr:nth-child(2)>td:nth-child(1)"));
        public NgWebElement ClearSelected => Driver.FindElement(By.XPath("//span[contains(text(),'Clear selected')]"));
        public NgWebElement SelectThisPage => Driver.FindElement(By.CssSelector("a#a123_selectall"));
        public NgWebElement BulkOperationButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-list-ul"));
        public NgWebElement BulkUpdatePageTitle => Driver.FindElement(By.XPath("//h3"));
        public NgWebElement BathEventUpdateButton => Driver.FindElement(By.CssSelector("a#bulkaction_a123_batch-event-update"));

        public NgWebElement BulkEventUpdate => Driver.FindElement(By.XPath("//span[text()='Batch event update']/.."));
    }
}