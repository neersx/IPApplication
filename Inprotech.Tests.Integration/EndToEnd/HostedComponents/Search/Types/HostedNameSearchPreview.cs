using Inprotech.Infrastructure.Web;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search.Types
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedNameSearchPreview : HostedSearchResultsBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedNameSearchPreviewResult(BrowserType browserType)
        {
            var navigationLocation = "NameDetails";
            var driver = BrowserProvider.Get(browserType);
            var queryContextKey = (int)QueryContext.NameSearch;
            TestHostedSearchResultsLifeCycle(driver, queryContextKey);
            AssertSelectedRecordInPreviewPane(driver, navigationLocation, 4);
        }
    }
}