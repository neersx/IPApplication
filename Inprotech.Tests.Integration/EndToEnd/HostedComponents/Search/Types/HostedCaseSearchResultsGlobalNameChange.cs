using Inprotech.Infrastructure.Web;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search.Types
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedCaseSearchResultsGlobalNameChange : HostedSearchResultsBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedCaseSearchResultsForGlobalNameChange(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.CaseSearch);
            AssertGlobalNameChangeMenuSendsNavigationMessage(driver, "GlobalNameChange");
        }
    }
}