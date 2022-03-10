using System.Linq;
using Inprotech.Tests.Integration.EndToEnd.HostedComponents.ContactActivity;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.CommonPageObjects;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Names;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.NameView.AttachmentMaintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedNameAttachmentBase : IntegrationTest
    {
        public string Folder { get; private set; }
        public string File { get; private set; }

        [SetUp]
        public void Setup()
        {
            (Folder, File) = AttachmentSetup.Setup();
        }

        [TearDown]
        public void CleanupFiles()
        {
            StorageServiceSetup.Delete();
        }

        protected void VerifyMaintenance(BrowserType browserType, bool fromName = true)
        {
            var data = new NameDetailsAttachmentSetup().AttachmentSetup();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);

            page.ComponentDropdown.Text = fromName ? "Hosted Name Attachment" : "Hosted Contact Activity Attachment";
            driver.WaitForAngular();

            if (fromName)
            {
                page.NamePicklist.SelectItem(data.displayName);
                driver.WaitForAngular();
            }

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
                Assert.IsTrue(hostedTopic.SelectedEntityLabelText.Contains(data.displayName), $"Expected label to display {data.displayName} but was {hostedTopic.SelectedEntityLabelText}");
                Assert.AreEqual(data.activityAttachment.AttachmentName, hostedTopic.AttachmentName.Text);
                Assert.AreEqual(data.activityAttachment.FileName ?? string.Empty, hostedTopic.FilePath.Text);
                Assert.AreEqual(data.activity.ActivityType.Name, hostedTopic.ActivityType.Text);
                Assert.AreEqual(data.activity.ActivityCategory.Name, hostedTopic.ActivityCategory.Text);

                hostedTopic.ActivityType.Input.SelectByText(data.newOption.ActivityType2);
                hostedTopic.ActivityCategory.Input.SelectByText(data.newOption.ActivityCategory2);
                hostedTopic.ActivityDate.GoToDate(-1);

                hostedTopic.Save();
            });

            var requestMessage = page.LifeCycleMessages.Last();
            Assert.AreEqual("onNavigate", requestMessage.Action);
            Assert.AreEqual(true, requestMessage.Payload);
        }

        protected void VerifyDelete(BrowserType browserType, bool fromName = true)
        {
            var componentName = fromName ? "Hosted Name Attachment" : "Hosted Contact Activity Attachment";
            var data = new NameDetailsAttachmentSetup().AttachmentSetup();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);

            page.ComponentDropdown.Text = componentName;
            driver.WaitForAngular();

            if (fromName)
            {
                page.NamePicklist.SelectItem(data.displayName);
                driver.WaitForAngular();
            }

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
                Assert.IsTrue(hostedTopic.SelectedEntityLabelText.Contains(data.displayName), $"Expected label to display {data.displayName} but was {hostedTopic.SelectedEntityLabelText}");
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

            if (fromName)
            {
                page.NamePicklist.SelectItem(data.displayName);
                driver.WaitForAngular();
            }

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

    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedNameAttachmentMaintenance : HostedNameAttachmentBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedNameAttachmentMaintenance(BrowserType browserType)
        {
            VerifyMaintenance(browserType);
        }

        [TestCase(BrowserType.Chrome, Ignore = "flaky test")]
        [TestCase(BrowserType.Ie, Ignore = "flaky test")]
        public void HostedNameAttachmentMaintenanceAdd(BrowserType browserType)
        {
            var data = new NameDetailsAttachmentSetup().AttachmentSetup();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Name Attachment";
            driver.WaitForAngular();

            page.NamePicklist.SelectItem(data.displayName);
            driver.WaitForAngular();

            page.ActivityId.Text = "0";
            driver.WaitForAngular();
            page.SequenceNo.Text = "0";
            driver.WaitForAngular();

            page.AttachmentSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var hostedTopic = new AttachmentPageObj(driver);
                Assert.IsTrue(hostedTopic.SelectedEntityLabelText.Contains(data.displayName), $"Expected label to display {data.displayName} but was {hostedTopic.SelectedEntityLabelText}");

                hostedTopic.AddAnother.Click();
                SetDataAndSave("First");
                driver.WaitForAngular();

                Assert.AreEqual(string.Empty, hostedTopic.AttachmentName.Text);
                Assert.AreEqual(string.Empty, hostedTopic.FilePath.Text);
                
                SetDataAndSave("Second");

                void SetDataAndSave(string suffix)
                {
                    hostedTopic.AttachmentName.Text = data.activityAttachment.AttachmentName + suffix;
                    hostedTopic.FilePath.Input.SendKeys(string.Concat(Folder, File));
                    hostedTopic.ActivityType.Input.SelectByText(data.newOption.ActivityType2);
                    hostedTopic.ActivityCategory.Input.SelectByText(data.newOption.ActivityCategory2);
                    hostedTopic.ActivityDate.GoToDate(-1);

                    hostedTopic.Save();
                    driver.WaitForAngular();
                }
            });

            Assert.AreEqual(3, new NameDetailsAttachmentSetup().CountAttachments(data.NameId), "Adds two attachments making the count to 3");

            var requestMessage = page.LifeCycleMessages.Last();
            Assert.AreEqual("onNavigate", requestMessage.Action);
            Assert.AreEqual(true, requestMessage.Payload);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteNameAttachment(BrowserType browserType)
        {
            VerifyDelete(browserType);
        }
    }
}