using Inprotech.Infrastructure.Web;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search.Types
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedWipOverview : HostedSearchResultsBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie, Ignore = "Hybrid section is removed for the time being until Release 17")]
        [TestCase(BrowserType.FireFox)]
        public void HostedWipOverviewResultsLifeCycle(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var queryContextKey = (int)QueryContext.WipOverviewSearch;
            var brimstoneHoldingWIPQueryKey = 41;
            TestHostedSearchResultsLifeCycle(driver, queryContextKey, queryKey: brimstoneHoldingWIPQueryKey);
            AssertClickingIrnSendsNavigationMessage(driver, "NameDetails", 4);
            AssertClickingTotalWipHyperlinkColumnSendsNavigationMessage(driver, "CaseOrNameWIPItems");
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie, Ignore = "Hybrid section is removed for the time being until Release 17")]
        [TestCase(BrowserType.FireFox)]
        public void WipOverviewResultsForCreateMultipleBill(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var queryContextKey = (int)QueryContext.WipOverviewSearch;
            var brimstoneHoldingWIPQueryKey = 41;
            TestHostedSearchResultsLifeCycle(driver, queryContextKey, queryKey: brimstoneHoldingWIPQueryKey);
            AssertCreateBillMenuSendsNavigationMessage(driver, "create-multiple-bill", "Create multiple bills");
        }
    }
}
