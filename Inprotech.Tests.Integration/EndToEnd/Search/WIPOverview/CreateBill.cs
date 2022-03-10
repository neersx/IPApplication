using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Search.WIPOverview
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    public class CreateBill : IntegrationTest
    {
        [TestCase(BrowserType.Chrome, Ignore = "This feature is not completed yet. It will be reinstated once this feature gets completed")]
        [TestCase(BrowserType.Ie, Ignore = "This feature is not completed yet. It will be reinstated once this feature gets completed")]
        [TestCase(BrowserType.FireFox, Ignore = "This feature is not completed yet. It will be reinstated once this feature gets completed")]
        public void CreateSingleBill(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var data = new CreateBillDbSetup().Setup();

            SignIn(driver, "#/search-result?queryContext=200&queryKey=" + data.QueryKey);
            var page = new BillSearchPageObject(driver);
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            var grid = page.ResultGrid;
            var selectedCaseRef = grid.Cell(0, grid.FindColByText("Case Ref.")).FindElement(By.TagName("a")).Text;
            grid.Cell(0, 0).FindElement(By.TagName("ipx-checkbox")).Click();
            grid.Cell(1, 0).FindElement(By.TagName("ipx-checkbox")).Click();
            grid.ActionMenu.OpenOrClose();
            page.SingleBillButton.Click();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("Maxim Yarrow and Colman", page.EntitySelect.SelectedOption.Text.Trim());
            Assert.AreEqual("Grey, George",page.RaisedByPickList.GetText());
            Assert.AreEqual(data.FromDate.ToString("dd-MMM-yyyy"), page.FromDatePicker.Value);
            Assert.AreEqual(data.ToDate.ToString("dd-MMM-yyyy"), page.ToDatePicker.Value);
            Assert.IsTrue(page.IncludeNonRenewalCheckBox.IsChecked);
            Assert.IsTrue(page.IncludeRenewalCheckBox.IsChecked);
            Assert.IsFalse(page.UseRenewalDebtorCheckBox.IsChecked);
            page.ProceedButton.WithJs().Click();

            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("Billing Wizard", page.BillingWizardTitle.Text.Trim());
            Assert.AreEqual(data.FromDate.ToString("dd-MMM-yyyy"), page.ItemDate.Value);
            Assert.AreEqual("Grey, George", page.RaisedByValuePicklist.GetText());
            var caseRef = page.ResultCaseGrid.Cell(0, page.ResultCaseGrid.FindColByText("Case Ref.")).FindElement(By.TagName("a")).Text;
            Assert.AreEqual(selectedCaseRef, caseRef);
            Assert.AreEqual("Maxim Yarrow and Colman", page.EntityValueSelect.SelectedOption.Text.Trim());
            Assert.IsTrue(page.UseRenewalDebtorCheckBox.IsChecked);
        }
    }
}