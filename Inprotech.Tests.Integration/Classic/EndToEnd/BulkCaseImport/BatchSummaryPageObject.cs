using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.BulkCaseImport
{
    public class BatchSummaryPageObject : PageObject
    {
        public BatchSummaryPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement GetCaseRefLink(int rowNumber, int columnNumber)
        {
            return BulkImportSummaryGrid.Cell(rowNumber,columnNumber).FindElement(By.TagName("a"));
        }

        public KendoGrid BulkImportSummaryGrid => new KendoGrid(Driver, "bulkImportSummary");
    }
}