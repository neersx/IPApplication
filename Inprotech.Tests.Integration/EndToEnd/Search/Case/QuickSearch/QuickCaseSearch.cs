using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.QuickSearch
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class QuickCaseSearch : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox, Ignore = "Pending routing change for the close button")]
        [TestCase(BrowserType.Ie)]
        public void DisplayQuickSearchResult(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var casePrefix = Fixture.AlphaNumericString(15);

                var property = setup.InsertWithNewId(new PropertyType
                {
                    Name = RandomString.Next(5)
                }, x => x.Code);

                var case1 = new CaseBuilder(setup.DbContext).Create(casePrefix + "1", true, propertyType: property);
                var case2 = new CaseBuilder(setup.DbContext).Create(casePrefix + "2", true, propertyType: property);
                var case3 = new CaseBuilder(setup.DbContext).Create(casePrefix + "3", true, propertyType: property);

                return new
                {
                    CasePrefix = casePrefix,
                    CaseIrns = new[] {case1.Irn, case2.Irn, case3.Irn}
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows");

            var searchPageObject = new SearchPageObject(driver);
            searchPageObject.QuickSearchInput().SendKeys(data.CasePrefix);
            searchPageObject.QuickSearchInput().SendKeys(Keys.Enter);

            Assert.AreEqual(data.CasePrefix, searchPageObject.CaseSearchTermLabel, "Search term should be displayed");

            var grid = searchPageObject.ResultGrid;
            var numberOfRows = grid.Rows.Count;
            Assert.AreEqual(data.CaseIrns.Length, numberOfRows, "Matching Number of Records returned");
            Assert.AreEqual(numberOfRows.ToString(), searchPageObject.CaseSearchTotalRecords, "Matching rows number displayed");

            var expectedSortAsc = string.Join(",", data.CaseIrns);
            var expectedSortDesc = string.Join(",", data.CaseIrns.OrderByDescending(_ => _).ToArray());

            CheckSortState(expectedSortAsc);
            CheckSortState(expectedSortDesc);
            
            searchPageObject.CloseButton().Click();
            driver.WaitForAngularWithTimeout();

            var location = driver.Location;
            Assert.IsTrue(location.Contains("/configuration/rules/workflows"), "Navigates back to previous page");

            IEnumerable<string> GetCaseRefs()
            {
                for (var i = 0; i < grid.Rows.Count; i++)
                    yield return grid.CellText(i, 2);
            }

            void CheckSortState(string expected)
            {
                grid.HeaderColumns[2].FindElement(By.XPath("//span[contains(text(),'Case Ref.')]")).ClickWithTimeout();
                driver.WaitForAngularWithTimeout();
                var test = string.Join(",", GetCaseRefs());
                Assert.AreEqual(expected,test );
            }
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void DisplayQuickSearchResultWithFilterInternal(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var casePrefix = Fixture.AlphaNumericString(15);

                var case1 = new CaseBuilder(setup.DbContext).Create(casePrefix + "1");
                var case2 = new CaseBuilder(setup.DbContext).Create(casePrefix + "2");
                var case3 = new CaseBuilder(setup.DbContext).Create(casePrefix + "3");

                return new
                {
                    CasePrefix = casePrefix,
                    CaseIrns = new[] {case1.Irn, case2.Irn, case3.Irn}
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");

            var searchPageObject = new SearchPageObject(driver);
            searchPageObject.QuickSearchInput().SendKeys(data.CasePrefix);
            searchPageObject.QuickSearchInput().SendKeys(Keys.Enter);

            Assert.AreEqual(data.CasePrefix, searchPageObject.CaseSearchTermLabel, "Search term should be displayed");

            var grid = searchPageObject.ResultGrid;
            var numberOfRows = grid.Rows.Count;
            Assert.AreEqual(data.CaseIrns.Length, numberOfRows, "Matching Number of Records returned");
            Assert.AreEqual(numberOfRows.ToString(), searchPageObject.CaseSearchTotalRecords, "Matching rows number displayed");

            // filter by case type
            var caseTypeFilter = new AngularMultiSelectGridFilter(driver, "searchResults", 6);
            caseTypeFilter.Open();
            Assert.AreEqual(3, caseTypeFilter.ItemCount);
            caseTypeFilter.SelectOption(data.CasePrefix + "1");
            caseTypeFilter.SelectOption(data.CasePrefix + "2");
            caseTypeFilter.Filter();
            driver.WaitForAngularWithTimeout();
            Assert.IsTrue(grid.Rows.Count == data.CaseIrns.Length - 1, $"Expected Number of Records returned after first filter to be {data.CaseIrns.Length - 1} but was {grid.Rows.Count}");

            // second filter by country name 
            var countryFilter = new AngularMultiSelectGridFilter(driver, "searchResults", 7);
            countryFilter.Open();
            Assert.True(countryFilter.ItemCount == 2);
            countryFilter.SelectOption(data.CasePrefix + "1");
            countryFilter.Filter();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(1, grid.Rows.Count, $"Expected Number of Records returned after second filter to be 1 but was {grid.Rows.Count}");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void DisplayQuickSearchResultWithFilterExternal(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var casePrefix = Fixture.AlphaNumericString(15);

                var case1 = new CaseBuilder(setup.DbContext).Create(casePrefix + "1");
                var case2 = new CaseBuilder(setup.DbContext).Create(casePrefix + "2");
                var case3 = new CaseBuilder(setup.DbContext).Create(casePrefix + "3");

                return new
                {
                    CasePrefix = casePrefix,
                    CaseIrns = new[] {case1.Irn, case2.Irn, case3.Irn}
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2", "external", "external");

            var searchPageObject = new SearchPageObject(driver);
            searchPageObject.QuickSearchInput().SendKeys(data.CasePrefix);
            searchPageObject.QuickSearchInput().SendKeys(Keys.Enter);

            Assert.AreEqual(data.CasePrefix, searchPageObject.CaseSearchTermLabel, "Search term should be displayed");
        }
    }
}