using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.HostedComponents;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedTimer : IntegrationTest
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

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void StartTimer(BrowserType browserType)
        {
            var componentName = "Hosted Enter Time with Timer";

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test");

            driver.With<HostedTestPageObject>(hostedPage =>
            {
                hostedPage.ComponentDropdown.Text = componentName;
                driver.WaitForAngular();

                hostedPage.CasePicklist.EnterAndSelect(DbData.Case.Irn);
                hostedPage.StartTimerButton.Click();
                driver.WaitForAngular();

                hostedPage.WaitForLifeCycleAction("onInit");
                hostedPage.WaitForLifeCycleAction("onViewInit");

                driver.DoWithinFrame(() =>
                {
                    var popups = new CommonPopups(driver);
                    var wipWarningsModal = new WipWarningsModal(driver);
                    Assert.NotNull(wipWarningsModal, "The case related warnings are displayed");
                    wipWarningsModal.Proceed();

                    Assert.True(popups.FlashAlert().Displayed, "Timer creation success is displayed");
                    Assert.True(popups.FlashAlert().Text.Contains("A new Timer"), "Timer started message is displayed");

                    var timerWidgetPopup = new TimerWidgetPopup(driver);
                    Assert.NotNull(timerWidgetPopup, "The timer basic details widget popup is displayed");
                    timerWidgetPopup.Activity.EnterAndSelect("NEWWIP");
                    timerWidgetPopup.Notes.Input.SendKeys("New Notes!");

                    timerWidgetPopup.Apply();
                });

                var requestMessage = hostedPage.LifeCycleMessages.Last();
                Assert.AreEqual("onNavigate", requestMessage.Action);
            });

            DbSetup.Do(x =>
            {
                var newTimer = x.DbContext.Set<Diary>().SingleOrDefault(_ => _.IsTimer == 1);
                Assert.AreEqual(DbData.Case.Id, newTimer?.CaseId, "Timer is added for the selected case");
                Assert.AreEqual("NEWWIP", newTimer?.Activity);
                Assert.AreEqual("New Notes!", newTimer?.Notes);
            });
        }
    }
}