using System.Collections.ObjectModel;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.BulkCaseImport
{
    public class ImportStatusPageObject : PageObject
    {
        public ImportStatusPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public KendoGrid ImportStatus => new KendoGrid(Driver, "importStatus");

        AlertModal ErrorModal => new AlertModal(Driver, "ImportStatusErrorPopup");

        public ReadOnlyCollection<NgWebElement> Issues => ErrorModal.Modal.FindElements(NgBy.Repeater("i in vm.options.details.issues"));

        public NgWebElement ReverseButton => Driver.FindElement(By.Id("bulkaction_importStatus_reverse"));

        public NgWebElement ErrorLinkFor(int batchId)
        {
            return Driver.FindElement(By.Id($"error_{batchId}"));
        }

        public NgWebElement ResubmitLinkFor(int batchId)
        {
            if (!Driver.IsElementPresent(By.Id($"resubmit_{batchId}")))
                return null;

            return Driver.FindElement(By.Id($"resubmit_{batchId}"));
        }

        public void BulkMenu()
        {
            Driver.FindElement(By.Name("list-ul")).Click();
        }

        public void ResumitBatch(int batchId)
        {
            ResubmitLinkFor(batchId).ClickWithTimeout();
        }

    }
}