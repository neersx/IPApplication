using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Search.Case.CaseSearch;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;
using System.Linq;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.AddCasesToCaseList
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CasesToCaseList : IntegrationTest
    {
        NgWebDriver _driver;
        AngularKendoGrid _grid;
        CaseListPicklistModalObject _caseListModal;
        ManageCaseListModalObject _manageCaseListModal;
        string _listName;
        string _listDescription;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyAddCasesIntoCaseList(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainCaseList).Create();
            _driver = BrowserProvider.Get(browserType);
            SignIn(_driver, "/#/search-result?queryContext=2", user.Username, user.Password);
            DbSetup.Do(x =>
            {
                new CaseBuilder(x.DbContext).Create("e2e");
                new CaseBuilder(x.DbContext).Create("e2e1");
                new CaseBuilder(x.DbContext).Create("e2e3");
            });

            _grid = new AngularKendoGrid(_driver, "searchResults", "a123");
            AddCasesToNewCaseList();
            AddCasesToExistingCaseList();
        }
        void AddCasesToNewCaseList()
        {
            _grid.ActionMenu.OpenOrClose();
            Assert.IsTrue(_grid.ActionMenu.Option("add-to-caselist").Disabled());
            _grid.ActionMenu.OpenOrClose();
            var case1 = _driver.FindElement(By.XPath("//tr[1]//td[3]//div[1]//ipx-hosted-url[1]//a[1]")).Text;
            var case2 = _driver.FindElement(By.XPath("//tr[2]//td[3]//div[1]//ipx-hosted-url[1]//a[1]")).Text;
            _grid.SelectRow(0);
            _grid.SelectRow(1);
            _grid.ActionMenu.OpenOrClose();
            Assert.IsTrue(_grid.ActionMenu.Option("add-to-caselist").Enabled);
            _grid.ActionMenu.Option("add-to-caselist").WithJs().Click();

            _caseListModal = new CaseListPicklistModalObject(_driver);
            Assert.AreEqual(_caseListModal.ModalTitle.Text, "Case List");
            _caseListModal.ButtonAddCaseList.WithJs().Click();

            _manageCaseListModal = new ManageCaseListModalObject(_driver);
            Assert.AreEqual(_manageCaseListModal.ModalTitle.Text, "Add Case List");
            Assert.False(_manageCaseListModal.ButtonSaveCaseList.Enabled);
            _listName = "New Bulk case list11";
            _listDescription = "Bulk Cases to List";
            _manageCaseListModal.TextCaseListName.SendKeys(_listName);
            _manageCaseListModal.TextDescription.SendKeys(_listDescription);
            Assert.True(_manageCaseListModal.ButtonSaveCaseList.Enabled);
            var case1List = _manageCaseListModal.CaseListGrid.CellText(0, 1, false);
            var case2List = _manageCaseListModal.CaseListGrid.CellText(1, 1, false);
            Assert.AreEqual(case1, case1List);
            Assert.AreEqual(case2, case2List);
            _manageCaseListModal.ButtonSaveCaseList.WithJs().Click();
        }
        void AddCasesToExistingCaseList()
        {
            _driver.Visit(Env.RootUrl + "/#/search-result?queryContext=2");
            _grid.SelectRow(2);
            var case3 = _driver.FindElement(By.XPath("//tr[3]//td[3]//div[1]//ipx-hosted-url[1]//a[1]")).Text;
            _grid.ActionMenu.OpenOrClose();
            Assert.IsTrue(_grid.ActionMenu.Option("add-to-caselist").Enabled);
            _grid.ActionMenu.Option("add-to-caselist").WithJs().Click();
            _caseListModal.SearchField.SendKeys(_listName);
            _caseListModal.SearchButton.WithJs().Click();
            var gridCaseList = _caseListModal.ResultGrid;
            Assert.AreEqual(1, gridCaseList.Rows.Count);
            gridCaseList.Rows.First().FindElements(By.TagName("td"))?.First().ClickWithTimeout();
            Assert.True(_manageCaseListModal.AddCaseButton.Displayed);
            var case3List = _manageCaseListModal.CaseListGrid.CellText(0, 1, false);
            Assert.AreEqual(case3, case3List);
            Assert.AreNotEqual(0, _grid.FindElement(By.ClassName("added")).Size);
            _manageCaseListModal.ButtonSaveCaseList.WithJs().Click();
            _driver.Visit(Env.RootUrl + "/#/case/search");
            var searchPage = new CaseSearchPageObject(_driver);
            searchPage.References.CaseList.OpenPickList();
            _caseListModal.SearchField.Clear();
            _caseListModal.SearchField.SendKeys(_listName);
            _caseListModal.SearchButton.ClickWithTimeout();
            Assert.AreEqual(1, gridCaseList.Rows.Count);
            var row = gridCaseList.Rows.First();
            Assert.AreEqual(_listDescription, row.FindElement(By.CssSelector("td:nth-child(2)")).Text);
            gridCaseList.EditButton(1).Click();
            gridCaseList = _manageCaseListModal.CaseListGrid;
            Assert.AreEqual(3, gridCaseList.Rows.Count);
        }
    }
}
