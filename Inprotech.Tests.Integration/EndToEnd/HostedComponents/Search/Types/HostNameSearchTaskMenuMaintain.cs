using Inprotech.Infrastructure.Web;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search.Types
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostNameSearchTaskMenuMaintain : HostedSearchResultsBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedNameSearchResultsForTaskMenuMaintainName(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.NameSearch);
            AssertMaintainNameTaskMenuSendsNavigationMessage(driver, "MaintainName");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedNameSearchResultsForTaskMenuMaintainNameText(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.NameSearch);
            AssertMaintainNameTextTaskMenuSendsNavigationMessage(driver, "MaintainNameText");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedNameSearchResultsForTaskMenuMaintainNameAttributes(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.NameSearch);
            AssertMaintainNameAttributesTaskMenuSendsNavigationMessage(driver, "MaintainNameAttributes");
        }
    }
}