using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Accounting;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.Checklists
{
    [NUnit.Framework.Category(Categories.E2E)]
    [TestFixture]
    public class HostedChecklistComponent : IntegrationTest
    {
        [TearDown]
        public void CleanupModifiedData()
        {
            SiteControlRestore.ToDefault(SiteControls.HomeNameNo, SiteControls.CriticalDates_Internal);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedChecklistComponentLifecycle(BrowserType browserType)
        {
            var setup = new CaseDetailsDbSetup();
            var caseData = setup.ReadOnlyDataSetup().Trademark;
            var restrictedName = (CaseName) caseData.RestrictedName;
            DbSetup.Do(db =>
            {
                var name = db.DbContext.Set<Name>().Single(v => v.Id == restrictedName.NameId);
                var nameType = db.DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.RenewalsDebtor);
                nameType.IsNameRestricted = 1m;
                var warningDebtorStatus = db.InsertWithNewId(new DebtorStatus
                {
                    RestrictionType = KnownDebtorRestrictions.DisplayWarning,
                    Status = Fixture.String(20)
                });
                name.ClientDetail.DebtorStatus = warningDebtorStatus;
                db.DbContext.SaveChanges();
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case View Checklist";
            driver.WaitForAngular();
            page.CasePicklist.SelectItem(caseData.Case.Irn);
            driver.WaitForAngular();
            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var checklistTopic = new CaseChecklistTopic(driver);
                var wipWarningDialog = new WipWarningsModal(driver);
                Assert.NotNull(wipWarningDialog, "Warning modal popup is displayed.");
                wipWarningDialog.Proceed();
                driver.WaitForAngular();
                Assert.True(checklistTopic.CaseChecklistGrid.Grid.Displayed, "Checklist grid is displayed.");
                Assert.AreEqual(checklistTopic.CaseChecklistGrid.Rows.Count, 3, "Correct number of questions are shown.");
                Assert.AreEqual(caseData.Checklists.ChecklistItemQuestion.Question + (caseData.Checklists.ChecklistItemQuestion.YesNoRequired == 1 ? " *" : string.Empty), checklistTopic.CaseChecklistGrid.CellText(0, 1), "Show correct answers.");
                var firstRow = new EditChecklistRow(driver, checklistTopic.CaseChecklistGrid.Rows[0]);
                Assert.AreEqual(firstRow.Text.Text, caseData.Checklists.CaseChecklist.ChecklistText, "Shows the correct checklist text answer");
                Assert.AreEqual(firstRow.CountValue.Number, caseData.Checklists.CaseChecklist.CountAnswer.ToString(), "Shows the correct checklist count answer");
                driver.WaitForAngular();
                firstRow.CountValue.Input.SendKeys("6");
                firstRow.Text.Input.SendKeys("v was here");
                Assert.False(checklistTopic.SaveButton.IsDisabled());
                Assert.False(checklistTopic.RevertButton.IsDisabled());
                driver.WaitForAngular();
                firstRow.CountValue.Input.Clear();
                firstRow.CountValue.Input.SendKeys("6");
                firstRow.Text.Input.Clear();
                firstRow.Text.Input.SendKeys("v was here");
                firstRow.Date.Input.Clear();
                firstRow.NoAnswer.Click();

                var parentRow = new EditChecklistRow(driver, checklistTopic.CaseChecklistGrid.Rows[1]);

                Assert.True(parentRow.YesAnswer.IsChecked, "Selects the defaulted answer");
                var childRow = new EditChecklistRow(driver, checklistTopic.CaseChecklistGrid.Rows[2]);
                Assert.False(childRow.YesAnswer.IsChecked, "Selects the defaulted answer from parent question");
                Assert.True(childRow.NoAnswer.IsChecked, "Selects the defaulted answer from parent question");
                Assert.True(childRow.YesAnswer.IsDisabled, "Sets the enable state from parent question");
                Assert.True(childRow.NoAnswer.IsDisabled, "Sets the enable state from parent question");

                parentRow.NoAnswer.Click();
                Assert.True(childRow.YesAnswer.IsChecked, "Selects the defaulted answer from parent answer");
                Assert.False(childRow.NoAnswer.IsChecked, "Selects the defaulted answer from parent answer");
                Assert.False(childRow.YesAnswer.IsDisabled, "Sets the enable state from parent answer");
                Assert.False(childRow.NoAnswer.IsDisabled, "Sets the enable stater from parent answer");

                childRow.NoAnswer.Click();

                checklistTopic.SaveButton.Click();
                driver.WaitForAngular();
                Assert.AreEqual(firstRow.Text.Text, "v was here", "Shows the correct checklist text answer after save");
                Assert.AreEqual(firstRow.CountValue.Number, "6", "Shows the correct checklist count answer after save");
                Assert.True(checklistTopic.SaveButton.IsDisabled());
                Assert.True(checklistTopic.RevertButton.IsDisabled());
                Assert.False(firstRow.Date.Input.Displayed, "Expected Date to be hidden if not available for 'No' response");
                Assert.False(childRow.YesAnswer.IsChecked, "Shows the saved answer of the child question");
                Assert.True(childRow.NoAnswer.IsChecked, "Shows the saved answer of the child question");

                firstRow.YesAnswer.Click();
                var dateValue = DateTime.Today.ToString("dd-MMM-yyyy");
                Assert.AreEqual(dateValue, firstRow.Date.Input.Value(), "Expected Date to be set when set for 'Yes' response");
            });

            page.CallOnRequestDataResponse(new HostedTestPageObject.DataReceivedMessage<bool>("isPoliceImmediately", false));
            driver.DoWithinFrame(() =>
            {
                var pageObject = new HostedTopicPageObject(driver);
                var checklistTopic = new CaseChecklistTopic(driver);
                checklistTopic.RegenerationModal.Proceed();
                driver.WaitForAngular();
                Assert.True(pageObject.SaveButton.IsDisabled());
                Assert.True(pageObject.RevertButton.IsDisabled());
            });
        }
    }
}