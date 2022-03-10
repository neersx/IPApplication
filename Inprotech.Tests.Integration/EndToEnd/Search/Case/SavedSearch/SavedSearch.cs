using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Search.Case.CaseSearch;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.SavedSearch
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SavedSearch : IntegrationTest
    {
        [SetUp]
        public void PrepareData()
        {
            _summaryData = DbSetup.Do(setup =>
            {
                var irnPrefix = Fixture.UriSafeString(5);
                var caseBuilder = new CaseSearchCaseBuilder(setup.DbContext);
                var data = caseBuilder.Build(irnPrefix);

                var textType = setup.InsertWithNewId(new TextType(Fixture.String(5)));
                data.Case.CaseTexts.Add(new CaseText(data.Case.Id, textType.Id, 0, null) { Text = Fixture.String(10), TextType = textType });

                var family = setup.InsertWithNewId(new Family
                {
                    Name = $"{RandomString.Next(3)},{RandomString.Next(3)}"
                });

                data.Case.Family = family;
                setup.DbContext.SaveChanges();

                return data;
            });
        }

        CaseSearchCaseBuilder.SummaryData _summaryData;
        void ClickCaseSearchBuilder(CaseSearchPageObject searchPage)
        {
            searchPage.CaseSearchMenuItem().WithJs().Click();
            Assert.IsTrue(searchPage.CaseSubMenu.Displayed);
            searchPage.CaseSearchBuilder().WithJs().Click();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CreateUpdateDeleteCaseSaveSearch(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#");

            var searchPage = new CaseSearchPageObject(driver);
            ClickCaseSearchBuilder(searchPage);
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");

            // Create Save Search
            searchPage.References.CaseReference.SendKeys(_summaryData.Case.Irn);
            Assert.IsTrue(searchPage.CaseSaveSearchButton.Enabled, "Save button should be enabled");
            searchPage.PresentationButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            searchPage.UseDefaultCheckbox.WithJs().Click();
            searchPage.Presentation.SearchColumnTextBox.SendKeys("Acceptance Date");
            Assert.AreEqual("Acceptance Date", searchPage.Presentation.SearchColumn.Text);
            var jsExecutable = From.EmbeddedAssets("drag_and_drop_helper.js");
            jsExecutable = jsExecutable + "$('#availableColumns li span').simulateDragDrop({ dropTarget: '#KendoGrid tbody'});" ;
            ((IJavaScriptExecutor)driver).ExecuteScript(jsExecutable);
            searchPage.CaseSaveSearchButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            searchPage.SearchNameTextbox.SendKeys("E2ESavedSearch");
            Assert.IsTrue(searchPage.SavedSearchButton.Enabled);
            searchPage.SavedSearchButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            Assert.True(searchPage.CaseSearchHeaderTitle.Text.Contains("E2ESavedSearch"));
            searchPage.CustomisePresentation.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            Assert.IsTrue(driver.FindElement(By.XPath("//span[contains(text(), 'E2ESavedSearch')]")).Displayed);
            searchPage.CaseSearchButton.Click();
            
            Assert.IsTrue(driver.FindElement(By.XPath("//ipx-kendo-grid[@id='searchResults']//kendo-grid//table//thead//th//span[contains(text(),'Acceptance Date')]")).Displayed);
            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "1 record is returned by search");
            searchPage.CloseSearch.ClickWithTimeout();
            searchPage.Presentation.EditSearchCriteriaButton.ClickWithTimeout();

            // Edit Save Search
            var familyId = _summaryData.Case.Family.Name;
            searchPage.References.CaseFamily.EnterAndSelect(familyId);
            searchPage.CaseSaveSearchButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            searchPage.CaseSearchButton.Click();
            Assert.AreEqual(1, grid.Rows.Count, "1 record is returned by search");
            searchPage.CloseSearch.ClickWithTimeout();

            // Edit Save Search Name
            searchPage.MoreItemButton.Click();
            driver.FindElement(By.XPath("//span[contains(.,'Edit saved search details')]")).WithJs().Click();
            searchPage.SearchNameTextbox.Clear();
            searchPage.SearchNameTextbox.SendKeys("E2EEditSavedSearch");
            searchPage.SavedSearchButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            Assert.True(searchPage.CaseSearchHeaderTitle.Text.Contains("E2EEditSavedSearch"));

            // Delete Save Search
            searchPage.MoreItemButton.Click();
            driver.FindElement(By.XPath("//span[contains(.,'Delete saved search')]")).WithJs().Click();
            var popup = new CommonPopups(driver);
            popup.ConfirmNgDeleteModal.Delete.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            Assert.Throws<NoSuchElementException>(() =>searchPage.CaseSearchHeaderTitle.Text.Contains("E2EEditSavedSearch"));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void SaveAsSaveSearch(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#");

            var searchPage = new CaseSearchPageObject(driver);
            ClickCaseSearchBuilder(searchPage);
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");

            // Create Save As Search
            searchPage.References.CaseReference.SendKeys(_summaryData.Case.Irn);
            Assert.IsTrue(searchPage.CaseSaveSearchButton.Enabled, "Save button should be enabled");
            searchPage.CaseSaveSearchButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            searchPage.SearchNameTextbox.SendKeys("E2ESavedSearch");
            Assert.IsTrue(searchPage.SavedSearchButton.Enabled);
            searchPage.SavedSearchButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            Assert.True(searchPage.CaseSearchHeaderTitle.Text.Contains("E2ESavedSearch"));

            var familyId = _summaryData.Case.Family.Name;
            searchPage.References.CaseFamily.EnterAndSelect(familyId);
            searchPage.PresentationButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            searchPage.UseDefaultCheckbox.WithJs().Click();
            searchPage.Presentation.SearchColumnTextBox.SendKeys("Acceptance Date");
            Assert.AreEqual("Acceptance Date", searchPage.Presentation.SearchColumn.Text);
            var jsExecutable = From.EmbeddedAssets("drag_and_drop_helper.js");
            jsExecutable = jsExecutable + "$('#availableColumns li span').simulateDragDrop({ dropTarget: '#KendoGrid tbody'});" ;
            ((IJavaScriptExecutor)driver).ExecuteScript(jsExecutable);
            searchPage.Presentation.EditSearchCriteriaButton.ClickWithTimeout();
            searchPage.MoreItemButton.Click();
            driver.FindElement(By.XPath("//span[contains(.,'Save as')]")).WithJs().Click();
            driver.WaitForAngularWithTimeout();
            searchPage.SearchNameTextbox.SendKeys("E2ESavedAsSearch");
            Assert.IsTrue(searchPage.SavedSearchButton.Enabled);
            searchPage.SavedSearchButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            Assert.True(searchPage.CaseSearchHeaderTitle.Text.Contains("E2ESavedAsSearch"));
            searchPage.CustomisePresentation.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            Assert.IsTrue(driver.FindElement(By.XPath("//span[contains(text(), 'E2ESavedAsSearch')]")).Displayed);
            searchPage.CaseSearchButton.Click();
            
            Assert.IsTrue(driver.FindElement(By.XPath("//ipx-kendo-grid[@id='searchResults']//kendo-grid//table//thead//th//span[contains(text(),'Acceptance Date')]")).Displayed);
            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "1 record is returned by search");
        }
    }
}
