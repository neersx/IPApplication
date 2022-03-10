using Inprotech.Infrastructure.Web;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search.Types
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedCaseSearchCaseOperations : HostedSearchResultsBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedCaseSearchResultsForTaskMenuOpenInFirstToFile(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.CaseSearch);
            AssertFirstToFileTaskMenuSendsNavigationMessage(driver, "OpenFirstToFile");
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedCaseSearchResultsForTaskMenuOpenCopyCase(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.CaseSearch);
            AssertCopyCaseTaskMenuSendsNavigationMessage(driver, "CopyCase");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedCaseSearchResultsForTaskMenuMaintainCaseDetails(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.CaseSearch);
            AssertMaintainCaseDetailsTaskMenuSendsNavigationMessage(driver, "MaintainCase");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedCaseSearchResultsForTaskMenuMaintainFileLocation(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.CaseSearch);
            AssertMaintainFileLocationTaskMenuSendsNavigationMessage(driver, "MaintainFileLocation");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedCaseSearchResultsForTaskMenuRequestCaseFile(BrowserType browserType)
        {
            var rfIdValue = GetRFIDSiteControlValue();
            if (!rfIdValue)
                SetRFIDSiteControl(true);
            var driver = BrowserProvider.Get(browserType);
            TestHostedSearchResultsLifeCycle(driver, (int)QueryContext.CaseSearch);
            AssertRequestCaseFileTaskMenuSendsNavigationMessage(driver, "RequestCaseFile");
            if (!rfIdValue)
                SetRFIDSiteControl(false);
        }
    }
}
