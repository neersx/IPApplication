using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.ClientAccess
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ExternalCaseViewActions : IntegrationTest
    {
        [TearDown]
        public void Cleanup()
        {
            var setup = new CaseDetailsActionsDbSetup();
            setup.SetSiteControlForClientNote(false);
            setup.SetGlobalPreferenceForNoteType(null);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CaseActionTopic(BrowserType browserType)
        {
            var user = new Users().CreateExternalUser();
            int? overDueDays;
            var setup = new CaseDetailsActionsDbSetup()
                        .SetSiteControlForClientNote(false)
                        .SetGlobalPreferenceForNoteType(null)
                        .SetSiteControlForDueDatesOverdueDays(null);

            var data = setup.ActionsSetupExternal(user.Id);

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/caseview/{data.CaseId}", user.Username, user.Password);
            var actions = new ActionTopic(driver);
            actions.ActionGrid.Grid.WithJs().ScrollIntoView();

            Assert.True(actions.ActionGrid.RowIsHighlighted(0), "First row should be selected by default");
            Assert.True(actions.OpenActions.IsChecked);
            Assert.False(actions.ClosedActions.IsChecked);
            Assert.AreEqual(2, actions.ActionGrid.Rows.Count);

            var rowIndex = 0;
            int? noteIndex = null;
            TestNoteIconShown(actions, rowIndex, false, "No SiteControl setting, No Public Event Note Type, should not show note icons");
            Assert.False(ColumnIncludedInPicker(actions, "defaultEventText"), "No SiteControl setting, No Public Event Note Type, should not show note grid column");
            Assert.True(actions.EventsGrid.Rows.Count == RowsMatchingImportanceLevel(), "Events with Importance Level ");

            overDueDays = 0;
            setup.SetSiteControlForClientNote(true)
                 .SetSiteControlForDueDatesOverdueDays(overDueDays);
            ReloadPage(driver);

            TestNoteIconShown(actions, rowIndex, true, "SiteControl setting, No Public Event Note Type, should show default note icons");
            Assert.True(ColumnIncludedInPicker(actions, "defaultEventText"), "SiteControl setting, No Public Event Note Type, should show default note grid column");
            ToggleColumnVisibility(actions, "defaultEventText");
            Assert.AreEqual(data.defaultNote.Text, NoteColumnText(), "Default Note shown in grid column");
            Assert.True(actions.EventsGrid.Rows.Count == RowsMatchingImportanceLevelAndDueDate(), $"Events with Due Days within last {overDueDays} days ");

            setup.SetGlobalPreferenceForNoteType(-12234234);
            ReloadPage(driver);

            TestNoteIconShown(actions, rowIndex, true, "SiteControl setting, Invalid Note Type, should show default note icons");
            Assert.True(ColumnIncludedInPicker(actions, "defaultEventText"), "SiteControl setting, No Public Event Note Type, should show default note grid column");
            Assert.AreEqual(string.Empty, NoteColumnText(), "Default Note stays empty in grid column");

            actions.EventsGrid.ToggleDetailsRow(rowIndex);
            Assert.AreEqual(1, actions.EventNoteDetailsGrid.Rows.Count, "No default note type so shows all records");
            var typefilter = new AngularMultiSelectGridFilter(driver, "eventNoteDetails", 0);
            typefilter.Open();
            typefilter.Clear();
            Assert.AreEqual(1, actions.EventNoteDetailsGrid.Rows.Count);
            Assert.AreEqual(data.defaultNote.Text, actions.EventNoteDetailsGrid.Cell(0, 1).Text);

            var publicNote = setup.SetupNote(data.CaseId, data.OpenActionWithMultipleEvents.events.First().EventNo, true);
            setup.SetGlobalPreferenceForNoteType(publicNote.EventNoteType.Id);
            ReloadPage(driver);

            TestNoteIconShown(actions, rowIndex, true, "SiteControl setting, Public Event Note Type, should show default note icons");
            Assert.True(ColumnIncludedInPicker(actions, "defaultEventText"), "SiteControl setting, Public Event Note Type, should show default note grid column");
            Assert.AreEqual(publicNote.Text, NoteColumnText(), "Public Note shown in grid column");

            actions.EventsGrid.ToggleDetailsRow(rowIndex);
            Assert.AreEqual(1, actions.EventNoteDetailsGrid.Rows.Count);
            Assert.AreEqual(publicNote.Text, actions.EventNoteDetailsGrid.Cell(0, 1).Text);

            int RowsMatchingImportanceLevel()
            {
                return data.OpenActionWithMultipleEvents.events.Count(_ => string.Compare(_.Event.ClientImportanceLevel, actions.ImportanceLevel.Value, StringComparison.InvariantCultureIgnoreCase) >= 0);
            }

            int RowsMatchingImportanceLevelAndDueDate()
            {
                return data.OpenActionWithMultipleEvents.events.Count(_ => string.Compare(_.Event.ClientImportanceLevel, actions.ImportanceLevel.Value, StringComparison.InvariantCultureIgnoreCase) >= 0
                                                                           && _.EventDueDate >= DateTime.Today.AddDays(-overDueDays.Value));
            }

            string NoteColumnText()
            {
                noteIndex = noteIndex ?? actions.EventsGrid.HeaderColumns.ToList().FindIndex(e => e.WrappedElement.Text.Equals("Notes"));
                var textArea = actions.EventsGrid.Cell(rowIndex, noteIndex.Value).FindElements(By.TagName("textarea")).FirstOrDefault();
                return textArea?.Value() ?? string.Empty;
            }
        }

        void TestNoteIconShown(ActionTopic actions, int rowId, bool shouldBeShown, string message = null)
        {
            var noteIcon = actions.EventsGrid.Rows[rowId].FindElements(By.CssSelector("td span.cpa-icon-file-o"));
            Assert.AreEqual(shouldBeShown, noteIcon.Any(), message ?? $"Note Icon on Row {rowId} should be {(shouldBeShown ? "displayed" : "hidden")}");
        }

        bool ColumnIncludedInPicker(ActionTopic actions, string fieldId)
        {
            try
            {
                actions.EventsColumnSelector.ColumnMenuButtonClick();
                return actions.EventsColumnSelector.ContainsColumn(fieldId);
            }
            finally
            {
                actions.EventsColumnSelector.ColumnMenuButtonClick();
            }
        }

        void ToggleColumnVisibility(ActionTopic actions, string column)
        {
            actions.EventsColumnSelector.ColumnMenuButtonClick();
            actions.EventsColumnSelector.ToggleGridColumn(column);
            actions.EventsColumnSelector.ColumnMenuButtonClick();
        }
    }
}