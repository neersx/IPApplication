using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions
{

    [Category(Categories.E2E)]
    [TestFixture]
    public class JurisdictionMaintenanceDetail : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SearchAndViewJurisdiction(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var scenario = new Scenario().Prepare();

            var user = new Users()
                        .WithPermission(ApplicationTask.MaintainJurisdiction, Deny.Execute)
                        .WithPermission(ApplicationTask.ViewJurisdiction)
                        .Create();

            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);

            // Searching Jurisdictions

            var searchOptions = new SearchOptions(driver);
            searchOptions.SearchButton.ClickWithTimeout();
            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(20, searchResults.Rows.Count, "Blank search returns all available countries");

            var searchText = driver.FindElement(By.Id("search-options-criteria"));
            searchText.SendKeys(scenario.Searching.Description);
            searchOptions.SearchButton.ClickWithTimeout();
            searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Search by name returns only matching countries.");

            searchOptions.ResetButton.Click();
            searchText.SendKeys(scenario.Searching.Code);
            searchOptions.SearchButton.ClickWithTimeout();
            searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Search by code returns only matching countries.");

            // Filtering Jurisdictions

            searchOptions.ResetButton.Click();
            searchText.SendKeys(scenario.Filtering.Name);
            searchOptions.SearchButton.ClickWithTimeout();
            searchResults = new KendoGrid(driver, "searchResults");

            var typefilter = new MultiSelectGridFilter(driver, "searchResults", "type");
            typefilter.Open();
            Assert.AreEqual(scenario.Filtering.FilterCount, typefilter.ItemCount, "Ensure that correct number of type filters are retrieved");

            typefilter.SelectOption(scenario.Filtering.Type);
            typefilter.Filter();
            Assert.AreEqual(1, searchResults.Rows.Count, "Correctly filters by type");

            searchOptions.ResetButton.Click();
            typefilter.Open();
            Assert.AreEqual(0, typefilter.CheckedItemCount, "Filters are cleared when search is reset");

            // Viewing an Address jurisdiction
            searchText.SendKeys(scenario.Searching.Code);
            searchOptions.SearchButton.ClickWithTimeout();
            searchResults = new KendoGrid(driver, "searchResults");
            searchResults.Rows[0].FindElements(By.TagName("td"))[1].FindElement(By.TagName("a")).ClickWithTimeout();

            var pageDetails = new JurisdictionDetailPage(driver);
            Assert.True(pageDetails.JurisdictionName().EndsWith(scenario.Details.Name),
                            "The details view displays correct information by matching the header title.");

            Assert.AreEqual(scenario.Details.PostalName, pageDetails.OverviewTopic.PostalName(driver).Value(), "The correct Postal Name is displayed.");
            Assert.AreEqual(scenario.Details.InformalName, pageDetails.OverviewTopic.InformalName(driver).Value(), "The correct Informal Name is displayed.");
            Assert.AreEqual(scenario.Details.Adjective, pageDetails.OverviewTopic.Adjective(driver).Value(), "The correct Country Adjective is displayed.");
            Assert.AreEqual(scenario.Details.IsdCode, pageDetails.OverviewTopic.IsdCode(driver).Value(), "The correct ISD Code is displayed.");

            Assert.IsTrue(driver.IsElementPresent(By.Name("stateLabel")));
            Assert.IsTrue(driver.IsElementPresent(By.Name("defaultCurrency")));
            Assert.IsTrue(driver.IsElementPresent(By.Id("statesGrid")));
            Assert.IsTrue(driver.IsElementPresent(By.Id("validCombinationAlert")));
            Assert.IsTrue(driver.IsElementPresent(By.Id("localClasses")));

            var statesGrid = new KendoGrid(driver, "statesGrid");
            Assert.AreEqual(statesGrid.Rows.Count, 2, "The matching states for the jurisdiction are displayed.");

            pageDetails.GroupsTopic.NavigateTo();
            var groupMembers = pageDetails.GroupsTopic.GroupMembers(driver);
            Assert.AreEqual(1, groupMembers.Rows.Count);
            Assert.AreEqual(scenario.Details.GroupName, groupMembers.CellText(0, 1));

            Assert.IsFalse(driver.IsElementPresent(By.Id("statusFlagsGrid")));

            Assert.IsNotNull(pageDetails.DefaultsTopic);

            pageDetails.TextsTopic.NavigateTo();
            var texts = pageDetails.TextsTopic.List(driver);
            Assert.AreEqual(1, texts.Rows.Count, "Only matching text is displayed.");
            Assert.AreEqual(scenario.Details.Text, texts.CellText(0, 2), "The correct Text is displayed.");

            pageDetails.AttributesTopic.NavigateTo();
            var attributes = pageDetails.AttributesTopic.List(driver);
            Assert.AreEqual(1, attributes.Rows.Count, "Only matching attribute is displayed.");
            Assert.AreEqual(scenario.Details.Attribute, attributes.CellText(0, 1), "The correct Attribute is displayed.");

            // clicking the back button

            pageDetails.LevelUp();
            searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(searchResults.Rows.Count, 1, "The previously matched results are still intact.");
            Assert.AreEqual(searchResults.Rows[0].FindElements(By.TagName("td"))[2].Text, scenario.Details.Name,
                            "The previously returned search results are still intact.");

            // viewing a Group jurisdiction

            searchOptions.ResetButton.Click();
            searchText.SendKeys(scenario.Details.GroupName);
            searchOptions.SearchButton.ClickWithTimeout();

            searchResults = new KendoGrid(driver, "searchResults");
            searchResults.Rows[0].FindElements(By.TagName("td"))[1].FindElement(By.TagName("a")).ClickWithTimeout();

            Assert.True(pageDetails.JurisdictionName().EndsWith(scenario.Details.GroupName),
                            "The details view displays correct information by matching the header title.");

            Assert.IsFalse(driver.IsElementPresent(By.Id("statesGrid")));
            Assert.IsFalse(driver.IsElementPresent(By.Id("addressSettingStateLabel")));
            Assert.IsFalse(driver.IsElementPresent(By.Name("postalName")));
            Assert.IsFalse(driver.IsElementPresent(By.Name("isdCode")));

            Assert.IsTrue(driver.IsElementPresent(By.Id("groups")));
            pageDetails.GroupsTopic.NavigateTo();
            driver.FindRadio("display-groups").Click();
            groupMembers = pageDetails.GroupsTopic.GroupMembers(driver);
            Assert.AreEqual(1, groupMembers.Rows.Count);
            Assert.AreEqual(scenario.Details.Country4Name, groupMembers.CellText(0, 1), "Returns the correct group members.");
            Assert.IsTrue(driver.FindRadio("display-groups").IsChecked, "Display groups by default");

            Assert.IsTrue(driver.IsElementPresent(By.Id("statusFlagsGrid")));
            pageDetails.DefaultsTopic.NavigateTo();
            var stagesGrid = new KendoGrid(driver, "statusFlagsGrid");
            Assert.AreEqual(stagesGrid.Rows.Count, 3, "The matching designation stages for the group jurisdiction are displayed.");
            Assert.IsNotNull(pageDetails.DefaultsTopic);
            Assert.IsTrue(driver.IsElementPresent(By.Name("defaultCurrency")));
            Assert.IsTrue(driver.IsElementPresent(By.Id("validCombinationAlert")));
            Assert.IsTrue(driver.IsElementPresent(By.Id("localClasses")));

            // clicking the back button

            pageDetails.LevelUp();
            searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(searchResults.Rows.Count, 1, "The previously matched results are still intact.");
            Assert.AreEqual(searchResults.Rows[0].FindElements(By.TagName("td"))[2].Text, scenario.Details.GroupName,
                            "The previously returned search results are still intact.");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void NavigateBetweenJurisdictions(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var scenario = new Scenario().Prepare();
            
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainJurisdiction)
                       .WithPermission(ApplicationTask.ViewJurisdiction)
                       .Create();

            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);

            var searchOptions = new SearchOptions(driver);
            var searchText = driver.FindElement(By.Id("search-options-criteria"));
            searchText.SendKeys("e2eCountry");
            searchOptions.SearchButton.ClickWithTimeout();

            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(searchResults.Rows.Count, 4, "All available countries are returned.");

            // view the first jurisdiction in the list
            searchResults.Rows[0].FindElements(By.TagName("td"))[1].FindElement(By.TagName("a")).ClickWithTimeout();

            var pageDetails = new JurisdictionDetailPage(driver);

            Assert.True(pageDetails.JurisdictionName().EndsWith(scenario.Details.Country1Name.ToString()),
                            "Display the details for the selected jurisdiction");

            var detailPage = new DetailPage(driver);
            detailPage.PageNav.NextPage();
            Assert.True(pageDetails.JurisdictionName().EndsWith(scenario.Details.Country2Name.ToString()),
                            "Clicking Next displays the next record from search results");

            detailPage.PageNav.LastPage();
            Assert.True(pageDetails.JurisdictionName().EndsWith(scenario.Details.Country4Name.ToString()),
                            "Clicking Last displays the last record from search results");

            detailPage.PageNav.PrePage();
            Assert.True(pageDetails.JurisdictionName().EndsWith(scenario.Details.Country3Name.ToString()),
                            "Clicking Previous displays the previous record from search results");

            detailPage.PageNav.FirstPage();
            Assert.True(pageDetails.JurisdictionName().EndsWith(scenario.Details.Country1Name.ToString()),
                            "Clicking First displays the first record from search results");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void LinksToValidCombination(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            new Scenario().Prepare();
            SignIn(driver, "/#/configuration/general/jurisdictions");
            var searchOptions = new SearchOptions(driver);
            var searchText = driver.FindElement(By.Id("search-options-criteria"));
            searchText.SendKeys("e2eCountry");
            searchOptions.SearchButton.ClickWithTimeout();

            var searchResults = new KendoGrid(driver, "searchResults");
            searchResults.Rows[0].FindElements(By.TagName("td"))[1].FindElement(By.TagName("a")).ClickWithTimeout();

            var pageDetails = new JurisdictionDetailPage(driver);
            var validCombination = pageDetails.ValidCombinationsTopic();

            driver.ClickLinkToNewBrowserWindow(validCombination.FindElement(By.Id("validCombinationLink")));

            var url = driver.WithJs().GetUrl();

            Assert.True(url.Contains("/validcombination/allcharacteristics"),
                        $"Clicking on the Valid Combination link will take the user to the Valid Combination app but was {url}");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ViewJurisdictionOnly(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            new Scenario().Prepare();

            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainJurisdiction, Deny.Execute)
                       .WithPermission(ApplicationTask.ViewJurisdiction)
                       .Create();

            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);

            var searchOptions = new SearchOptions(driver);
            var searchText = driver.FindElement(By.Id("search-options-criteria"));
            searchText.SendKeys("e2eCountry");
            searchOptions.SearchButton.ClickWithTimeout();

            var searchResults = new KendoGrid(driver, "searchResults");
            // view the first jurisdiction in the list
            searchResults.Rows[0].FindElements(By.TagName("td"))[1].FindElement(By.TagName("a")).ClickWithTimeout(5);

            var pageDetails = new JurisdictionDetailPage(driver);

            Assert.True(pageDetails.OverviewTopic.Notes(driver).IsDisabled(),
                            "Ensure notes field is disabled");
        }
    }
}