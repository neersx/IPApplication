using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.Checklists
{
    [NUnit.Framework.Category(Categories.E2E)]
    [TestFixture]
    public class HostedChecklistWizardComponent : IntegrationTest
    {
        [TearDown]
        public void CleanupModifiedData()
        {
            SiteControlRestore.ToDefault(SiteControls.HomeNameNo, SiteControls.CriticalDates_Internal);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
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
            page.ComponentDropdown.Text = "Hosted Workflow Wizard Checklist";
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
                driver.WaitForAngular();
                Assert.True(checklistTopic.CaseChecklistGrid.Grid.Displayed, "Checklist grid is displayed.");
                Assert.AreEqual(checklistTopic.CaseChecklistGrid.Rows.Count, 3, "Correct number of questions are shown.");
                Assert.AreEqual(caseData.Checklists.ChecklistItemQuestion.Question + (caseData.Checklists.ChecklistItemQuestion.YesNoRequired == 1 ? " *" : string.Empty), checklistTopic.CaseChecklistGrid.CellText(0,1), "Show correct answers.");
                var firstRow = new EditChecklistRow(driver, checklistTopic.CaseChecklistGrid.Rows[0]);
                Assert.AreEqual(firstRow.Text.Text, caseData.Checklists.CaseChecklist.ChecklistText, "Shows the correct checklist text answer");
                Assert.AreEqual(firstRow.CountValue.Number, caseData.Checklists.CaseChecklist.CountAnswer.ToString(), "Shows the correct checklist count answer");
                driver.WaitForAngular();
                firstRow.CountValue.Input.SendKeys("6");
                firstRow.Text.Input.SendKeys("v was here");
                Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.CssSelector("ipx-revert-button button")), "Revert button is not visible");
                Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.CssSelector("ipx-revert-button button")), "Save button is not visible");
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
            });
        }
    }
}
