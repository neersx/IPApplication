using System.Collections.ObjectModel;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.BulkCaseImport
{
    public class MappingIssuesPageObjects : PageObject
    {
        public MappingIssuesPageObjects(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement BatchIdentifier => Driver.FindElement(By.Id("batchIdentifier"));

        public NgWebElement BatchSummaryLink => Driver.FindElement(By.Id("miTransactionLink"));

        public ReadOnlyCollection<NgWebElement> MappingIssues => Driver.FindElements(NgBy.Repeater("n in data.mappingIssues"));
    }
}