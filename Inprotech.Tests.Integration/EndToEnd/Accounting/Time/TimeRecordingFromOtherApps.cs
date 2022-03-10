using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingFromOtherApps : IntegrationTest
    {
        protected TimeRecordingData DbData { get; set; }

        [SetUp]
        public void Setup()
        {
            DbData = TimeRecordingDbHelper.Setup(withStartTime: true);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        public void CheckRecordTime(NgWebDriver driver, BrowserType browserType, string irn, bool willHaveWipWarning = false)
        {
            var timeRecordingTab = driver.WindowHandles.Last();
            driver.SwitchTo().Window(timeRecordingTab);
            driver.With<TimeRecordingPage>(timeRecording =>
            {
                // WipWarningsModal sometimes does not display in IE
                if (willHaveWipWarning && browserType == BrowserType.Chrome)
                {
                    var wipWarningsModal = new WipWarningsModal(driver);
                    Assert.NotNull(wipWarningsModal, "The case related warnings are displayed");
                    wipWarningsModal.Proceed();
                }

                var editableRow = new TimeRecordingPage.EditableRow(driver, timeRecording.Timesheet, 0);
                Assert.AreEqual(irn, editableRow.CaseRef.GetText(), "IRN of the selected case is used to create new time entry");
            });
        }

        public void CheckRecordTimeWithTimer(NgWebDriver driver, BrowserType browserType, string irn, bool willHaveWipWarning = false)
        {
            var popups = new CommonPopups(driver);

            if (willHaveWipWarning)
            {
                var wipWarningsModal = new WipWarningsModal(driver);
                Assert.NotNull(wipWarningsModal, "The case related warnings are displayed");
                wipWarningsModal.Proceed();
            }

            Assert.True(popups.FlashAlert().Displayed, "Timer creation success is displayed");
            Assert.True(popups.FlashAlert().Text.Contains("A new Timer"), "Timer started message is displayed");

            var timerWidgetPopup = new TimerWidgetPopup(driver);
            Assert.NotNull(timerWidgetPopup, "The timer basic details widget popup is displayed");
            timerWidgetPopup.Activity.EnterAndSelect("NEWWIP");
            var activity = timerWidgetPopup.Activity.InputValue;
            timerWidgetPopup.Notes.Input.SendKeys("New Notes!");
            timerWidgetPopup.Apply();

            popups.WaitForFlashAlert();

            driver.With<TimeRecordingWidget>(widget =>
            {
                Assert.True(widget.IsDisplayed, "Displays the new timer in widget");
                if (browserType == BrowserType.Chrome)
                {
                    widget.CheckTooltipValues(caseRef: irn, activity: activity);
                }
            });
        }

        protected void DeleteStartedTimer(NgWebDriver driver, BrowserType browserType)
        {
            var popups = new CommonPopups(driver);

            var timerWidgetPopup = new TimerWidgetPopup(driver);
            driver.Wait().ForTrue(() => timerWidgetPopup.ClockTimeSpan.Text.Contains("00:1"));

            timerWidgetPopup.Delete();
            popups.ConfirmNgDeleteModal.Delete.Click();

            // FlashAlert sometimes disappears too quickly in IE
            if (browserType == BrowserType.Chrome)
            {
                Assert.True(popups.FlashAlertIsDisplayed(), "The Timer is deleted and confirmed to be deleted");
            }
            driver.With<TimeRecordingWidget>(widget => { Assert.False(widget.IsDisplayed, "Deletes the started timer"); });
        }
    }
}