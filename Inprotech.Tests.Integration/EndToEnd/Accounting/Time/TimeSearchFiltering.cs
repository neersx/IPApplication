using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Names;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeSearchFiltering : TimeSearchBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void SearchFilters(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            page.SearchButton.Click();

            var search = new TimeSearchPage(driver);

            CheckDefaultValues(search);

            search.IsUnposted.Click();
            Assert.True(search.IsPosted.IsChecked, "Expected Posted to be checked when Unposted is unchecked");
            search.IsPosted.Click();
            Assert.True(search.IsUnposted.IsChecked, "Expected Unposted to be checked when Posted is unchecked");
            search.IsPosted.Click();
            Assert.True(search.IsPosted.IsChecked && search.IsUnposted.IsChecked, "Expected Posted and Unposted to remain checked");

            search.FromDate.GoToDate(-1);
            search.ToDate.GoToDate(1);

            search.SearchButton.ClickWithTimeout();
            var searchResults = search.SearchResults;
            Assert.AreEqual(10, searchResults.Rows.Count, "Expected only matching records to be returned and displayed");
            Assert.True(searchResults.ColumnValues(2, searchResults.Rows.Count, true).All(_ => !string.IsNullOrWhiteSpace(_)), "Expected all records to have a Start Date");
            Assert.True(search.PostedIcon(4).Displayed && search.IsRowMarkedAsPosted(4), "Expected posted rows to be styled and indicated by an icon");
            Assert.True(search.IncompleteIcon(5).Displayed && search.IncompleteIcon(6).Displayed, "Expected incomplete rows to be marked by an icon");
            search.CheckTimeValues(false);
            Assert.True(search.CaseLink(1).Displayed & search.NameLink(1).Displayed, "Expected Case and Name Link to be displayed for normal entries");
            Assert.True(search.CaseLink(2).Displayed && search.NameLink(2).Displayed, "Expected Case and Name Link to be displayed for continued entries");
            Assert.True(search.CaseLink(5).Displayed && search.NameLink(5).Displayed, "Expected Case and Name Link to be displayed for posted entries");
            Assert.True(search.NameLink(0).Displayed, "Expected Name Link to be displayed for debtor-only entries");
            search.ClearButton.Click();

            CheckDefaultValues(search);

            search.Entity.Input.SelectByIndex(1);
            Assert.True(search.IsPosted.IsChecked && search.IsPosted.IsDisabled && search.IsUnposted.IsDisabled, "Expected Posted to be checked and both checkboxes disabled when Entity is selected");
            Assert.False(search.IsUnposted.IsChecked, "Expected Unposted to be unchecked when Entity is selected");

            search.Cases.OpenPickList();
            search.Cases.SearchFor("e2e");
            search.Cases.SearchGrid.SelectRow(0);
            search.Cases.SearchGrid.SelectRow(1);
            search.Cases.Apply();
            Assert.AreEqual(2, search.Cases.Tags.Count(), "Expected selected cases to be displayed");
            Assert.True(search.Cases.Tags.Any(_ => _ == DbData.Case.Irn), $"Expected case {DbData.Case.Irn} to be selected");
            Assert.True(search.Cases.Tags.Any(_ => _ == DbData.NewCaseSameDebtor.Irn), $"Expected case {DbData.NewCaseSameDebtor.Irn} to be selected");
            
            search.SearchButton.ClickWithTimeout();
            search.CheckTimeValues(true);
            
            search.ClearButton.Click();
            CheckDefaultValues(search);

            search.Name.Typeahead.SendKeys("e2e");
            search.Name.Typeahead.SendKeys(Keys.ArrowDown);
            search.Name.Typeahead.SendKeys(Keys.Enter);
            driver.WaitForAngularWithTimeout();
            Assert.True(search.AsDebtor.IsChecked && !search.AsDebtor.IsDisabled && search.AsInstructor.IsChecked && !search.AsInstructor.IsDisabled, "Expected Name options to both be checked and enabled");
            search.SearchButton.Click();
            Assert.True(search.SearchResults.ColumnValues(4, search.SearchResults.Rows.Count).All(_ => _.Contains(DbData.Debtor.LastName)), $"Expected all values within the column to contain {DbData.Debtor.LastName}");

            search.ClearButton.Click();
            CheckDefaultValues(search);

            var narrativeSearch = "narrative";
            search.Narrative.SendKeys(narrativeSearch);
            search.SearchButton.Click();
            Assert.True(search.SearchResults.ColumnValues(10, search.SearchResults.Rows.Count).All(_ => _.Contains(narrativeSearch)), $"Expected all values within the Narrative Text to contain {narrativeSearch}");

            search.ClearButton.Click();
            CheckDefaultValues(search);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void FilteringSearchResults(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            page.SearchButton.Click();

            var search = new TimeSearchPage(driver);
            search.SearchButton.ClickWithTimeout();

            CheckFilter(driver, search.SearchResults, 2, DateTime.Today.ToString("dd-MMM-yyyy"));
            CheckFilter(driver, search.SearchResults, 3, "e2e");
            CheckFilter(driver, search.SearchResults, 4, "E2EOrg");
            CheckFilter(driver, search.SearchResults, 5, "E2E_WIP");

            search.Period.Input.SelectByIndex(0);
            Assert.True(search.ToDate.Input.Text.IsNullOrEmpty(), "Ensure the to date is not defaulted when Date Range is selected");

            var today = DateTime.Today;
            var startOfWeek = today.AddDays(-(int)today.DayOfWeek + 1);
            var endOfWeek = startOfWeek.AddDays(7).AddSeconds(-1);
            search.Period.Input.SelectByIndex(1);

            Assert.AreEqual(startOfWeek.ToString("dd-MMM-yyyy"), search.FromDate.Value, "Ensure the from date is defaulted to start of week");
            Assert.AreEqual(endOfWeek.ToString("dd-MMM-yyyy"), search.ToDate.Value, "Ensure the to date is defaulted to end of week");
        }

        void CheckFilter(NgWebDriver driver, AngularKendoGrid grid, int colIndex, string filter)
        {
            var caseFilter = new AngularMultiSelectGridFilter(driver, "timeSearchResults", colIndex);
            caseFilter.Open();
            var filterCount = caseFilter.ItemCount;
            caseFilter.SelectOption(filter);
            caseFilter.Filter();
            Assert.True(grid.ColumnValues(colIndex, grid.Rows.Count).All(_ => _.Contains(filter)), $"Expected all values within the column to contain {filter}");
            caseFilter.Open();
            Assert.AreEqual(filterCount, caseFilter.ItemCount, $"Expected filter to have {filterCount} options but only had {caseFilter.ItemCount}");
            caseFilter.Clear();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ColumnSelection(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            page.SearchButton.Click();

            var search = new TimeSearchPage(driver);
            search.SearchButton.ClickWithTimeout();

            TimeGridHelper.TestColumnSelection(search.SearchResults, search.ColumnSelector, driver,
                                               new Dictionary<string, string>
                                               {
                                                   {"totalUnits", "Units"},
                                                   {"chargeOutRate", "Charge Rate"},
                                                   {"foreignDiscount", "Foreign Discount"},
                                                   {"notes", "Notes"}
                                               });

            var columnSelector = search.ColumnSelector;
            columnSelector.ColumnMenuButtonClick();
            columnSelector.ToggleGridColumn("totalUnits");
            columnSelector.ToggleGridColumn("name");
            columnSelector.ColumnMenuButtonClick();
            Assert.True(search.SearchResults.HeaderColumnsFields.Contains("totalUnits"), "Units Column is displayed");
            Assert.False(search.SearchResults.HeaderColumnsFields.Contains("name"), "Name Column is not displayed as per local saved setting");

            var newTab = OpenAnotherTab(driver, "/#/accounting/time/query", DbData.User.Username, DbData.User.Password, browserType);
            driver.SwitchTo().Window(newTab);    
            Assert.False(search.SearchResults.HeaderColumnsFields.Contains("name"), "Name Column is not displayed as per local saved setting");
            Assert.Contains("totalUnits", search.SearchResults.HeaderColumnsFields, "Units Column is displayed as per local saved setting");

            columnSelector.ColumnMenuButtonClick();
            columnSelector.ResetButton.WithJs().Click();
        }

        void CheckDefaultValues(TimeSearchPage search)
        {
            Assert.AreEqual(DateTime.Today.AddMonths(-1).ToString("dd-MMM-yyyy"), search.FromDate.Value, $"Expected From Date to be defaulted to today's date {DateTime.Today.AddMonths(-1):dd-MMM-yyyy}");
            Assert.AreEqual(string.Empty, search.ToDate.Value);
            Assert.True(search.IsUnposted.IsChecked, "Expected Unposted to be checked by default");
            Assert.True(search.IsPosted.IsChecked, "Expected Posted to be checked by default");
            Assert.AreEqual(DbData.StaffName.Formatted(), search.StaffName.InputValue, $"Expected Staff to be defaulted to {DbData.StaffName}");
            Assert.IsEmpty(search.Cases.InputValue, "Expected Cases to be cleared");
            Assert.AreEqual(string.Empty, search.Name.InputValue, "Expected Name to be cleared");
            Assert.AreEqual(string.Empty, search.Activity.InputValue, "Expected Activity to be cleared");
            Assert.AreEqual(string.Empty, search.Entity.Value, "Expected Entity to be cleared");
            Assert.True(!search.AsDebtor.IsChecked && search.AsDebtor.IsDisabled && !search.AsInstructor.IsChecked && search.AsInstructor.IsDisabled, "Expected Name options to both be unchecked and disabled");
            Assert.AreEqual(string.Empty, search.Narrative.WithJs().GetInnerText(), "Expected Narrative Search to be blank");
        }
    }
}