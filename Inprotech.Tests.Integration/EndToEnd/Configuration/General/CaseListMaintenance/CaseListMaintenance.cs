using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Search.Case.CaseSearch;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.CaseListMaintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseListMaintenance : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void SearchCaseLists(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainCaseList).Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/search", user.Username, user.Password);
            var page = new CaseListMaintenancePageObject(driver);
            page.SearchField.SendKeys("Case List");
            page.SearchButton.ClickWithTimeout();
            page.ConfigurationSearchLink.ClickWithTimeout();

            DbSetup.Do(x =>
            {
                new CaseBuilder(x.DbContext).Create("e2e");
                new CaseBuilder(x.DbContext).Create("e2e1");
                new CaseBuilder(x.DbContext).Create("e2e3");
            });

            #region Add Case List

            page.ButtonAddCaseListElement.ClickWithTimeout();
            var manageCaseListModal = new ManageCaseListModalObject(driver);
            Assert.AreEqual(manageCaseListModal.ModalTitle.Text, "Add Case List");
            Assert.False(manageCaseListModal.ButtonSaveCaseList.Enabled);
            var caselistName = "New case list2";
            var listDescription = "Test description2";
            var primeCase = "1234/A";
            manageCaseListModal.TextCaseListName.SendKeys(caselistName);
            manageCaseListModal.TextDescription.SendKeys(listDescription);
            manageCaseListModal.PrimeCase.SendKeys(primeCase);
            manageCaseListModal.PrimeCase.SendKeys(Keys.Tab);
            manageCaseListModal.PrimeCase.SendKeys(Keys.Tab);
            Assert.True(manageCaseListModal.ButtonSaveCaseList.Enabled);
            manageCaseListModal.ButtonSaveCaseList.WithJs().Click();
            page.SearchField.SendKeys(caselistName);
            page.SearchButton.Click();
            driver.WaitForGridLoader();
            driver.Wait().ForTrue(() => page.ResultGrid.Rows.Count == 1);
            var grid = page.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "1 record is returned by search");
            Assert.AreEqual(caselistName, grid.Cell(0, 1).Text);
            Assert.AreEqual(listDescription, grid.Cell(0, 2).Text);

            #endregion

            #region Edit Case List

            grid.Rows.First().FindElement(By.CssSelector("td a")).ClickWithTimeout();
            caselistName += " updated";
            manageCaseListModal.TextCaseListName.Clear();
            manageCaseListModal.TextCaseListName.SendKeys(caselistName);
            manageCaseListModal.ButtonSaveCaseList.WithJs().Click();
            page.SearchField.Clear();
            page.SearchField.SendKeys(caselistName);
            page.SearchButton.Click();
            grid = page.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "1 record is returned by search");
            Assert.AreEqual(caselistName, grid.Cell(0, 1).Text);
            Assert.AreEqual(listDescription, grid.Cell(0, 2).Text);

            #endregion

            #region Delete Case List

            grid.Cell(0, 0).Click();
            page.BulkActionMenu.Click();
            page.Delete.WithJs().Click();
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.AreEqual(0, grid.Rows.Count, "0 record is returned by search");

            #endregion
        }
    }
}