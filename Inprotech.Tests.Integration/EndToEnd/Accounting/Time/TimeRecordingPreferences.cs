using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingPreferences : TimeRecordingReadOnly
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void UserPreferences(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            Assert.IsTrue(entriesList.MasterRows.All(_ => _.Displayed), "Expected continued rows to be displayed");

            driver.With<QuickLinks>(slider =>
            {
                slider.Open("timeRecordingPreferences");

                var showSeconds = new AngularCheckbox(driver).ById("userPreference_19");
                var addOnSave = new AngularCheckbox(driver).ById("userPreference_31");
                var is12HourFormat = new AngularCheckbox(driver).ById("userPreference_32");
                var timePickerInterval = new IpxTextField(driver).ById("userPreference_39");
                var durationPickerInterval = new IpxTextField(driver).ById("userPreference_40");
                var applyButton = page.ApplyButton();
                var cancelButton = page.CancelButton();
                Assert.False(applyButton.Enabled, "Expected button to be disabled initially");

                Assert.False(showSeconds.IsChecked, "Expected Show Seconds setting to be false by default");
                Assert.False(addOnSave.IsChecked, "Expected Add On Save setting to be false by default");
                Assert.False(is12HourFormat.IsChecked, "Expected 12-Hour format setting to be false by default");
                Assert.IsEmpty(timePickerInterval.Text, "Expected Time Picker interval to be null by default");
                Assert.IsEmpty(durationPickerInterval.Text, "Expected Duration picker interval to be null by default");

                showSeconds.Click();
                addOnSave.Click();
                is12HourFormat.Click();
                timePickerInterval.Input.SendKeys("10");
                durationPickerInterval.Input.SendKeys("15");
                cancelButton.TryClick();
                Assert.False(showSeconds.IsChecked, "Expected Show Seconds setting to be reset to false");
                Assert.False(addOnSave.IsChecked, "Expected Add On Save setting to be reset to false");
                Assert.False(is12HourFormat.IsChecked, "Expected 12-hour format setting to be reset to false");
                Assert.IsEmpty(timePickerInterval.Text, "Expected Time Picker interval to be reset to null");
                Assert.IsEmpty(durationPickerInterval.Text, "Expected Duration picker interval to be reset to null");

                showSeconds.Click();
                addOnSave.Click();
                is12HourFormat.Click();
                timePickerInterval.Input.SendKeys("10");
                durationPickerInterval.Input.SendKeys("15");
                applyButton.TryClick();

                var infoModal = new InfoModal(driver);
                infoModal.Ok();

                slider.Close();
            });
            Assert.AreEqual(3, page.TotalHours.WithJs().GetInnerText().Split(':').Length, "Expected show Seconds to take effect");

            var cellTextToCheck = entriesList.Cell(0, "Finish").WithJs().GetInnerText();
            Assert.AreEqual("01", cellTextToCheck.Split(':')[0], "Expected 12-hour format to take effect");
            
            driver.With<QuickLinks>(slider =>
            {
                slider.Open("timeRecordingPreferences");

                var showSeconds = new AngularCheckbox(driver).ById("userPreference_19");
                var addOnSave = new AngularCheckbox(driver).ById("userPreference_31");
                var is12HourFormat = new AngularCheckbox(driver).ById("userPreference_32");
                var applyButton = page.ApplyButton();
                Assert.False(applyButton.Enabled, "Expected button to be disabled initially");

                showSeconds.Click();
                addOnSave.Click();
                is12HourFormat.Click();
                driver.WaitForAngularWithTimeout();

                applyButton.TryClick();

                var infoModal = new InfoModal(driver);
                infoModal.Ok();

                slider.Close();
            });
            Assert.AreEqual(2, page.TotalHours.WithJs().GetInnerText().Split(':').Length, "Expected show Seconds to take effect");

            cellTextToCheck = entriesList.Cell(0, "Finish").WithJs().GetInnerText();
            Assert.AreEqual("13", cellTextToCheck.Split(':')[0], "Expected 24-hour format to take effect");

            driver.With<QuickLinks>(slider =>
            {
                slider.Open("timeRecordingPreferences");

                var hideContinuedEntries = new AngularCheckbox(driver).ById("userPreference_18");
                var applyButton = page.ApplyButton();
                Assert.False(applyButton.Enabled, "Expected button to be disabled initially");

                hideContinuedEntries.Click();
                driver.WaitForAngularWithTimeout();

                applyButton.TryClick();

                var infoModal = new InfoModal(driver);
                infoModal.Ok();

                slider.Close();
            });
            Assert.IsTrue(entriesList.HiddenRows.Any(), "Expected continued rows to be hidden");

            page.AddButton.Click();
            var activeRow = entriesList.EditableRow(0);

            var startTime = activeRow.FindElement(By.Id("startTime")).FindElement(By.TagName("input"));
            startTime.SendKeys("0100");
            startTime.SendKeys(Keys.Tab);
            startTime.SendKeys("0100");
            startTime.SendKeys(Keys.ArrowUp);
            Assert.IsTrue(startTime.Value().EndsWith(":10"), $"Expected start time to increment by 10 minutes but was {startTime.Value()}");
            startTime.SendKeys(Keys.ArrowUp);
            Assert.IsTrue(startTime.Value().EndsWith(":20"), $"Expected start time to increment to 20 minutes but was {startTime.Value()}");
            var durationPicker = activeRow.FindElement(By.Id("elapsedTime")).FindElement(By.TagName("input"));
            durationPicker.SendKeys("0010");
            startTime.SendKeys(Keys.Tab);
            durationPicker.SendKeys("0010");
            durationPicker.SendKeys(Keys.ArrowUp);
            Assert.AreEqual("00:25", durationPicker.Value(), $"Expected Duration to increment by 15 minutes to 25 but was {durationPicker.Value()}");
            durationPicker.SendKeys(Keys.ArrowUp);
            Assert.AreEqual("00:40", durationPicker.Value(), $"Expected Duration to increment by 15 minutes to 25 but was {durationPicker.Value()}");

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.RevertButton().WithJs().Click();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ResettingUserPreferences(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            driver.With<QuickLinks>(slider =>
            {
                slider.Open("timeRecordingPreferences");
                var resetButton = page.ResetToDefaultButton();
                resetButton.Click();

                var confirmation = new ConfirmModal(driver);
                confirmation.PrimaryButton.Click();

                var infoModal = new InfoModal(driver);
                infoModal.Ok();

                slider.Close();
            });

            driver.With<QuickLinks>(slider =>
            {
                slider.Open("timeRecordingPreferences");

                var showSeconds = new AngularCheckbox(driver).ById("userPreference_19");
                var addOnSave = new AngularCheckbox(driver).ById("userPreference_31");
                var is12HourFormat = new AngularCheckbox(driver).ById("userPreference_32");
                var applyButton = page.ApplyButton();
                var cancelButton = page.CancelButton();
                var previewButton = page.PreviewDefaultsButton();
                var resetButton = page.ResetToDefaultButton();
                Assert.False(applyButton.Enabled, "Expected button to be disabled initially");
                Assert.False(showSeconds.IsChecked, "Expected Show Seconds setting to be false by default");
                Assert.False(addOnSave.IsChecked, "Expected Add On Save setting to be false by default");
                Assert.False(is12HourFormat.IsChecked, "Expected 12-Hour format setting to be false by default");
                Assert.False(previewButton.Enabled, "Expected 'Preview default' button to be disabled if no personal preferences");
                Assert.False(resetButton.Enabled, "Expected 'Reset to defaults' button to be disabled if no personal preferences");

                showSeconds.Click();
                addOnSave.Click();
                is12HourFormat.Click();
                applyButton.TryClick();

                var infoModal = new InfoModal(driver);
                infoModal.Ok();

                Assert.True(previewButton.Enabled, "Expected 'Preview default' button to be enabled if there are personal preferences");
                Assert.True(resetButton.Enabled, "Expected 'Reset to defaults' button to be enabled if there are personal preferences");

                previewButton.Click();
                Assert.False(showSeconds.IsChecked, "Expected Show Seconds setting to be reset to default of false");
                Assert.False(addOnSave.IsChecked, "Expected Add On Save setting to be reset to default of false");
                Assert.False(is12HourFormat.IsChecked, "Expected 12-Hour format setting to be reset to default of false");

                cancelButton.Click();

                showSeconds.Click();
                addOnSave.Click();
                is12HourFormat.Click();

                previewButton.Click();

                var confirmDiscard = new DiscardChangesModal(driver);
                confirmDiscard.Discard();

                Assert.False(showSeconds.IsChecked, "Expected Show Seconds setting to be set to default");
                Assert.False(addOnSave.IsChecked, "Expected Add On Save setting to be set to default");
                Assert.False(is12HourFormat.IsChecked, "Expected 12-Hour format setting to be set to default");

                applyButton.TryClick();
                infoModal = new InfoModal(driver);
                infoModal.Ok();

                showSeconds.Click();
                addOnSave.Click();
                is12HourFormat.Click();

                resetButton.Click();

                var confirmation = new ConfirmModal(driver);
                confirmation.PrimaryButton.Click();

                infoModal = new InfoModal(driver);
                infoModal.Ok();

                driver.WaitForAngularWithTimeout();

                Assert.False(showSeconds.IsChecked, "Expected Show Seconds setting to be reset to default of false");
                Assert.False(addOnSave.IsChecked, "Expected Add On Save setting to be reset to default of false");
                Assert.False(is12HourFormat.IsChecked, "Expected 12-Hour format setting to be reset to default of false");
                Assert.False(previewButton.Enabled, "Expected 'Preview default' button to be disabled if no personal preferences");
                Assert.False(resetButton.Enabled, "Expected 'Reset to defaults' button to be disabled if no personal preferences");
            });
        }
    }
}