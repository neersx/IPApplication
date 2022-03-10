using System;
using System.Linq;
using System.Runtime.CompilerServices;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Integration.Classic.EndToEnd.BulkCaseImport;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Configuration.General.CaseSearchColumn;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Queries;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.CaseSearch
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "16.0")]
    [TestFrom(dbReleaseLevel: DbCompatLevel.Release13)]
    public class CaseSearchRelease13 : IntegrationTest
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
        public void CaseSearchDataManagement(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#");

            DbSetup.Do(setup =>
            {
                var aliasType = setup.DbContext.Set<NameAliasType>().SingleOrDefault(na => na.Code == "_E");

                var name = setup.InsertWithNewId(new Name
                {
                    NameCode = KnownNameWithAliasTypes.NameCodeWithAliasTypesE,
                    LastName = KnownNameWithAliasTypes.NameDescWithAliasTypeE,
                    UsedAs = 4
                });

                setup.InsertWithNewId(new NameAlias
                {
                    Name = name,
                    Alias = "AliasE2E",
                    AliasType = aliasType
                });
            });

            var batchData = new ViewBatchSummaryDbSetup().CreateBatch();

            DbSetup.Do(setup => { setup.InsertWithNewId(new CpaSend {BatchNo = batchData.Item1}); });

            var searchPage = new CaseSearchPageObject(driver);
            ClickCaseSearchBuilder(searchPage);
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");

            searchPage.DataManagement.NavigateTo();

            searchPage.DataManagement.DataSource.EnterAndSelect(KnownNameWithAliasTypes.NameDescWithAliasTypeE);
            searchPage.DataManagement.BatchIdentifier.Input.SendKeys("E2E Batch - 911");

            searchPage.CaseSearchButton.Click();
            Assert.AreEqual("/search-result?queryContext=2", driver.Location, "Should navigate to case search result page");

            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(9, grid.Rows.Count, "9 record is returned by search");

            ClickCaseSearchBuilder(searchPage);

            searchPage.DataManagement.BatchIdentifier.Input.Clear();
            searchPage.DataManagement.BatchIdentifier.Input.SendKeys("E2E Batch");

            searchPage.CaseSearchButton.Click();

            grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(0, grid.Rows.Count, "No record is returned by search");

            ClickCaseSearchBuilder(searchPage);

            searchPage.DataManagement.BatchIdentifier.Input.Clear();
            searchPage.DataManagement.DataSource.Clear();
            searchPage.DataManagement.SentToCpaBatchNo.Value = "501";

            searchPage.CaseSearchButton.Click();
            grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(2, grid.Rows.Count, "2 record is returned by search");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CaseSearchEventsActions(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#");

            var searchPage = new CaseSearchPageObject(driver);
            ClickCaseSearchBuilder(searchPage);
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");
            searchPage.EventsActions.NavigateTo();

            searchPage.EventsActions.EventOperator.Input.SelectByText("Equal To");
            Assert.AreEqual(false, searchPage.EventsActions.EventForCompare.Enabled, "Event for compare picklist should be disabled");

            searchPage.EventsActions.EventOperator.Input.SelectByText("Within Last");
            searchPage.EventsActions.DaysInput.Input("2");

            Assert.AreEqual(true, searchPage.EventsActions.OccurredEvent.IsChecked, "OccurredEvent is defaulted to checked");
            searchPage.EventsActions.OccurredEvent.Click();

            Assert.AreEqual(true, searchPage.EventsActions.DueEvent.IsChecked, "DueEvent is checked in case of OccurredEvent unchecked");
            searchPage.EventsActions.OccurredEvent.Click();

            searchPage.CaseSearchButton.Click();
            Assert.AreEqual("/search-result?queryContext=2", driver.Location, "Should navigate to case search result page");

            driver.WaitForGridLoader();
            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;

            Assert.AreNotEqual(0, grid.Rows.Count, "Expected search to return matching rows");
            var searchResultMatchValues = grid.ColumnValues(2, grid.Rows.Count);
            Assert.True(searchResultMatchValues.Contains(_summaryData.Case.Irn), $"Expected Case {_summaryData.Case.Irn} to be in the search results: {string.Join(",", searchResultMatchValues)}");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CaseSearchOtherDetails(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#");

            var searchPage = new CaseSearchPageObject(driver);
            ClickCaseSearchBuilder(searchPage);
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");
            searchPage.OtherDetails.NavigateTo();

            searchPage.OtherDetails.FileLocation.SendKeys(_summaryData.Case.CaseLocations.First().FileLocation.Name);
            searchPage.OtherDetails.BayNo.SendKeys(_summaryData.Case.CaseLocations.First().BayNo);
            searchPage.OtherDetails.EntitySize.Input.SelectByText(_summaryData.Case.EntitySize.Name);

            searchPage.CaseSearchButton.Click();
            Assert.AreEqual("/search-result?queryContext=2", driver.Location, "Should navigate to case search result page");

            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "One record is returned by search");
            Assert.AreEqual(_summaryData.Case.Irn, grid.Cell(0, 2).Text, "Correct record is returned");
            searchPage.CloseSearch.ClickWithTimeout();
            Assert.AreEqual(_summaryData.Case.EntitySize.Name, searchPage.OtherDetails.EntitySize.Input.SelectedOption.Text.Trim());

            ClickCaseSearchBuilder(searchPage);
            searchPage.CaseSearchClearButton.WithJs().Click();

            searchPage.OtherDetails.InstructionOperator.Input.SelectByText("Equal To");
            searchPage.OtherDetails.Insrtuction.EnterAndSelect(_summaryData.RenewalInstruction);

            searchPage.CaseSearchButton.Click();
            Assert.AreEqual(1, grid.Rows.Count, "One record is returned by search");
            Assert.AreEqual(_summaryData.Case.Irn, grid.Cell(0, 2).Text, "Correct record is returned");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CaseSearchOtherDetailsWithCeasedCountry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#");

            var searchPage = new CaseSearchPageObject(driver);
            ClickCaseSearchBuilder(searchPage);
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");
            searchPage.OtherDetails.NavigateTo();

            searchPage.OtherDetails.Jurisdiction.SendKeys(_summaryData.CeasedCountry.Name);
            searchPage.OtherDetails.BayNo.SendKeys(string.Empty);
            searchPage.OtherDetails.ConfirmModal.Ok().WithJs().Click();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CaseSearchAttributes(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var caseId = _summaryData.Case.Id;
                const string value1 = "Patent1";
                const string value2 = "Product1";
                const string parentTable = "CASES";
                var tableCodePatent = setup.InsertWithNewId(new TableCode {Name = value1, TableTypeId = (int) TableTypes.PatentTechnology});
                setup.InsertWithNewId(new TableAttributes(parentTable, caseId.ToString()) {TableCode = tableCodePatent, SourceTableId = (int) TableTypes.PatentTechnology});

                var tableCodeProducts = setup.InsertWithNewId(new TableCode {Name = value2, TableTypeId = (int) TableTypes.Products});
                setup.InsertWithNewId(new TableAttributes(parentTable, caseId.ToString()) {TableCode = tableCodeProducts, SourceTableId = (int) TableTypes.Products});

                return new
                {
                    AttributeValue1 = value1,
                    AttributeValue2 = value2,
                    AttributeType1 = "Patent Technology",
                    AttributeType2 = "Products"
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#");

            var searchPage = new CaseSearchPageObject(driver);
            ClickCaseSearchBuilder(searchPage);
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");
            searchPage.Attributes.NavigateTo();

            Assert.AreEqual(false, searchPage.Attributes.AttributeType1.IsDisabled, "Attribute Type should be enabled");
            Assert.AreEqual(true, searchPage.Attributes.AttributeOperator1.IsDisabled, "Attribute Operator should be disabled");
            Assert.AreEqual(false, searchPage.Attributes.AttributeValue1.Enabled, "Attribute Value should be disabled");

            Assert.AreEqual(false, searchPage.Attributes.AttributeType2.IsDisabled, "Attribute Type should be enabled");
            Assert.AreEqual(true, searchPage.Attributes.AttributeOperator2.IsDisabled, "Attribute Operator should be disabled");
            Assert.AreEqual(false, searchPage.Attributes.AttributeValue2.Enabled, "Attribute Value should be disabled");

            Assert.AreEqual(false, searchPage.Attributes.AttributeType3.IsDisabled, "Attribute Type should be enabled");
            Assert.AreEqual(true, searchPage.Attributes.AttributeOperator3.IsDisabled, "Attribute Operator should be disabled");
            Assert.AreEqual(false, searchPage.Attributes.AttributeValue3.Enabled, "Attribute Value should be disabled");

            searchPage.Attributes.AttributeType1.Input.SelectByText(data.AttributeType1);
            Assert.AreEqual(false, searchPage.Attributes.AttributeOperator1.IsDisabled, "Attribute Operator should be enabled");
            Assert.AreEqual(false, searchPage.Attributes.AttributeType1.IsDisabled, "Attribute Type should be enabled");
            searchPage.Attributes.AttributeValue1.EnterAndSelect(data.AttributeValue1);

            searchPage.Attributes.AttributeType2.Input.SelectByText(data.AttributeType2);
            Assert.AreEqual(false, searchPage.Attributes.AttributeOperator2.IsDisabled, "Attribute Operator should be enabled");
            Assert.AreEqual(false, searchPage.Attributes.AttributeType2.IsDisabled, "Attribute Type should be enabled");
            searchPage.Attributes.AttributeValue2.EnterAndSelect(data.AttributeValue2);

            searchPage.CaseSearchButton.Click();
            Assert.AreEqual("/search-result?queryContext=2", driver.Location, "Should navigate to case search result page");

            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "One record is returned by search");
            Assert.AreEqual(_summaryData.Case.Irn, grid.Cell(0, 2).Text, "Correct record is returned");
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CaseSearchWithMultiStepMode(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search");
            var searchPage = new CaseSearchPageObject(driver);

            Assert.AreEqual(searchPage.ToggleMultiStepButton.Displayed, true);
            Assert.AreEqual(searchPage.ToggleMultiStepButton.Enabled, true);
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.CssSelector(".cpa-icon-plus-circle")), "Ensure Add button is not visible");

            searchPage.ToggleMultiStepButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(searchPage.AddStepButton.Displayed, true);
            Assert.AreEqual(searchPage.Step1.Displayed, true);

            SearchWithMultiStepModeWithORandAnd(searchPage, driver);
            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "One record is returned by search");

            searchPage.CloseSearch.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            searchPage.Step3.ClickWithTimeout();
            searchPage.RemoveMultiStep.ClickWithTimeout();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Id("step_2")), "Ensure Third Step is not visible");
            searchPage.CaseSearchButton.Click();

            Assert.AreEqual(1, grid.Rows.Count, "One record is returned by search");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CaseSearchWithFamily(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search");

            var familyId = _summaryData.Case.Family.Id;
            var searchPage = new CaseSearchPageObject(driver);
            searchPage.References.CaseFamily.EnterAndSelect(familyId);
            searchPage.CaseSearchButton.Click();

            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "One record is returned by search");
            Assert.AreEqual(_summaryData.Case.Irn, grid.Cell(0, 2).Text, "Correct record is returned");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CaseSearchWithDueDateWindow(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search");

            DbSetup.Do(setup =>
            {
                var searchBuilder = new CaseSearchCaseBuilder(setup.DbContext);
                searchBuilder.SetupColumn( "Due Date",-44);
            });
            var searchPage = new CaseSearchPageObject(driver);

            searchPage.References.CaseReference.SendKeys(_summaryData.Case.Irn);

            Assert.AreEqual(searchPage.DueDateButton.Displayed, true);
            Assert.AreEqual(searchPage.DueDateButton.Enabled, true);

            searchPage.DueDateButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();

            Assert.AreEqual(searchPage.DueDate.EventCheckbox.IsChecked, true);
            Assert.AreEqual(searchPage.DueDate.AdHocsCheckbox.IsChecked, false);
            Assert.AreEqual(searchPage.DueDate.RangeRadioButton.IsChecked, true);
            Assert.AreEqual(searchPage.DueDate.PeriodRadioButton.IsChecked, false);
            Assert.AreEqual(searchPage.DueDate.SearchByDueDateCheckbox.IsChecked, true);
            Assert.AreEqual(searchPage.DueDate.SearchByReminderDateCheckbox.IsChecked, false);

            Assert.AreEqual(searchPage.DueDate.RenewalsCheckbox.IsChecked, true);
            Assert.AreEqual(searchPage.DueDate.NonRenewalsCheckbox.IsChecked, true);
            Assert.AreEqual(searchPage.DueDate.ClosedActionsCheckbox.IsChecked, false);
            Assert.AreEqual(searchPage.DueDate.StaffCheckbox.IsChecked, false);
            Assert.AreEqual(searchPage.DueDate.SignatoryCheckbox.IsChecked, false);
            Assert.AreEqual(searchPage.DueDate.AnyNameCheckbox.IsChecked, false);

            searchPage.DueDate.PeriodRadioButton.Input.WithJs().Click();
            searchPage.DueDate.FromPeriod.Input.SendKeys("-5");
            searchPage.DueDate.ToPeriod.Input.SendKeys("20");
            searchPage.DueDate.DueDateNameTypePicklist.EnterAndSelect("Signatory");
            searchPage.DueDateSearchButton.Click();

            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "One record is returned by search");
            searchPage.CloseSearch.ClickWithTimeout();
            Assert.AreEqual(searchPage.References.CaseReference.Value(), _summaryData.Case.Irn);
            searchPage.DueDateButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            searchPage.DueDate.PeriodRadioButton.Input.WithJs().Click();
            Assert.AreEqual(searchPage.DueDate.FromPeriod.Input.Value(), "-5");
            Assert.AreEqual(searchPage.DueDate.ToPeriod.Input.Value(), "20");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void RecentCases(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search");

            DbSetup.Do(setup =>
            {
                var searchBuilder = new CaseSearchCaseBuilder(setup.DbContext);
            });
            var searchPage = new CaseSearchPageObject(driver);

            searchPage.References.CaseReference.SendKeys(_summaryData.Case.Irn);
            searchPage.CaseSearchButton.Click();

            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "One record is returned by search");
            searchPage.CloseSearch.ClickWithTimeout();

            driver.Visit(Env.RootUrl + "#/portal2");
            driver.WaitForAngular();
            Assert.IsTrue(searchPage.HomePage.RecentCasesHeader.Displayed);

            var gridRecentCases = searchPage.HomePage.ResultGrid;
            var searchResultValue = gridRecentCases.ColumnValues(0, 0);
            searchPage.HomePage.ClickCaseReference(searchResultValue[0]).ClickWithTimeout();
            Assert.IsTrue(searchPage.HomePage.VerifyCaseReference(searchResultValue[0]).Displayed);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CaseSearchWithPresentationColumn(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#");

            var searchPage = new CaseSearchPageObject(driver);
            ClickCaseSearchBuilder(searchPage);
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");

            searchPage.PresentationButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            searchPage.UseDefaultCheckbox.WithJs().Click();

            var selectedColumnsCount = driver.FindElements(By.XPath("//kendo-grid/div/table/tbody/tr"));
            var lastColumnText = driver.FindElement(By.XPath("//tbody/tr["+selectedColumnsCount.Count+"]/td[1]/span")).Text;
            var jsExecutable = From.EmbeddedAssets("drag_and_drop_helper.js");
            jsExecutable = jsExecutable + "$('#KendoGrid table tbody tr:last-child').simulateDragDrop({ dropTarget: '#KendoGrid table tbody tr:first-child'});" ;
            ((IJavaScriptExecutor)driver).ExecuteScript(jsExecutable);
            Assert.AreEqual(lastColumnText,driver.FindElement(By.XPath("//tbody/tr[1]/td[1]/span")).Text);

            var jsExecutable1 = From.EmbeddedAssets("drag_and_drop_helper.js");
            jsExecutable1 = jsExecutable1 + "$('#KendoGrid table tbody tr:nth-child(4)').simulateDragDrop({ dropTarget: '#availableColumns li span'});" ;
            ((IJavaScriptExecutor)driver).ExecuteScript(jsExecutable1);
            var newSelectedColumnsCount = driver.FindElements(By.XPath("//kendo-grid/div/table/tbody/tr"));
            Assert.AreNotEqual(selectedColumnsCount.Count,newSelectedColumnsCount.Count);

            var availableColumnName1 = driver.FindElement(By.XPath("//ipx-icon-button[1]/parent::*/span[1]")).Text;

            searchPage.Presentation.SearchColumnTextBox.SendKeys(availableColumnName1);
            Assert.AreEqual(availableColumnName1, searchPage.Presentation.SearchColumn.Text);

            var secondRowSelectedColumn = driver.FindElement(By.XPath("//tbody/tr[2]/td[1]/span")).Text;

            var firstSortOrderDropDown = new SelectElement(driver.FindElement(By.XPath("//tbody/tr[1]/td[2]/ipx-dropdown/div/select")));
            firstSortOrderDropDown.SelectByText("1");

            var secondSortOrderDropDown = new SelectElement(driver.FindElement(By.XPath("//tbody/tr[2]/td[2]/ipx-dropdown/div/select")));
            secondSortOrderDropDown.SelectByText("2");

            searchPage.Presentation.SecondHideCheckBox.Click();
            var jsExecutable2 = From.EmbeddedAssets("drag_and_drop_helper.js");
            jsExecutable2 = jsExecutable2 + "$('#availableColumns li span').simulateDragDrop({ dropTarget: '#KendoGrid tbody'});";
            ((IJavaScriptExecutor) driver).ExecuteScript(jsExecutable2);
            searchPage.MoreItemButton.Click();
            driver.FindElement(By.XPath("//span[contains(.,'Make this my default')]")).WithJs().Click();
            Assert.IsTrue(searchPage.UseDefaultCheckbox.IsChecked());
            searchPage.CaseSearchButton.Click();

            Assert.AreEqual("/search-result?queryContext=2", driver.Location, "Should navigate to case search result page");
            
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.XPath("//ipx-kendo-grid[@id='searchResults']//kendo-grid//table//thead//th//span[contains(text(),'"+secondRowSelectedColumn+"')]")), "Ensure Official Number Column is not visible");
            Assert.IsTrue(driver.FindElement(By.XPath("//ipx-kendo-grid[@id='searchResults']//kendo-grid//table//thead//th//span[contains(text(),'"+availableColumnName1+"')]")).Displayed);
            searchPage.CloseSearch.ClickWithTimeout();

            searchPage.MoreItemButton.Click();
            driver.FindElement(By.XPath("//span[contains(.,'Revert to standard default')]")).WithJs().Click();
            Assert.IsTrue(searchPage.UseDefaultCheckbox.IsChecked());
            searchPage.CaseSearchButton.Click();
            Assert.AreEqual("/search-result?queryContext=2", driver.Location, "Should navigate to case search result page");
            Assert.IsTrue(driver.FindElement(By.XPath("//ipx-kendo-grid[@id='searchResults']//kendo-grid//table//thead//th//span[contains(text(),'"+secondRowSelectedColumn+"')]")).Displayed);
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.XPath("//ipx-kendo-grid[@id='searchResults']//kendo-grid//table//thead//th//span[contains(text(),'"+availableColumnName1+"')]")), "Ensure Acceptance Date Column is not visible");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie, Ignore = "https://github.com/SeleniumHQ/selenium/issues/1365")]
        public void GroupingOnCaseSearchResult(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#");

            var searchPage = new CaseSearchPageObject(driver);
            ClickCaseSearchBuilder(searchPage);
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");
            searchPage.References.CaseReference.SendKeys("1234");
            searchPage.CaseSearchButton.Click();
            var drag = driver.FindElement(By.XPath("//kendo-grid/div/table/thead/tr/th[3]"));
            var drop = driver.FindElement(By.TagName("kendo-grid-group-panel"));
            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            var data = grid.Cell(0, 4).Text;
            var act = new Actions(driver);
            act.DragAndDrop(drag, drop).Build().Perform();
            driver.WaitForAngularWithTimeout();
            var dragText = driver.FindElement(By.XPath("//ipx-kendo-grid[@id='searchResults']//kendo-grid//table//thead//tr//th[4]")).Text;
            var dropText = driver.FindElement(By.XPath("//ipx-kendo-grid[@id='searchResults']//kendo-grid-group-panel//div//div//a")).Text;
            Assert.AreNotEqual(dragText, dropText);
            var ResultGrid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(10, ResultGrid.Rows.Count);
            //driver.Wait().ForTrue(() => driver.FindElement(By.XPath("//p[@class='k-reset']")).Displayed);
            //Assert.IsTrue(driver.FindElement(By.XPath("//span[contains(text(),'" + data + "')]")).Displayed);
        }

        void SearchWithMultiStepModeWithORandAnd(CaseSearchPageObject searchPage, NgWebDriver driver)
        {
            searchPage.References.NavigateTo();
            searchPage.References.CaseReference.SendKeys(_summaryData.Case.Irn);
            searchPage.AddStepButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(searchPage.Step2.Displayed, true);
            searchPage.StepOperatorDropDown.Input.SelectByText("AND");
            searchPage.Details.NavigateTo();
            searchPage.Details.PropertyType.EnterAndSelect(_summaryData.Case.PropertyTypeId);
            driver.WaitForAngularWithTimeout();
            searchPage.AddStepButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(searchPage.Step3.Displayed, true);
            searchPage.Details.NavigateTo();
            searchPage.Details.Jursidiction.EnterAndSelect(_summaryData.Case.CountryId);
            searchPage.CaseSearchButton.Click();
        }

        [TestCase(BrowserType.Chrome, Ignore = "e2e-13: Failing")]
        [TestCase(BrowserType.FireFox, Ignore = "e2e-13: Failing")]
        [TestCase(BrowserType.Ie, Ignore = "e2e-13: Failing")]
        public void FormattingNeedsToBeAppliedToColumns(BrowserType browserType)
        {
            InprotechKaizen.Model.Cases.Case @case = null;
            DbSetup.Do(x =>
            {
                var searchBuilder = new CaseSearchCaseBuilder(x.DbContext);
                searchBuilder.SetupColumn( "WIP Balance",-24);
                @case = new CaseBuilder(x.DbContext).Create();
                var entityName = new NameBuilder(x.DbContext).Create("E2E-Entity");
                var staffName = new NameBuilder(x.DbContext).CreateStaff();

                x.Insert(new SpecialName(true, entityName));
                x.Insert(new TransactionHeader
                {
                    StaffId = staffName.Id,
                    EntityId = entityName.Id,
                    TransactionId = 1,
                    EntryDate = DateTime.Now.Date,
                    TransactionDate = DateTime.Now.Date,
                    UserLoginId = Fixture.String(10)
                });
                x.Insert(new WorkHistory
                {
                    CaseId = @case.Id,
                    Status = TransactionStatus.Active,
                    MovementClass = MovementClass.Entered,
                    LocalValue = 300,
                    EntityId = entityName.Id,
                    TransactionId = 1,
                    WipSequenceNo = 1,
                    HistoryLineNo = 1,
                    TransDate = DateTime.Now.Date.AddDays(-1)
                });
                x.Insert(new WorkInProgress
                {
                    CaseId = @case.Id,
                    Status = TransactionStatus.Active,
                    Balance = 500,
                    EntityId = entityName.Id,
                    TransactionId = 1,
                    TransactionDate = DateTime.Now.Date.AddDays(-1)
                });
                x.DbContext.SaveChanges();
            });
            
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search");
            var searchPage = new CaseSearchPageObject(driver);
            searchPage.References.CaseReference.SendKeys(@case.Irn);
            searchPage.CaseSearchButton.ClickWithTimeout();
            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            var wipBalance = driver.FindElement(By.XPath("//a[text()='" + @case.Irn + "']/../../../following-sibling::td/span/span//span")).Text;
            Assert.AreEqual(1, grid.Rows.Count, "1 record is returned by search");
            Assert.True(wipBalance.IndexOf("500", StringComparison.Ordinal)>-1);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void NavigationFromCaseSearchToCaseViewAndThenQuickSearch(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search");
            InprotechKaizen.Model.Cases.Case case1 = null, case2 = null, case3 = null;
            DbSetup.Do(x =>
            {
                case1 = new CaseBuilder(x.DbContext).Create("e2e");
                case2 = new CaseBuilder(x.DbContext).Create("e2e1");
                case3 = new CaseBuilder(x.DbContext).Create("e2e3");
            });
            var searchPage = new CaseSearchPageObject(driver);
            searchPage.References.CaseReference.SendKeys(case1.Irn);
            searchPage.CaseSearchButton.WithJs().Click();

            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "One record is returned by search");
            grid.Cell(0,2).FindElements(By.TagName("a"))?.First().ClickWithTimeout();
            var pageDescription = searchPage.PageSubTitle();
            Assert.True(pageDescription.Contains(case1.Irn), "Expected the "+ case1.Irn+" in Page Description");

            searchPage.QuickSearchInput.Clear();
            searchPage.QuickSearchInput.SendKeys(case2.Irn);
            searchPage.QuickSearchInput.SendKeys(Keys.Enter);
            pageDescription = searchPage.PageSubTitle();
            Assert.True(pageDescription.Contains(case2.Irn), "Expected the "+case2.Irn+" in Page Description");

            searchPage.QuickSearchInput.Clear();
            searchPage.QuickSearchInput.SendKeys(case3.Irn);
            searchPage.QuickSearchInput.SendKeys(Keys.Enter);
            pageDescription = searchPage.PageSubTitle();
            Assert.True(pageDescription.Contains(case3.Irn), "Expected the "+case3.Irn+" in Page Description");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyMandatoryIconInSelectedColumns(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var userColumnQueryDataItem = x.DbContext.Set<QueryDataItem>().Single(_ => _.ProcedureItemId == "Text" && _.ProcedureName == "csw_ListCase");
                var e2EColumn1 = new QueryColumn {DataItemId = userColumnQueryDataItem.DataItemId, ColumnLabel = "e2e column 1", Description = "e2e description 1", };
                x.Insert(e2EColumn1);
                var queryContextDisplayUrl = new QueryContextColumn {ColumnId = e2EColumn1.ColumnId, ContextId = (int) QueryContext.CaseSearch, IsMandatory = true};
                x.Insert(queryContextDisplayUrl);
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search");
            var searchPage = new CaseSearchPageObject(driver);
            ClickCaseSearchBuilder(searchPage);
            searchPage.PresentationButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            searchPage.UseDefaultCheckbox.WithJs().Click();
            searchPage.Presentation.SearchColumnTextBox.SendKeys("e2e column 1");
            var jsExecutable = From.EmbeddedAssets("drag_and_drop_helper.js");
            jsExecutable = jsExecutable + "$('#availableColumns li span').simulateDragDrop({ dropTarget: '#KendoGrid tbody'});" ;
            ((IJavaScriptExecutor)driver).ExecuteScript(jsExecutable);
            Assert.AreEqual("e2e column 1",driver.FindElement(By.XPath("//tbody/tr[1]/td[1]/span")).Text);
            Assert.IsTrue(driver.FindElement(By.XPath("//tbody/tr[1]/td[1]/span[2][contains(@class,'cpa cpa-icon-lock')]")).Displayed);
            
            searchPage.Presentation.SearchColumnTextBox.Clear();
            searchPage.Presentation.RefreshButton.ClickWithTimeout();
            var selectedColumnsCount = driver.FindElements(By.XPath("//kendo-grid/div/table/tbody/tr"));
            driver.FindElement(By.XPath("//kendo-grid/div/table/tbody/tr[1]")).ClickWithTimeout();
            var jsExecutable1 = From.EmbeddedAssets("drag_and_drop_helper.js");
            jsExecutable1 = jsExecutable1 + "$('#KendoGrid table tbody tr:first-child').simulateDragDrop({ dropTarget: '#availableColumns li span'});" ;
            ((IJavaScriptExecutor)driver).ExecuteScript(jsExecutable1);
            var newSelectedColumnsCount = driver.FindElements(By.XPath("//kendo-grid/div/table/tbody/tr"));
            Assert.AreEqual(newSelectedColumnsCount.Count,selectedColumnsCount.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CaseReferenceFilter(BrowserType browserType)
        {
            InprotechKaizen.Model.Cases.Case @case = null;
            DbSetup.Do(x =>
            {
                @case = new CaseBuilder(x.DbContext).Create();
            });

            var driver = BrowserProvider.Get(browserType);
            var searchPage = new CaseSearchPageObject(driver);
            SignIn(driver, "/#");
            ClickCaseSearchBuilder(searchPage);
            searchPage.CaseSearchButton.Click();
            Assert.AreEqual("/search-result?queryContext=2", driver.Location, "Should navigate to case search result page");

            searchPage.PresentationButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            searchPage.Presentation.SearchColumnTextBox.SendKeys("Case Ref.");
            searchPage.SimulateDragDrop(searchPage.AvailableColumns, searchPage.SelectedColumnsGrid);
            searchPage.CaseSearchButton.Click();

            driver.WaitForGridLoader();
            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;

            grid.FilterColumnByName("Case Ref.");
            grid.FilterOption(@case.Irn);
            grid.DoFilter();
            Assert.AreEqual(grid.Rows.Count, 1, "Row with matching filter value is returned");
        }
    }
}
