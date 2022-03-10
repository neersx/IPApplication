using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaInheritance;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaSearch
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CriteriaSearch : IntegrationTest
    {
        [Category(Categories.E2E)]
        [TestFixture]
        public class Searching : IntegrationTest
        {
            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.Ie)]
            [TestCase(BrowserType.FireFox)]
            public void SearchByCriteria(BrowserType browserType)
            {
                CriteriaSearchDbSetup.Result dataFixture;
                using (var setup = new CriteriaSearchDbSetup())
                {
                    dataFixture = setup.Setup();
                }

                var driver = BrowserProvider.Get(browserType);
                SignIn(driver, "/#/configuration/rules/workflows");
                driver.FindRadio("search-by-criteria").Click();

                var searchResults = new KendoGrid(driver, "searchResults");
                var searchOptions = new SearchOptions(driver);
                var pl = new PickList(driver).ByName("ip-search-by-criteria", "criteria");

                #region do search with no filtering

                searchOptions.SearchButton.ClickWithTimeout();
                Assert.IsTrue(searchResults.Rows.Count > 1);

                #endregion

                pl.Typeahead.WithJs().ScrollIntoView();

                #region do search by criteria number

                pl.EnterAndSelect(dataFixture.CriteriaNo.ToString());
                searchOptions.SearchButton.ClickWithTimeout();
                Assert.AreEqual(1, searchResults.Rows.Count);

                #endregion
            }
        }

        [Category(Categories.E2E)]
        [TestFixture]
        public class NavigateByIcon : IntegrationTest
        {
            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.Ie)]
            [TestCase(BrowserType.FireFox)]
            public void HighestCriteriaAndNavigateByIcon(BrowserType browserType)
            {
                var data = DbSetup.Do(setup =>
                {
                    var criteriaBuilder = new CriteriaBuilder(setup.DbContext);
                    var parent = criteriaBuilder.Create();
                    var child = criteriaBuilder.Create();

                    setup.Insert(new Inherits(child.Id, parent.Id));

                    return new
                    {
                        ParentId = parent.Id.ToString(),
                        ChildId = child.Id.ToString()
                    };
                });

                var driver = BrowserProvider.Get(browserType);
                SignIn(driver, "/#/configuration/rules/workflows");
                driver.FindRadio("search-by-criteria").Click();

                var searchResults = new KendoGrid(driver, "searchResults");
                var pl = new PickList(driver).ByName("ip-search-by-criteria", "criteria");
                pl.EnterAndSelect(data.ParentId);

                var searchOptions = new SearchOptions(driver);
                searchOptions.SearchButton.TryClick();

                var icon = searchResults.LockedCell(0, 1).FindElement(By.TagName("a"));
                var tooltip = icon.GetAttribute("uib-tooltip");

                Assert.AreEqual("Top parent in tree", tooltip);

                icon.Click();
                var page = new CriteriaInheritancePage(driver);

                Assert.True(page.PageTitle().Contains("Inheritance"));
                Assert.True(driver.Url.Contains("?criteriaIds=" + data.ParentId));
            }
        }
    }
}