using Inprotech.Infrastructure.Web;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search.Types
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedCaseSearchResultsTimeAndBilling : HostedSearchResultsBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedCaseSearchResultsForTaskMenuRecordWip(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.CaseSearch);
            AssertRecordWipTaskMenuSendsNavigationMessage(driver, "RecordWip");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedCaseSearchResultsForTaskMenuDocketingWizard(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.CaseSearch);
            AssertDocketingWizardTaskMenuSendsNavigationMessage(driver, "DocketingWizard");
        }
    }
}