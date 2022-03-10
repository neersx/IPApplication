using System.Linq;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.CommonPageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.ContactActivity
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedAttachmentMaintenance : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            AttachmentSetup.Setup();
        }

        [TestCase(BrowserType.Chrome)]
        public void TestHostedAttachmentMaintenance(BrowserType browserType)
        {
            var data = new NewAttachment().Make();
            var driver = BrowserProvider.Get(browserType);SignIn(driver, "/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Contact Activity Attachment";
            driver.WaitForAngular();

            page.ActivityId.Text = data.activity.Id.ToString();
            driver.WaitForAngular();
            page.SequenceNo.Text = data.activityAttachment.SequenceNo.ToString();
            driver.WaitForAngular();

            page.AttachmentSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var hostedTopic = new AttachmentPageObj(driver);
                Assert.Throws<NoSuchElementException>(() => hostedTopic.FindElement(By.Name("event")), "Expected Event picklist to be hidden");
                Assert.Throws<NoSuchElementException>(() => hostedTopic.FindElement(By.Name("eventCycle")), "Expected Event Cycle to be hidden");
                Assert.Throws<NoSuchElementException>(() => hostedTopic.FindElement(By.Name("pageCount")), "Expected Page Count to be hidden");
                Assert.AreEqual(data.activityAttachment.AttachmentName, hostedTopic.AttachmentName.Text);
                Assert.AreEqual(data.activityAttachment.FileName ?? string.Empty, hostedTopic.FilePath.Text);
                Assert.AreEqual(data.activity.ActivityType.Name, hostedTopic.ActivityType.Text);
                Assert.AreEqual(data.activity.ActivityCategory.Name, hostedTopic.ActivityCategory.Text);
                Assert.AreEqual(data.activityAttachment.AttachmentType?.Name ?? string.Empty, hostedTopic.AttachmentType.GetText());
                Assert.AreEqual(data.activityAttachment.Language?.Name, hostedTopic.Language.GetText());

                hostedTopic.ActivityType.Input.SelectByText(data.newOption.ActivityType2);
                hostedTopic.ActivityCategory.Input.SelectByText(data.newOption.ActivityCategory2);
                hostedTopic.ActivityDate.GoToDate(-1);
                hostedTopic.AttachmentType.Typeahead.Clear();
                hostedTopic.AttachmentType.Typeahead.SendKeys(data.newOption.attachmentType);
                hostedTopic.AttachmentType.Typeahead.SendKeys(Keys.ArrowDown);
                hostedTopic.AttachmentType.Typeahead.SendKeys(Keys.Enter);
                hostedTopic.Language.Typeahead.Clear();
                hostedTopic.Language.Typeahead.SendKeys(data.newOption.language);
                hostedTopic.Language.Typeahead.SendKeys(Keys.ArrowDown);
                hostedTopic.Language.Typeahead.SendKeys(Keys.Enter);

                hostedTopic.Save();
            });

            var requestMessage = page.LifeCycleMessages.Last();
            Assert.AreEqual("onNavigate", requestMessage.Action);
            Assert.AreEqual(true, requestMessage.Payload);
        }

        [TestCase(BrowserType.Chrome)]
        public void TestDeleteAttachment(BrowserType browserType)
        {
            var componentName = "Hosted Contact Activity Attachment";
            var data = new NewAttachment().Make();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);
            
            page.ComponentDropdown.Text = componentName;
            driver.WaitForAngular();

            page.ActivityId.Text = data.activity.Id.ToString();
            driver.WaitForAngular();
            page.SequenceNo.Text = data.activityAttachment.SequenceNo.ToString();
            driver.WaitForAngular();

            page.AttachmentSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var hostedTopic = new AttachmentPageObj(driver);
                hostedTopic.Delete();
                driver.WaitForAngular();

                var popups = new CommonPopups(driver);
                popups.ConfirmNgDeleteModal.Delete.ClickWithTimeout();
                driver.WaitForAngularWithTimeout();
            });

            page.AttachmentSubmitButton.Click();
            driver.WaitForAngular();

            ReloadPage(driver);
            page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = componentName;
            driver.WaitForAngular();

            page.ActivityId.Text = data.activity.Id.ToString();
            driver.WaitForAngular();
            page.SequenceNo.Text = data.activityAttachment.SequenceNo.ToString();
            driver.WaitForAngular();

            page.AttachmentSubmitButton.Click();
            driver.WaitForAngular();

            var alert = new CommonPopups(driver);
            Assert.IsNotNull(alert.AlertModal, "Expected attachment to no longer be available.");
        }
    }
}
