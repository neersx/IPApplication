using System;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingReadOnly : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            DbData = TimeRecordingDbHelper.Setup();
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        protected TimeRecordingData DbData;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ViewingTimeEntryList(BrowserType browserType)
        {
            DbData = TimeRecordingDbHelper.SetupLastInvoicedDate(DbData);
            var homeCurrency = DbData.HomeCurrency;
            var currency = DbData.Currency;
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password); 

            var page = new TimeRecordingPage(driver);
            
            var selectedDate = page.SelectedDate;
            var today = DateTime.Now.Date;
            Assert.AreEqual(today, DateTime.Parse(selectedDate.Value), $"Expected selected date of {selectedDate.Value} to be {today}");

            var entriesList = page.Timesheet;
            Assert.NotNull(entriesList, "Expected the time entries list to be available");
            page.ColumnSelector.ColumnMenuButtonClick();
            page.ColumnSelector.ToggleGridColumn("chargeOutRate");
            page.ColumnSelector.ToggleGridColumn("localDiscount");
            page.ColumnSelector.ToggleGridColumn("foreignDiscount");
            page.ColumnSelector.ColumnMenuButtonClick();

            Assert.True(DateTime.Parse(entriesList.CellText(0, "Start")) > DateTime.Parse(entriesList.CellText(3, "Start")), "Expected list to be ordered by the start time by default");
            var duration = entriesList.CellText(1, "Duration");
            var localValue = entriesList.CellText(1, "Local Value");
            var localDiscount = entriesList.CellText(1, "Local Value");
            var foreignValue = entriesList.CellText(1, "Foreign Value");
            var foreignDiscount = entriesList.CellText(1, "Foreign Discount");
            Assert.True(localValue.StartsWith(homeCurrency.Id), "Expected Local Value to use the home currency code");
            Assert.True(foreignValue.StartsWith(currency.Id), "Expected Foreign Value to use the foreign currency code");

            Assert.True(entriesList.MasterRows[0].FindElements(By.CssSelector("td+span, td+div")).All(_ => _.GetAttribute("class").Contains("continued")), "Expected continued styling to be applied");
            entriesList.ClickRow(1);
            entriesList.ToggleDetailsRow(1);
            driver.Wait();
            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            var narrative = details.NarrativeText;
            var notes = details.Notes;
            Assert.True(narrative.Value().StartsWith("long-narrative"), "Expected long narrative to be displayed");
            Assert.True(notes.Value().StartsWith("note3"), "Expected notes to be displayed");
            Assert.True(entriesList.MasterRows[2].FindElements(By.CssSelector("td+span, td+div")).All(_ => _.GetAttribute("class").Contains("continued-group")), "Expected continued styling to be applied");
            Assert.AreEqual(duration, details.AccumulatedDuration, "Expected Accumulated Duration to be reflected in details section");
            Assert.AreEqual(localValue, details.LocalValue, "Expected Local Value to be reflected in details section");
            Assert.AreEqual(localDiscount, details.LocalValue, "Expected Local Discount to be reflected in details section");
            Assert.AreEqual(foreignValue, details.ForeignValue, "Expected Foreign Value to be reflected in details section");
            Assert.AreEqual(foreignDiscount, details.ForeignDiscount, "Expected Foreign Discount to be reflected in details section");
            entriesList.ToggleDetailsRow(1);

            page.ColumnSelector.ColumnMenuButtonClick();
            page.ColumnSelector.ResetButton.WithJs().Click();

            entriesList.ToggleDetailsRow(2);
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            narrative = details.NarrativeText;
            notes = details.Notes;
            Assert.True(narrative.Value().StartsWith("short-narrative"), "Expected short narrative to be displayed");
            Assert.True(notes.Value().StartsWith("note2"), "Expected notes to be displayed");
            entriesList.ToggleDetailsRow(2);

            entriesList.ClickRow(3);
            entriesList.ToggleDetailsRow(3);
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            narrative = details.NarrativeText;
            notes = details.Notes;
            Assert.True(narrative.Value().StartsWith("long-narrative"), "Expected long narrative to be displayed");
            Assert.True(notes.Value().StartsWith("note3"), "Expected notes to be displayed");
            entriesList.ToggleDetailsRow(3);
            Assert.True(entriesList.MasterRows[1].FindElements(By.CssSelector("td+span, td+div")).All(_ => _.GetAttribute("class").Contains("continued-group")), "Expected continued styling to be applied");

            Assert.True(entriesList.MasterRows[4].FindElements(By.CssSelector("td+span, td+div")).All(_ => _.GetAttribute("class").Contains("posted")), "Expected posted styling to be applied");
            entriesList.ToggleDetailsRow(4);
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            notes = details.Notes;
            Assert.True(notes.Value().StartsWith("posted"), "Expected notes for Posted Entry to be displayed");
            Assert.True(page.PostedIcon(4).Displayed, "Expected Posted icon to be displayed");
            entriesList.ToggleDetailsRow(4);

            entriesList.ToggleDetailsRow(5);
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            notes = details.Notes;
            Assert.True(notes.Value().StartsWith("incomplete"), "Expected notes for Incomplete Entry to be displayed");
            Assert.True(page.IncompleteIcon(5).Displayed, "Expected Incomplete icon to be displayed");
            entriesList.ToggleDetailsRow(5);

            var caseSummary = new CaseSummaryPageObject(driver);
            Assert.True(page.CaseSummarySwitch.Enabled, "Expect toggle switch to be enabled");
            Assert.False(caseSummary.CaseSummaryPane.GetAttribute("class").IgnoreCaseContains("collapsed"), "Expected Case Summary to be hidden");

            entriesList.MasterCell(2, 2).ClickWithTimeout();
            Assert.True(caseSummary.NoInformationAvailable().Displayed, "Expected no information available msg to be shown");

            entriesList.MasterCell(1, 2).ClickWithTimeout();
            Assert.True(caseSummary.CaseRefLink.Displayed, "Expected Case Summary panel to be open");
            Assert.True(caseSummary.TotalWorkPerformed().Displayed, "Expected total work performed label to be displayed");
            Assert.True(caseSummary.ActiveBudget().Displayed, "Expected budget to be displayed");
            Assert.True(caseSummary.ActiveBudget().Text.Replace(",", string.Empty).Contains($"{homeCurrency.Id}{DbData.Case.BudgetRevisedAmt}"));
            Assert.True(caseSummary.BudgetUsed().Text.Contains($"{DbData.Budget.usedPerc}%"), $"Expected Budget Used Percentage to be displayed as: {DbData.Budget.usedPerc}%");
            Assert.AreEqual(entriesList.CellText(1, "Case Ref."), caseSummary.CaseRefLink.Text, "Expected Case Summary for the selected row to be displayed");
            Assert.AreEqual(DbData.LastInvoiceDate?.ToString("dd-MMM-yyyy"), caseSummary.LastInvoiceDate().Text, "Last Invoice date is displayed");

            Assert.NotNull(caseSummary.NameLinkFor(DbData.DebtorWithRestriction), "Expect name link to be displayed for debtor with restriction");
            Assert.True(caseSummary.BillPercentageFor(DbData.DebtorWithRestriction).Text.TextContains($"{TimeRecordingDbHelper.RestrictedDebtorBillPercentage}%"), "Expect bill percentage to be displayed");
            Assert.NotNull(caseSummary.NameRestrictionIconFor(DbData.DebtorWithRestriction), "Expect restriction flag to be displayed");
            Assert.NotNull(caseSummary.AgedBalanceExpandFor(DbData.DebtorWithRestriction), "Expect receivable balance toggle to be available");
            caseSummary.AgedBalanceExpandFor(DbData.DebtorWithRestriction).ClickWithTimeout();
            Assert.NotNull(caseSummary.AgedBalanceDataSectionFor(DbData.DebtorWithRestriction), "Expect receivable balance totals to be displayed");
            Assert.NotNull(caseSummary.AgedBalanceCollapseFor(DbData.DebtorWithRestriction), "Expect receivable balance toggle to be correctly swapped");
            caseSummary.AgedBalanceCollapseFor(DbData.DebtorWithRestriction).ClickWithTimeout();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.CssSelector($"div#debtor-{DbData.DebtorWithRestriction} ipx-aged-totals")), "Expect receivable balance section to be collapsed");

            Assert.NotNull(caseSummary.NameLinkFor(DbData.DebtorWithoutRestriction), "Expect name link to be displayed for debtor without restriction");
            Assert.True(caseSummary.BillPercentageFor(DbData.DebtorWithoutRestriction).Text.TextContains($"{TimeRecordingDbHelper.UnrestrictedDebtorBillPercentage}%"), "Expect bill percentage to be displayed for unrestricted name");
            Assert.Throws<NoSuchElementException>(() => caseSummary.NameRestrictionIconFor(DbData.DebtorWithoutRestriction), "Expect restriction icon to be hidden for unrestricted name");

            Assert.NotNull(caseSummary.CaseRefLink, "Expect Case Reference link to be available");
            Assert.NotNull(caseSummary.AgedWipExpand, "Expect WIP Totals toggle to be available");
            caseSummary.AgedWipExpand.ClickWithTimeout();
            Assert.NotNull(caseSummary.AgedWipDataSection(), "Expect WIP Totals section to be displayed");
            Assert.NotNull(caseSummary.AgedWipCollapse, "Expect WIP Totals toggle to be correctly swapped");
            caseSummary.AgedWipCollapse.ClickWithTimeout();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.CssSelector("div#aged-wip-data ipx-aged-totals")), "Expect WIP Totals section to be collapsed");

            page.NextButton.ClickWithTimeout();
            page.NextButton.ClickWithTimeout();
            Assert.True(caseSummary.NoInformationAvailable().Displayed, "Expected no information available msg to be shown");

            page.CaseSummarySwitch.ClickWithTimeout();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Id("caseSummaryPane")), "Expect Case Summary to be hidden");
            page.CaseSummarySwitch.ClickWithTimeout();

            page.ColumnSelector.ColumnMenuButtonClick();
            page.ColumnSelector.ResetButton.WithJs().Click();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TimeSummaryValues(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);

            Assert.True(page.TotalHours.Displayed, "Expected Total Hours to be displayed when there are chargeable entries");
            Assert.True(page.TotalValue.Displayed, "Expected Total Value to be displayed when there are chargeable entries");
            Assert.True(page.TotalCharges.Displayed, "Expected Chargeable Totals to be displayed when there are chargeable entries");

            page.NextButton.ClickWithTimeout();
            Assert.True(page.TotalHours.Displayed, "Expected Total Hours to be displayed when there are no chargeable entries");
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Id("totalValue")), "Expected Total Value to be hidden when there are no chargeable entries");
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Id("totalChargeable")), "Expected Chargeable Totals to be hidden when there are no chargeable entries");
        }
    }
}