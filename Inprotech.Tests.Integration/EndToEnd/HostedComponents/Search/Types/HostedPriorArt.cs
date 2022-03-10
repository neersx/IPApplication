using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search.Types
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedPriorArt : HostedSearchResultsBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedPriorArtResultsLifeCycle(BrowserType browserType)
        {
            var navigationLocation = "CaseDetails";
            var driver = BrowserProvider.Get(browserType);
            var queryContextKey = (int)QueryContext.PriorArtSearch;
            SignIn(driver, $"/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);

            page.ComponentDropdown.Text = "Hosted Search Results";
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.CallOnInit(new PostMessage() { QueryContextKey = queryContextKey, QueryKey = null });
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() => Assert.Throws<NoSuchElementException>(() => page.HostedSearchPage.CloseButton(), "Close Button Is not displayed"));
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedPriorArtSearchResultsForTaskMenuMaintainPriorArt(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.PriorArtSearch);
            AssertMaintainPriorArtTaskMenuSendsNavigationMessage(driver, "MaintainPriorArt");
        }
    }
}
