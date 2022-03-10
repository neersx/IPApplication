using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search.Types
{
    [Category(Categories.E2E)]
    [TestFixture]   
    public class HostedCaseSearchResultsLifecycle : HostedSearchResultsBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedCaseSearchResultsLifeCycle(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var queryContextKey = (int)QueryContext.CaseSearch;
            AddColumnForDefaultPresentation(queryContextKey, "Total Billed");
            TestHostedSearchResultsLifeCycle(driver, queryContextKey);
            AssertClickingIrnSendsNavigationMessage(driver, "CaseDetails", 3);
            AssertProgramsTaskMenuSendsNavigationMessage(driver, "CaseDetails", KnownCasePrograms.CaseEntry);
            AssertClickingCurrencyHyperlinkColumnSendsNavigationMessage(driver, "CaseBillingItems");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void HostedCaseSearchExternalResultsLifeCycle(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var queryContextKey = (int)QueryContext.CaseSearchExternal;
            var columnSequence = AddColumnForDefaultPresentation(queryContextKey, "Debtor - Code");
            TestHostedSearchResultsLifeCycle(driver, queryContextKey, "external");
            AssertBulkActionMenuDoesNotHaveOpenWithProgram(driver);
            AssertClickingNameSummaryHyperlinkColumnSendsNavigationMessage(driver, "NameSummary", (short)columnSequence.ColumnSequence);
        }
    }
}