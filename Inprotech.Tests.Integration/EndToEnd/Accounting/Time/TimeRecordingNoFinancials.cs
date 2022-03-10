using Inprotech.Infrastructure.Extensions;
using Inprotech.Tests.Integration.DbHelpers;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingNoFinancials : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup(allowWipView: false, allowBillHistory: false, allowReceivables: false);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        TimeRecordingData _dbData;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void NoCaseFinancials(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);
            var caseSummary = new CaseSummaryPageObject(driver);
            Assert.Throws<NoSuchElementException>(() => caseSummary.TotalWorkPerformed(), "Expected Total Work Performed to be hidden");
            Assert.Throws<NoSuchElementException>(() => caseSummary.UnpostedTime(), "Expected Unposted Time to be hidden");
            Assert.Throws<NoSuchElementException>(() => caseSummary.ActiveBudget(), "Expected Budget section to be hidden");
            Assert.Throws<NoSuchElementException>(() => caseSummary.LastInvoiceDate(), "Expected Last Invoiced Dat to be hidden");
            
            Assert.Throws<NoSuchElementException>(() => caseSummary.ReceivableBalanceFor(_dbData.DebtorWithRestriction), "Expected Receivable for first Debtor to be hidden");
            Assert.NotNull(caseSummary.NameLinkFor(_dbData.DebtorWithRestriction), "Expect name link to be displayed for debtor with restriction");
            Assert.True(caseSummary.BillPercentageFor(_dbData.DebtorWithRestriction).Text.TextContains($"{TimeRecordingDbHelper.RestrictedDebtorBillPercentage}%"), "Expect bill percentage to be displayed");
            
            Assert.Throws<NoSuchElementException>(() => caseSummary.ReceivableBalanceFor(_dbData.DebtorWithoutRestriction), "Expected Receivable for second Debtor to be hidden");
            Assert.NotNull(caseSummary.NameLinkFor(_dbData.DebtorWithoutRestriction), "Expect name link to be displayed for debtor with restriction");
            Assert.True(caseSummary.BillPercentageFor(_dbData.DebtorWithoutRestriction).Text.TextContains($"{TimeRecordingDbHelper.UnrestrictedDebtorBillPercentage}%"), "Expect bill percentage to be displayed");
        }
    }
}