using Inprotech.Tests.Integration.EndToEnd.Accounting.Time;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class RecordTimeFromCaseSearchList : TimeRecordingFromOtherApps
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CreateTimeEntryFromCaseSearch(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            const string irnStartsWith = "e2e";
            SignIn(driver, $"/#/search-result?q={irnStartsWith}&queryContext=2");
            driver.With<SearchPageObject>(searchResult =>
            {
                searchResult.TaskMenuButton(1).Click();
                driver.WaitForAngular();
                WaitHelper.Wait(100);
                searchResult.RecordTimeMenu.Click();
                driver.WaitForAngular();
            });

            CheckRecordTime(driver, browserType, DbData.Case.Irn, true);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void StartTimerFromCaseSearch(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            const string irnStartsWith = "e2e";
            SignIn(driver, $"/#/search-result?q={irnStartsWith}&queryContext=2");
            driver.With<SearchPageObject>(searchResult =>
            {
                searchResult.TaskMenuButton(1).Click();
                driver.WaitForAngular();
                WaitHelper.Wait(100);
                searchResult.RecordTimeWithTimerMenu.Click();
                driver.WaitForAngular();
            });

            CheckRecordTimeWithTimer(driver, browserType, DbData.Case.Irn, true);
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void StartAndDeleteTimerFromCaseSearch(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            const string irnStartsWith = "e2e";
            SignIn(driver, $"/#/search-result?q={irnStartsWith}&queryContext=2");
            driver.With<SearchPageObject>(searchResult =>
            {
                var popups = new CommonPopups(driver);

                searchResult.TaskMenuButton(0).Click();
                driver.WaitForAngular();
                WaitHelper.Wait(100);
                searchResult.RecordTimeWithTimerMenu.Click();
                driver.WaitForAngular();

                Assert.True(popups.FlashAlert().Displayed, "Timer creation success is displayed");
                DeleteStartedTimer(driver, browserType);
            });
        }
    }
}