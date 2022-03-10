using Inprotech.Infrastructure.Web;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search.Types
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedNameSearchTaskMenuCreateAndExport : HostedSearchResultsBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedNameSearchResultsForTaskMenuAdHocDateForName(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.NameSearch);
            AssertAdHocDateForNameTaskMenuSendsNavigationMessage(driver, "AdHocDateForName");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedNameSearchResultsForTaskMenuCreateContactActivity(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.NameSearch);
            AssertCreateContactActivityTaskMenuSendsNavigationMessage(driver, "NewActivityWizardForName");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedNameSearchSelectedExport(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var queryContextKey = (int)QueryContext.NameSearch;
            TestHostedSearchResultsLifeCycle(driver, queryContextKey);
            AssertSelectedRecordExport(driver);
        }
    }
}
