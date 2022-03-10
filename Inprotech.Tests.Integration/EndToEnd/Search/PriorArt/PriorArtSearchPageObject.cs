using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Search.PriorArt
{
    public class PriorArtSearchPageObject : PageObject
    {
        public PriorArtSearchPageObject(NgWebDriver driver) : base(driver)
        {
            
        }

        public NgWebElement ExportToPdf => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_export-pdf']"));
    }
}
