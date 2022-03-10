using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Integration.EndToEnd.Search.Case;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search.Types
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    public class HostedBillSearch : HostedSearchResultsBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void VerifyReverseFinalizedBill(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var queryContextKey = (int)QueryContext.BillingSelection;
            var dbSetup = new BillSearchDbSetup();
            var queryKeyDraftBills = dbSetup.CreateSavedSearch(queryContextKey);
            TestHostedSearchResultsLifeCycle(driver, queryContextKey, queryKey: queryKeyDraftBills);
            var page = new HostedTestPageObject(driver);
            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                Assert.False(page.HostedSearchPage.HasTaskMenuFor(BillSearchTaskMenuItemOperationType.ReverseBill), "Reverse Bill task menu should not be presented for draft bill.");
            });
            
            var queryKeyFinalisedBills = dbSetup.CreateSavedSearch(queryContextKey, true);
            TestHostedSearchResultsLifeCycle(driver, queryContextKey, queryKey: queryKeyFinalisedBills);
            AssertReverseBillMenuSendsNavigationMessage(driver);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void VerifyCreditFinalizedBill(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var queryContextKey = (int)QueryContext.BillingSelection;
            var dbSetup = new BillSearchDbSetup();
            var queryKeyDraftBills = dbSetup.CreateSavedSearch(queryContextKey);
            TestHostedSearchResultsLifeCycle(driver, queryContextKey, queryKey: queryKeyDraftBills);
            var page = new HostedTestPageObject(driver);
            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                Assert.False(page.HostedSearchPage.HasTaskMenuFor(BillSearchTaskMenuItemOperationType.CreditBill), "Credit Bill task menu should not be presented for draft bill.");
            });
            
            var queryKeyFinalisedBills = dbSetup.CreateSavedSearch(queryContextKey, true);
            TestHostedSearchResultsLifeCycle(driver, queryContextKey, queryKey: queryKeyFinalisedBills);
            AssertCreditBillMenuSendsNavigationMessage(driver);
        }

        void AssertReverseBillMenuSendsNavigationMessage(NgWebDriver driver)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.TaskMenuFor(BillSearchTaskMenuItemOperationType.ReverseBill).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(BillSearchTaskMenuItemOperationType.ReverseBill, page.NavigationMessages.Last().Args[0], "Posts Message to Reverse Bill");
            Assert.AreEqual(7, page.NavigationMessages.Last().Args.Length, "Posts arguments to Reverse Bill");
        }

        void AssertCreditBillMenuSendsNavigationMessage(NgWebDriver driver)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.TaskMenuFor(BillSearchTaskMenuItemOperationType.CreditBill).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(BillSearchTaskMenuItemOperationType.CreditBill, page.NavigationMessages.Last().Args[0], "Posts Message to Credit Bill");
            Assert.AreEqual(8, page.NavigationMessages.Last().Args.Length, "Posts arguments to Reverse Bill");
        }
    }
}
