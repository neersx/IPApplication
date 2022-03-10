using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.StandingInstructions;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseViewActions : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _currentIsImmediately = new CaseDetailsActionsDbSetup().IsPoliceImmediately;
        }

        [TearDown]
        public void TearDown()
        {
            new CaseDetailsActionsDbSetup().IsPoliceImmediately = _currentIsImmediately;
        }

        bool _currentIsImmediately;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CaseActionTopicWithRowSecurity(BrowserType browserType)
        {
            var data = new CaseDetailsActionsDbSetup().ActionsSetup();

            var rowSecurity = DbSetup.Do(x =>
            {
                var @case = x.DbContext.Set<Case>().Single(_ => _.Id == data.CaseId);

                var propertyType = @case.PropertyType;
                var caseType = @case.Type;

                var rowAccessDetail = new RowAccess("ra1", "row access one")
                {
                    Details = new List<RowAccessDetail>
                    {
                        new RowAccessDetail("ra1")
                        {
                            SequenceNo = 0,
                            Office = @case.Office,
                            AccessType = RowAccessType.Case,
                            CaseType = caseType,
                            PropertyType = propertyType,
                            AccessLevel = 15
                        },
                        new RowAccessDetail("ra1")
                        {
                            SequenceNo = 1,
                            Office = null,
                            AccessType = RowAccessType.Name,
                            AccessLevel = 15,
                            CaseType = caseType,
                            PropertyType = propertyType
                        }
                    }
                };

                var user = new Users(x.DbContext).WithRowLevelAccess(rowAccessDetail).WithPermission(ApplicationTask.MaintainCaseAttachments).Create();

                return new
                {
                    user,
                    rowAccessDetail
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/caseview/{data.CaseId}", rowSecurity.user.Username, rowSecurity.user.Password);

            var actions = new ActionTopic(driver);
            actions.ActionGrid.Grid.WithJs().ScrollIntoView();

            actions.EventsColumnSelector.ColumnMenuButtonClick();
            actions.EventsColumnSelector.ToggleGridColumn("fromCaseIrn");
            actions.EventsColumnSelector.ToggleGridColumn("name");

            Assert.True(actions.EventsGrid.Cell(0, 12).Text.Equals(string.Empty), "shouldn't display fromCase");
            Assert.False(actions.EventsGrid.Cell(0, 13).Text.Equals(string.Empty), "shouldn display name");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CaseActionTopic(BrowserType browserType)
        {
            var dbSetup = new CaseDetailsActionsDbSetup();
            var data = dbSetup.ActionsSetup(false, true);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/caseview/{data.CaseId}");

            var actions = new ActionTopic(driver);
            actions.ActionGrid.Grid.WithJs().ScrollIntoView();
            var refreshButton = actions.ActionGrid.Cell(0, actions.ActionGrid.FindColByText("Refresh Action")).FindElements(By.CssSelector("ipx-icon span.cpa-icon-refresh"));
            Assert.True(refreshButton.Any(), "Should display refresh button on row selected");
            TestEventRuleDetails(actions, data.validEvent, data.caseEvent, dbSetup, data.OpenAction.events, driver);

            Assert.True(actions.EventsGrid.HeaderColumnsFields.Contains("attachmentCount"), "Attachment field column should be visible in non hosted");
            Assert.False(actions.EventsGrid.HeaderColumnsFields.Contains("hasEventHistory"), "Event History column should not be visible in non hosted");
            Assert.True(actions.ActionGrid.RowIsHighlighted(0), "First row should be selected by default");
            Assert.True(actions.OpenActions.IsChecked);
            Assert.False(actions.ClosedActions.IsChecked);
            Assert.AreEqual(2, actions.ActionGrid.Rows.Count);

            Assert.True(actions.ActionGrid.Cell(0, "Police Action").FindElements(By.TagName("a")).Any(), "First row shows policing icon");
            Assert.True(actions.ActionGrid.Cell(1, "Police Action").FindElements(By.TagName("a")).Any(), "Second row shows policing icon");

            dbSetup.IsPoliceImmediately = true;
            AssertPolicingIconBeginsPolicingProcess(0, actions, driver);
            dbSetup.UpdateEventDate(data.OpenActionWithMultipleEvents.events[0].Event.Id, data.CaseId, Fixture.PastDate());
            dbSetup.UpdateEventDate(data.OpenActionWithMultipleEvents.events[3].Event.Id, data.CaseId, Fixture.PastDate());
            AssertPolicingIconBeginsPolicingProcess(1, actions, driver);
            driver.WaitForAngular();
            Assert.AreEqual("01-Jan-1999", actions.EventsGrid.CellText(0, 6));
            Assert.AreEqual("01-Jan-1999", actions.EventsGrid.CellText(1, 6));

            TestActionGridColumnOrder(actions, driver);

            TestNotes(actions, driver);

            var columns2 = actions.ActionGrid.HeaderColumns;
            var newNameIndex = columns2.ToList().FindIndex(e => e.Text.Equals("Action"));
            var newStatusIndex = columns2.ToList().FindIndex(e => e.Text.Equals("Action Status"));

            actions.ClosedActions.Click();
            Assert.AreEqual(3, actions.ActionGrid.Rows.Count);
            Assert.AreEqual(data.Closed.Va.Action.Name, actions.ActionGrid.CellText(2, newNameIndex));

            Assert.True(actions.ActionGrid.Cell(0, "Police Action").FindElements(By.TagName("a")).Any(), "First row shows policing icon");
            Assert.True(actions.ActionGrid.Cell(1, "Police Action").FindElements(By.TagName("a")).Any(), "Second row shows policing icon");
            Assert.True(actions.ActionGrid.Cell(2, "Police Action").FindElements(By.TagName("a")).Any(), "Third row shows policing icon");

            actions.OpenActions.Click();
            Assert.AreEqual(1, actions.ActionGrid.Rows.Count);
            Assert.True(actions.ActionGrid.Cell(0, "Police Action").FindElements(By.TagName("a")).Any(), "First row shows policing icon");

            actions.PotentialActions.Click();
            actions.ActionGrid.ClickRow(1);
            Assert.IsTrue(actions.IsAllCycles.IsChecked, @"isAllCycles should be checked for selecting potential actions");
            Assert.IsTrue(actions.IsAllEvents.IsChecked, @"isAllEvents should be checked for selecting potential actions");
            Assert.AreEqual(2, actions.ActionGrid.Rows.Count);

            actions.PotentialActions.Click();
            actions.OpenActions.Click();
            actions.ClosedActions.Click();
            actions.ClosedActions.Click();

            var openActionRow = 1;
            var closedActionRow = 2;
            Assert.AreEqual(3, actions.ActionGrid.Rows.Count);
            Assert.AreEqual(data.OpenAction.Va.ActionName, actions.ActionGrid.CellText(0, newNameIndex));

            Assert.AreEqual(data.Closed.Va.Action.Name, actions.ActionGrid.CellText(closedActionRow, newNameIndex));
            Assert.True(actions.ActionGrid.Rows[closedActionRow].GetAttribute("class").Contains("text-red-dark"));
            Assert.True(actions.ActionGrid.CellText(closedActionRow, newStatusIndex).Contains("(closed action)"));

            // Reset
            actions.IsAllEvents.Click();
            Assert.IsTrue(!actions.IsAllCycles.IsChecked, @"isAllCycles should default to false");
            Assert.IsTrue(!actions.IsAllEvents.IsChecked, @"isAllEvents should default to false");
            Assert.IsTrue(!actions.IsAllEventDetails.IsChecked, @"All event details should default to false");

            actions.IsAllEvents.Click();
            Assert.IsTrue(actions.IsAllCycles.IsChecked, @"IsAllCycles should be checked after choosing all events");
            Assert.IsTrue(actions.IsAllCycles.IsDisabled, @"IsAllCycles should be disabled after choosing all events");

            actions.IsAllEvents.Click();
            Assert.IsTrue(!actions.IsAllCycles.IsChecked, @"IsAllCycles should no longer be checked after un-choosing all events");
            Assert.IsTrue(!actions.IsAllCycles.IsDisabled, @"IsAllCycles should no longer be disabled after un-choosing all events");

            actions.EventsGrid.Grid.WithJs().ScrollIntoView();
            Assert.True(actions.EventsHeader.Contains(actions.ActionGrid.CellText(0, newNameIndex)));
            Assert.AreEqual(data.OpenAction.events.Length, actions.EventsGrid.Rows.Count);

            actions.ActionGrid.ClickRow(closedActionRow);
            Assert.True(actions.EventsHeader.Contains(actions.ActionGrid.CellText(closedActionRow, newNameIndex)), "Event header should update with selected action");
            Assert.AreEqual(data.Closed.events.Length, actions.EventsGrid.Rows.Count, "Shows correct number of rows for selected action");

            actions.ActionGrid.ClickRow(openActionRow);
            Assert.True(actions.EventsHeader.Contains(actions.ActionGrid.CellText(openActionRow, newNameIndex)), "Event header should update with selected action");
            Assert.AreEqual(data.OpenActionWithMultipleEvents.events.Count(_ => _.IsOccurredFlag == 0 && _.EventDueDate != null && _.Cycle == 1), actions.EventsGrid.Rows.Count, "Shows correct number of rows for selected action");

            actions.IsAllEvents.Click();
            Assert.AreEqual(data.OpenActionWithMultipleEvents.events.Length, actions.EventsGrid.Rows.Count, "Shows correct number of rows for all events per action");

            if (actions.IsAllEventDetails.IsChecked)
            {
                actions.IsAllEventDetails.Click();
            }

            Assert.True(!string.IsNullOrEmpty(actions.EventsGrid.CellText(0, 4)), "Due date should be shown if event date is null even if all event details is not checked");

            TestImportanceLevel(actions, driver, data.MaxImportanceLevel, data.OpenActionWithMultipleEvents.events);

            TestColumnSelection(actions, driver);

            TestRememberingSelections(actions, driver);
        }

        static void AssertPolicingIconBeginsPolicingProcess(int cell, ActionTopic actions, NgWebDriver driver)
        {
            actions.ActionGrid.Cell(cell, "Police Action").FindElement(By.TagName("a")).Click();
            driver.WaitForAngular();

            var policingPopup = new CommonPopups(driver);
            policingPopup.ConfirmModal.PrimaryButton.Click();
            driver.WaitForAngular();
        }

        void TestRememberingSelections(ActionTopic actions, NgWebDriver driver)
        {
            actions.PotentialActions.Click();
            var isPotentialChecked = actions.PotentialActions.IsChecked;
            var isClosedChecked = actions.ClosedActions.IsChecked;
            var isOpenChecked = actions.OpenActions.IsChecked;

            actions.IsAllEventDetails.Click();
            actions.IsAllCycles.Click();
            var isAllEventChecked = actions.IsAllEvents.IsChecked;
            var isAllCyclesChecked = actions.IsAllCycles.IsChecked;
            var isAllDetailsChecked = actions.IsAllEventDetails.IsChecked;

            ReloadPage(driver);

            Assert.AreEqual(isPotentialChecked, actions.PotentialActions.IsChecked);
            Assert.AreEqual(isClosedChecked, actions.ClosedActions.IsChecked);
            Assert.AreEqual(isOpenChecked, actions.OpenActions.IsChecked);

            Assert.AreEqual(isAllEventChecked, actions.IsAllEvents.IsChecked);
            Assert.AreEqual(isAllCyclesChecked, actions.IsAllCycles.IsChecked);
            Assert.AreEqual(isAllDetailsChecked, actions.IsAllEventDetails.IsChecked);

            actions.PotentialActions.Click();
            actions.IsAllEventDetails.Click();
            actions.IsAllCycles.Click();
        }

        void TestEventRuleDetails(ActionTopic actions, ValidEvent validEvent, CaseEvent caseEvent, DbSetup dbSetup, CaseEvent[] events, NgWebDriver driver)
        {
            actions.EventNoLink.ClickWithTimeout();
            var eventText = validEvent.Description + " (" + validEvent.EventId + ")";
            Assert.AreEqual(actions.EventNumber.Text, validEvent.EventId.ToString());
            Assert.AreEqual(actions.Event.Text, eventText);
            Assert.AreEqual(actions.CriteriaNumber.Text, validEvent.CriteriaId.ToString());
            Assert.AreEqual(actions.Cycle.Text, caseEvent.Cycle.ToString());
            Assert.AreEqual(actions.Notes.Text, "Event Control Notes");

            Assert.IsTrue(actions.HeaderTitle("Reminders").Displayed);
            Assert.AreEqual(actions.GetHeaderCount(driver, "remindersCount").Text, "1");
            Assert.AreEqual(actions.ReminderMessage.Text, "e2e - Reminder");

            Assert.IsTrue(actions.HeaderTitle("Due Date Calculation").Displayed);
            Assert.IsTrue(actions.DueDateCalFormatted.Text.Contains(validEvent.Description));
            var dueDateCalc = validEvent.DueDateCalcs.First(_ => _.Sequence == 0);
            var adj = dbSetup.DbContext.Set<DateAdjustment>().First(_ => _.Id == dueDateCalc.Adjustment);
            Assert.IsTrue(actions.DueDateCalFormatted.Text.Contains(adj.Description));
            Assert.IsTrue(actions.DueDateCalFormatted.Text.Contains(dueDateCalc.DeadlinePeriod.ToString()));
            Assert.AreEqual(caseEvent.EventDueDate?.ToString("dd-MMM-yyyy"), actions.DueDateCalculatedFromDate.Text);
            var instruction = dbSetup.DbContext.Set<InstructionType>().First(_ => _.Code == validEvent.InstructionType);
            Assert.IsTrue(actions.StandingInstructionInfo.Text.Contains(instruction.Description));
            Assert.AreEqual(2, actions.DateComparisonGrid.Rows.Count);
            var ddCompareData = validEvent.DueDateCalcs.First(_ => _.IsDateComparison);
            Assert.IsTrue(actions.DateComparisonGrid.CellText(0, 0).TextContains(validEvent.Description));
            Assert.IsTrue(actions.DateComparisonGrid.CellText(0, 1).TextContains(ddCompareData.Comparison));
            Assert.IsTrue(actions.DateComparisonGrid.CellText(0, 2).TextContains(ddCompareData.CompareEvent.Description));
            Assert.IsTrue(actions.DateComparisonGrid.CellText(1, 2).TextContains("System Date"));
            Assert.AreEqual(2, actions.SatisfiedEventsGrid.Rows.Count);
            var satisfyEvents = validEvent.RelatedEvents.First(_ => _.Sequence == 0);
            Assert.IsTrue(actions.SatisfiedEventsGrid.CellText(0, 0).TextContains(satisfyEvents.RelatedEventId.ToString()));
            Assert.IsTrue(actions.SatisfiedEventsGrid.CellText(0, 1).TextContains(satisfyEvents.RelatedEvent.Description));
            Assert.AreEqual("Due date will be saved when it is first calculated.", actions.SaveDueDate.Text);

            Assert.IsTrue(actions.HeaderTitle("Documents").Displayed);
            Assert.AreEqual(actions.GetHeaderCount(driver, "documentsCount").Text, "1");
            var letter = dbSetup.DbContext.Set<Document>().First(_ => _.Code == "rm-lt");
            Assert.IsTrue(actions.ReminderFormattedText.Text.Contains(letter.Name));

            Assert.IsTrue(actions.HeaderTitle("Date Validation when Dates Manually Entered").Displayed);
            Assert.AreEqual(actions.GetHeaderCount(driver, "datesLogicCount").Text, "1");
            var datesLogic = validEvent.DatesLogic.First();
            Assert.IsTrue(actions.DatesLogicMessage.Text.Contains(datesLogic.CompareEvent.Description));
            Assert.IsTrue(actions.DatesLogicMessage.Text.Contains(datesLogic.CaseRelationship.Description));
            Assert.IsTrue(actions.DatesLogicMessage.Text.Contains(datesLogic.Operator));
            Assert.AreEqual(datesLogic.ErrorMessage, actions.FailureActionMessage.Text);
            Assert.True(actions.FailureActionIcon.Displayed);

            Assert.IsTrue(actions.HeaderTitle("What Occurs when Event is Updated").Displayed);
            Assert.IsTrue(actions.UpdateImmediately.Displayed);
            Assert.AreEqual(validEvent.ChangeStatus.Name, actions.EventUpdateStatus.Text);
            Assert.AreEqual($"Raise charge for {validEvent.InitialFee.Description}", actions.Charge1.Text);
            Assert.AreEqual($"Pay Fee for {validEvent.InitialFee2.Description}", actions.Charge2.Text);
            Assert.AreEqual(validEvent.OpenAction.Name, actions.CreateAction.Text);
            Assert.AreEqual(validEvent.CloseAction.Name, actions.CloseAction.Text);
            Assert.IsTrue(actions.ReportToCpa.Displayed);
            var updateEvent = validEvent.RelatedEvents.First(_ => _.IsUpdateEvent);
            Assert.AreEqual(2, actions.DatesToUpdateText.Count());
            Assert.IsTrue(actions.DatesToUpdateText.First().Text.Contains(updateEvent.RelatedEvent.Description));
            Assert.IsTrue(actions.UpdateEventAdjustedTo.Text.Contains(updateEvent.DateAdjustment.Description));
            var clearEvent = validEvent.RelatedEvents.First(_ => _.IsClearDue);
            Assert.AreEqual(2, actions.DatesToClearText.Count());
            Assert.IsTrue(actions.DatesToClearText.First().Text.Contains(clearEvent.RelatedEvent.Description));
            Assert.IsTrue(actions.DatesToClearText.First().Text.Contains("due date when Due Date updated"));

            Assert.AreEqual(actions.TotalNavigation.Text, events.Length.ToString());
            Assert.AreEqual(actions.CurrentNavigation.Text, "1");
            actions.NextNavigation.ClickWithTimeout();
            Assert.AreEqual(actions.CurrentNavigation.Text, "2");
            Assert.AreEqual(actions.EventNumber.Text, events[1].EventNo.ToString());
            Assert.IsTrue(actions.Event.Text.Contains(events[1].Event.ValidEvents.FirstOrDefault().Description));
            actions.FirstNavigation.ClickWithTimeout();
            Assert.AreEqual(actions.CurrentNavigation.Text, "1");
            Assert.AreEqual(actions.EventNumber.Text, events[0].EventNo.ToString());
            Assert.IsTrue(actions.Event.Text.Contains(events[0].Event.ValidEvents.FirstOrDefault().Description));
            actions.LastNavigation.ClickWithTimeout();
            Assert.AreEqual(actions.CurrentNavigation.Text, "2");
            Assert.AreEqual(actions.EventNumber.Text, events[1].EventNo.ToString());

            actions.ModalCloseButton.WithJs().Click();
        }

        void TestActionGridColumnOrder(ActionTopic actions, NgWebDriver driver)
        {
            var columns = actions.ActionGrid.HeaderColumns;
            var nameIndex = columns.ToList().FindIndex(e => e.Text.Equals("Action"));
            var statusIndex = columns.ToList().FindIndex(e => e.Text.Equals("Action Status"));
            Assert.True(nameIndex < statusIndex);

            if (!driver.Is(BrowserType.Ie)) //TODO: REVIEW
            {
                new Actions(driver).DragAndDrop(columns[nameIndex], columns[statusIndex]).Perform();
            }

            driver.WaitForAngular();
            var columns2 = actions.ActionGrid.HeaderColumns;
            var nameIndex2 = columns2.ToList().FindIndex(e => e.Text.Equals("Action"));
            var statusIndex2 = columns2.ToList().FindIndex(e => e.Text.Equals("Action Status"));

            if (!driver.Is(BrowserType.Ie)) //TODO: REVIEW
            {
                Assert.True(nameIndex2 > statusIndex2, "should have swap position after column change");
            }
        }

        void TestNotes(ActionTopic actions, NgWebDriver driver)
        {
            actions.ActionGrid.ClickRow(0);
            var noteIcon = actions.EventsGrid.Rows[0].FindElements(By.TagName("td"))[2].FindElement(By.CssSelector("span.cpa-icon-file-o"));
            Assert.True(noteIcon != null, "note indicator should show");
            Assert.False(actions.EventsGrid.HeaderColumnsFields.Contains("defaultEventText"), "Note column header should not be visible");

            actions.EventsGrid.Rows[0].FindElements(By.TagName("td"))[0].FindElement(By.TagName("a")).ClickWithTimeout();

            Assert.True(actions.EventNoteDetailsGrid.Rows.Count == 1, "should pre filter event notes");
            Assert.AreEqual("no type event text", actions.EventNoteDetailsGrid.Cell(0, 1).Text);

            var typefilter = new AngularMultiSelectGridFilter(driver, "eventNoteDetails", 0);
            typefilter.Open();
            var selectedValues = typefilter.SelectedValues;
            Assert.True(selectedValues.Length == 1 && selectedValues[0] == "null", "pre filter is selected at the beginning");
            Assert.AreEqual(2, typefilter.ItemCount, "Ensure that correct number of type filters are retrieved");
            typefilter.SelectOption("test Type");
            typefilter.SelectOption("(empty)");
            typefilter.Filter();
            Assert.True(actions.EventNoteDetailsGrid.Rows.Count == 1, "should filter rows");
            Assert.True(actions.EventNoteDetailsGrid.Cell(0, 1).Text.Equals("test event text"), "should display filterred row correctly");

            actions.EventsGrid.Rows[0].FindElements(By.TagName("td"))[0].FindElement(By.TagName("a")).ClickWithTimeout();
        }

        void TestImportanceLevel(ActionTopic actions, NgWebDriver driver, Importance maxImportanceLevel, CaseEvent[] events)
        {
            actions.SelectImportanceLevel(maxImportanceLevel.Description);
            Assert.True(actions.ActionGrid.RowIsHighlighted(0), "Changing Importance Level should maintain the selection if action exists");
            Assert.AreEqual(events.Count(_ => _.Event.ValidEvents.Any(ve => ve.Importance?.LevelNumeric >= maxImportanceLevel.LevelNumeric)), actions.EventsGrid.Rows.Count, "Shows all event filtered by Importance Level");

            ReloadPage(driver);
            Assert.AreEqual(maxImportanceLevel.Description, actions.ImportanceLevel.Text);
        }

        void TestColumnSelection(ActionTopic actions, NgWebDriver driver)
        {
            if (actions.ClosedActions.IsChecked)
            {
                actions.ClosedActions.Click();
            }

            var columns = actions.EventsGrid.HeaderColumnsFields;
            Assert.False(columns.Contains("fromCaseIrn"), "Default hidden Column is not displayed");
            Assert.False(columns.Contains("period"), "Default hidden Column is not displayed");
            Assert.False(columns.Contains("responsibility"), "Default hidden Column is not displayed");
            Assert.False(columns.Contains("isManuallyEntered"), "Default hidden Column is not displayed");

            actions.EventsColumnSelector.ColumnMenuButtonClick();
            Assert.IsTrue(actions.EventsColumnSelector.IsColumnChecked("eventDescription"), "The column appears checked in the menu");

            actions.EventsColumnSelector.ToggleGridColumn("eventDescription");
            actions.EventsColumnSelector.ColumnMenuButtonClick();
            Assert.False(actions.EventsGrid.HeaderColumnsFields.Contains("eventDescription"), "eventDescription Column is not displayed");

            actions.EventsColumnSelector.ColumnMenuButtonClick();
            Assert.IsFalse(actions.EventsColumnSelector.IsColumnChecked("eventDescription"), "The column is unchecked in the menu");

            // actions.EventsColumnSelector.ColumnMenuButtonClick();
            actions.EventsColumnSelector.ToggleGridColumn("period");
            actions.EventsColumnSelector.ColumnMenuButtonClick();
            Assert.Contains("period", actions.EventsGrid.HeaderColumnsFields, "period Column is displayed");

            ReloadPage(driver);

            actions.EventsGrid.Grid.WithJs().ScrollIntoView();
            columns = actions.EventsGrid.HeaderColumnsFields;
            Assert.False(columns.Contains("eventDescription"), "eventDescription Column is not displayed");
            Assert.Contains("period", columns, "period Column is displayed");

            if (!actions.IsAllEvents.IsChecked)
            {
                actions.IsAllEvents.Click();
            }

            actions.EventsColumnSelector.ColumnMenuButtonClick();
            actions.EventsColumnSelector.ToggleGridColumn("stopPolicing");
            actions.EventsColumnSelector.ColumnMenuButtonClick();

            Assert.Contains("stopPolicing", actions.EventsGrid.HeaderColumnsFields, "stopPolicing Column is displayed");
            Assert.True(actions.EventsGrid.CellIsSelected(0, actions.EventsGrid.FindColByText("Stop Policing")));

            actions.EventsColumnSelector.ColumnMenuButtonClick();
            actions.EventsColumnSelector.ToggleGridColumn("isManuallyEntered");
            Assert.Contains("isManuallyEntered", actions.EventsGrid.HeaderColumnsFields, "DateDueSaved Column is displayed");
            Assert.False(actions.EventsGrid.CellIsSelected(0, actions.EventsGrid.FindColByText("Due Date Saved")));
            actions.EventsColumnSelector.ColumnMenuButtonClick();
        }
    }
}