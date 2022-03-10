using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.CaseSearch
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseListPicklist : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainCaseList(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainCaseList).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search", user.Username, user.Password);
            var popup = new CommonPopups(driver);
            InprotechKaizen.Model.Cases.Case case1 = null, case2 = null, case3 = null;
            DbSetup.Do(x =>
            {
                case1 = new CaseBuilder(x.DbContext).Create("e2e");
                case2 = new CaseBuilder(x.DbContext).Create("e2e1");
                case3 = new CaseBuilder(x.DbContext).Create("e2e3");
            });
            var searchPage = new CaseSearchPageObject(driver);
            searchPage.References.CaseList.OpenPickList();

            var caseListModal = new CaseListPicklistModalObject(driver);
            Assert.AreEqual(caseListModal.ModalTitle.Text, "Case List");
            caseListModal.ButtonAddCaseList.WithJs().Click();

            var manageCaseListModal = new ManageCaseListModalObject(driver);
            Assert.AreEqual(manageCaseListModal.ModalTitle.Text, "Add Case List");
            Assert.False(manageCaseListModal.ButtonSaveCaseList.Enabled);
            var listName = "Test case list1";
            var listDescription = "Test description";
            var primeCase = "1234/A";
            manageCaseListModal.TextCaseListName.SendKeys(listName);
            manageCaseListModal.TextDescription.SendKeys(listDescription);
            manageCaseListModal.PrimeCase.SendKeys(primeCase);
            manageCaseListModal.TextCaseListName.Click();
            manageCaseListModal.PrimeCase.Click();
            Assert.True(manageCaseListModal.ButtonSaveCaseList.Enabled);
            manageCaseListModal.ButtonSaveCaseList.WithJs().Click();

            caseListModal.SearchField.SendKeys(listName);
            caseListModal.SearchButton.WithJs().Click();

            var grid = caseListModal.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count);
            var row = grid.Rows.First();
            Assert.AreEqual(listName, row.FindElement(By.CssSelector("td:nth-child(1)")).Text);
            Assert.AreEqual(listDescription, row.FindElement(By.CssSelector("td:nth-child(2)")).Text);
            Assert.AreEqual(primeCase, row.FindElement(By.CssSelector("td:nth-child(3)")).Text);
            grid.EditButton(1).Click();

            listDescription = "Modified Test description";
            Assert.False(manageCaseListModal.ButtonSaveCaseList.Enabled);
            manageCaseListModal.TextDescription.Clear();
            manageCaseListModal.TextDescription.SendKeys(listDescription);
            Assert.True(manageCaseListModal.ButtonSaveCaseList.Enabled);
            manageCaseListModal.ButtonSaveCaseList.WithJs().Click();
            manageCaseListModal.CloseButton.WithJs().Click();
            caseListModal.SearchField.Clear();
            caseListModal.SearchField.SendKeys(listName);
            caseListModal.SearchButton.ClickWithTimeout();

            Assert.AreEqual(1, grid.Rows.Count);
            row = grid.Rows.First();
            Assert.AreEqual(listDescription, row.FindElement(By.CssSelector("td:nth-child(2)")).Text);
            grid.EditButton(1).Click();

            var caseListGrid = manageCaseListModal.CaseListGrid;
            Assert.AreEqual(1, caseListGrid.Rows.Count);

            manageCaseListModal.AddCaseButton.Click();
            var caseModel = new CasesModalObject(driver);
            caseModel.SearchField.SendKeys("1234");
            caseModel.SearchButton.Click();
            var caseGrid = caseModel.ResultGrid;
            Assert.True(caseGrid.Rows.Count > 2);
            caseGrid.SelectRow(0);
            caseGrid.SelectRow(1);
            caseModel.ApplyButton.WithJs().Click();

            caseListGrid = manageCaseListModal.CaseListGrid;
            Assert.AreEqual(2, caseListGrid.Rows.Count);
            manageCaseListModal.ButtonSaveCaseList.WithJs().Click();
            manageCaseListModal.CloseButton.WithJs().Click();

            caseListModal.SearchField.Clear();
            caseListModal.SearchField.SendKeys(listName);
            caseListModal.SearchButton.ClickWithTimeout();
            grid.DeleteButton(1).Click();

            Assert.NotNull(popup.ConfirmDeleteModal);
            caseListModal.DeleteButton.Click();

            Assert.NotNull(popup.AlertModal);
            popup.AlertModal.Ok();
            
            caseListModal.ButtonAddCaseList.WithJs().Click();
            manageCaseListModal.TextCaseListName.SendKeys(listName);
            Assert.True(manageCaseListModal.ButtonSaveCaseList.Enabled);
            manageCaseListModal.ButtonSaveCaseList.WithJs().Click();
            Assert.NotNull(popup.AlertModal);
            popup.AlertModal.Ok();
            
            listName = "new case list";
            manageCaseListModal.TextCaseListName.Clear();
            manageCaseListModal.TextCaseListName.SendKeys(listName);
            manageCaseListModal.ButtonSaveCaseList.WithJs().Click();

            caseListModal.SearchField.Clear();
            caseListModal.SearchField.SendKeys(listName);
            caseListModal.SearchButton.ClickWithTimeout();
            grid.DeleteButton(1).Click();

            Assert.NotNull(popup.ConfirmDeleteModal);
            caseListModal.DeleteButton.Click();

            caseListModal.SearchField.Clear();
            caseListModal.SearchField.SendKeys(listName);
            caseListModal.SearchButton.ClickWithTimeout();
            Assert.True(grid.Rows.Count == 0);
        }
    }
}