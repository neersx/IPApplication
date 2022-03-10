using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Names;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingAdding : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup();
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        TimeRecordingData _dbData;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void AddNewTimeEntry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            TaskBasicTestHelper.CheckAddition(driver);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            var totalEntries = entriesList.MasterRows.Count;
            page.AddButton.ClickWithTimeout();

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.RevertButton().WithJs().Click();
            Assert.AreEqual(totalEntries, entriesList.MasterRows.Count, "Expected newly added row to have been removed.");

            page.AddButton.ClickWithTimeout();
            var activeRow = entriesList.MasterRows[0];
            var durationPicker = activeRow.FindElement(By.Id("elapsedTime"));
            durationPicker.FindElement(By.TagName("input")).SendKeys("1234");
            durationPicker.FindElement(By.TagName("input")).SendKeys(Keys.Tab);

            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().WithJs().Click();
            Assert.AreEqual(totalEntries + 1, entriesList.MasterRows.Count, "Expected row to be added with duration only");

            ReloadPage(driver);
            page = new TimeRecordingPage(driver);
            entriesList = page.Timesheet;

            page.AddButton.ClickWithTimeout();
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            var narrativePicker = details.Narrative;
            narrativePicker.Clear();
            narrativePicker.EnterAndSelect("e2e");
            var narrativeText = details.NarrativeText;
            Assert.AreEqual(_dbData.Narrative.NarrativeText, narrativeText.Value(), "Expected Narrative text to be defaulted");

            narrativeText.WithJs().Focus();

            narrativeText.SendKeys(Fixture.AlphaNumericString(1));
            Assert.AreEqual(string.Empty, narrativePicker.GetText(), "Expected narrative to be cleared when default text is changed");

            activeRow = entriesList.MasterRows[0];
            durationPicker = activeRow.FindElement(By.Id("elapsedTime"));
            durationPicker.FindElement(By.TagName("input")).WithJs().Focus();
            durationPicker.FindElement(By.TagName("input")).SendKeys("12");
            driver.WaitForAngular();
            durationPicker.FindElement(By.TagName("input")).SendKeys("34");

            var editableRow = new TimeRecordingPage.EditableRow(driver, page.Timesheet, 0);
            editableRow.CaseRef.OpenPickList();
            Assert.AreEqual(0, editableRow.CaseRef.SearchGrid.Rows.Count, "Expected no results displayed when Instructor name has not been specified");
            editableRow.CaseRef.Close();

            editableRow.CaseRef.EnterAndSelect(_dbData.Case.Irn);

            var wipWarningDialog = new WipWarningsModal(driver);
            Assert.IsNotNull(wipWarningDialog, "Expected debtor restriction dialog to be displayed for case with restricted debtors");

            var budgetAmount = wipWarningDialog.BudgetWarningSection.Budget;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.Budget.budgetRevised}.00", StripAmountFormatting(budgetAmount), $"Budget warning displays budget amount correctly as: {budgetAmount}");

            var usedTotal = wipWarningDialog.BudgetWarningSection.UsedTotal;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.Budget.amountUsed}.00", StripAmountFormatting(usedTotal), $"Budget warning displays budget used amount correctly as: {budgetAmount}");

            var billed = wipWarningDialog.BudgetWarningSection.BilledTotal;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.Budget.billed}.00", StripAmountFormatting(billed), $"Budget warning displays budget used amount correctly as: {billed}");

            var unbilled = wipWarningDialog.BudgetWarningSection.UnbilledTotal;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.Budget.unbilled}.00", StripAmountFormatting(unbilled), $"Budget warning displays budget used amount correctly as: {unbilled}");

            var budgetUsedPerc = wipWarningDialog.BudgetWarningSection.BudgetUsedPerc;
            Assert.AreEqual($"{_dbData.Budget.usedPerc}%", budgetUsedPerc, $"Budget warning displays budget used amount correctly as: {budgetUsedPerc}");
            wipWarningDialog.Proceed();

            driver.WaitForAngularWithTimeout();

            var activityPicker = editableRow.Activity;
            editableRow.Activity.OpenPickList();
            Assert.IsTrue(activityPicker.SearchGrid.Rows.Any(), "Expected activities to be available for cases with open action");
            activityPicker.Close();

            editableRow.CaseRef.Clear();
            editableRow.CaseRef.SendKeys(Fixture.AlphaNumericString(50));
            editableRow.CaseRef.OpenPickList();
            editableRow.CaseRef.SearchButton.ClickWithTimeout();
            Assert.AreEqual(0, editableRow.CaseRef.SearchGrid.MasterRows.Count, "Expected no records to be returned if no matches found.");
            editableRow.CaseRef.Close();

            var instructor = _dbData.Case2.CaseNames.Single(_ => _.NameTypeId == KnownNameTypes.Instructor).Name.FormattedNameOrNull();
            editableRow.Name.Clear();
            editableRow.Name.EnterAndSelect(_dbData.Case2.Client().Name.NameCode);

            editableRow.CaseRef.OpenPickList();
            Assert.AreEqual(1, editableRow.CaseRef.SearchGrid.Rows.Count, "Expected Case to be filtered by the selected Instructor name");
            var contextInfo = editableRow.CaseRef.ContextInfoElement();
            Assert.True(contextInfo.Text.Contains(instructor), "Expected Instructor Name to be displayed in picklist context area");
            editableRow.CaseRef.Close();
            driver.WaitForAngularWithTimeout();

            editableRow.Name.Typeahead.WithJs().Focus();
            editableRow.Name.Clear();
            Assert.AreEqual(string.Empty, editableRow.CaseRef.Typeahead.Text, "Expected Case to be cleared when Name is cleared.");

            editableRow.Activity.OpenPickList();
            Assert.IsTrue(activityPicker.SearchGrid.Rows.Any());
            activityPicker.Close();

            activityPicker.SendKeys(Keys.ArrowDown);
            activityPicker.SendKeys(Keys.ArrowDown);
            activityPicker.SendKeys(Keys.Enter);
            Assert.AreEqual(string.Empty, narrativePicker.GetText(), "Expected narrative to not be defaulted when text is already modified");

            editableRow.CaseRef.Clear();
            editableRow.CaseRef.EnterAndSelect(_dbData.Case2.Irn);

            activityPicker = new AngularPicklist(driver).ByName("wipTemplates");
            activityPicker.Clear();
            activityPicker.OpenPickList();
            Assert.IsTrue(activityPicker.SearchGrid.Rows.Any(), "Expected activities to be available for cases without open action");
            activityPicker.Close();
            details.ClearButton().Click();

            editableRow.CaseRef.Clear();
            editableRow.CaseRef.SendKeys("e2e");
            var casePickerList = editableRow.CaseRef.TypeAheadList;
            Assert.True(casePickerList.Count > 2, "Expected case suggestion list to display on focus");
            Assert.True(casePickerList.Count(_ => (_.Text?.Contains(_dbData.Case.Irn)).GetValueOrDefault(false)) == 1, "Contains expected case");
            Assert.True(casePickerList.Count(_ => (_.Text?.Contains(_dbData.Case2.Irn)).GetValueOrDefault()) == 1, "Contains expected case");
        }

        public string StripAmountFormatting(string amount)
        {
            return amount.Replace(",", string.Empty);
        }
    }
}