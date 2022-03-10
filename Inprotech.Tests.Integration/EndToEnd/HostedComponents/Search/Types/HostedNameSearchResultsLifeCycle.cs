using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search.Types
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedNameSearchResultsLifeCycle : HostedSearchResultsBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedNameInternalSearchResultsLifeCycle(BrowserType browserType)
        {
            var navigationLocation = "NameDetails";
            var driver = BrowserProvider.Get(browserType);
            var queryContextKey = (int)QueryContext.NameSearch;
            TestHostedSearchResultsLifeCycle(driver, queryContextKey);
            AssertClickingIrnSendsNavigationMessage(driver, navigationLocation, 4);
            AssertBulkActionMenuSendsNavigationMessage(driver, navigationLocation, KnownNamePrograms.NameEntry);

        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedNameExternalSearchResultsLifeCycle(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var queryContextKey = (int)QueryContext.NameSearchExternal;
            TestHostedSearchResultsLifeCycle(driver, queryContextKey, "external");
            AssertBulkActionMenuDoesNotHaveOpenWithProgram(driver);
        }
    }
}