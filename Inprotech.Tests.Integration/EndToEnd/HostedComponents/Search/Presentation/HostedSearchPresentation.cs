using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search.Presentation
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedSearchPresentation : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedCaseSearchPresentationLifeCycle(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var queryContextKey = (int) QueryContext.CaseSearch;
            TestHostedPresentationLifeCycle(driver, queryContextKey);
        }

        protected void TestHostedPresentationLifeCycle(NgWebDriver driver, int queryContextKey, string user = "internal", int? queryKey = null)
        {
            SignIn(driver, $"/#/deve2e/hosted-test", user, user);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Search Presentation";
            driver.WaitForAngular();
            page.WaitForLifeCycleAction("onInit");
            page.CallOnInit(new PostMessage { QueryContextKey = queryContextKey, QueryKey = queryKey });
            page.WaitForLifeCycleAction("onViewInit");
            driver.DoWithinFrame(() =>
            {
                Assert.True(page.MoreItemButton.Displayed);
            });
        }
    }
}
