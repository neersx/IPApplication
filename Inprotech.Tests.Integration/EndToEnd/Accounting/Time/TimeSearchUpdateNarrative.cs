using System.Linq;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeSearchUpdateNarrative : TimeSearchBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SelectAllAndChangeNarrative(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time/query", DbData.User.Username, DbData.User.Password);

            var searchPage = new TimeSearchPage(driver);
            searchPage.PerformSearch();

            searchPage.SearchResults.ActionMenu.OpenOrClose();
            searchPage.SearchResults.ActionMenu.SelectAll();
            searchPage.UpdateNarrative.Click();

            var updateNarrativeDialog = new UpdateNarrativeModal(driver);
            Assert.False(updateNarrativeDialog.ApplyButton.Enabled);

            updateNarrativeDialog.Narrative.EnterAndSelect("Conference");
            Assert.True(updateNarrativeDialog.ApplyButton.Enabled);
            driver.WaitForAngular();

            updateNarrativeDialog.Apply();
            
            var popups = new CommonPopups(driver);
            popups.WaitForFlashAlert();
            driver.WaitForAngular();

            Assert.True(searchPage.SearchResults.ColumnValues(10).All(_ => _ == "Conference with"), "All the narratives in the search result are set to the new narrative");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SelectItemsAndUpdateNarrative(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time/query", DbData.User.Username, DbData.User.Password);

            var searchPage = new TimeSearchPage(driver);
            searchPage.PerformSearch();

            searchPage.SearchResults.ActionMenu.OpenOrClose();
            searchPage.SearchResults.SelectRow(0);
            searchPage.SearchResults.ActionMenu.OpenOrClose();
            searchPage.UpdateNarrative.Click();

            var updateNarrativeDialog = new UpdateNarrativeModal(driver);
            Assert.True(updateNarrativeDialog.NarrativeText.GetAttribute("value").StartsWith("short-narrative"));

            var newNarrative = "Some New Narrative!!";
            updateNarrativeDialog.NarrativeText.Clear();
            updateNarrativeDialog.NarrativeText.SendKeys(newNarrative);
            updateNarrativeDialog.Apply();

            var popups = new CommonPopups(driver);
            popups.WaitForFlashAlert();
            driver.WaitForAngular();

            Assert.AreEqual(newNarrative, searchPage.SearchResults.CellText(0, 10), "The narrative for the first row is updated to the new narrative");
        }
    }
}