using Inprotech.Infrastructure.Web;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search.Types
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedCaseSearchResultsDates : HostedSearchResultsBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedCaseSearchResultsForTaskMenuWorkflowWizard(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.CaseSearch);
            AssertWorkflowWizardTaskMenuSendsNavigationMessage(driver, "WorkflowWizard");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedCaseSearchResultsForTaskMenuOpenReminders(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.CaseSearch);
            AssertOpenRemindersTaskMenuSendsNavigationMessage(driver, "OpenReminders");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedCaseSearchResultsForTaskMenuCreateAdHocDate(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.CaseSearch);
            AssertCreateAdHocDateTaskMenuSendsNavigationMessage(driver, "CreateAdHocDate");
        }
    }
}