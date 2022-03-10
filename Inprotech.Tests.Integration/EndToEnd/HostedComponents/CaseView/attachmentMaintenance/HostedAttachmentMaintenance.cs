using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.HostedComponents.ContactActivity;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.CommonPageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.attachmentMaintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedCaseAttachmentBase : IntegrationTest
    {
        protected dynamic _rowSecurity;
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

        protected void VerifyMaintenance(BrowserType browserType, bool fromCase = true)
        {
            var data = new CaseDetailsAttachmentSetup().AttachmentSetup();
            SetupRowSecurity(data.CaseId);

            var driver = BrowserProvider.Get(browserType);
            if (fromCase)
            {
                SignIn(driver, "/#/deve2e/hosted-test", _rowSecurity.user.Username, _rowSecurity.user.Password);
            }
            else
            {
                SignIn(driver, "/#/deve2e/hosted-test");
            }

            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = fromCase ? "Hosted Case Attachment" : "Hosted Contact Activity Attachment";
            driver.WaitForAngular();

            if (fromCase)
            {
                page.CasePicklist.SelectItem(data.CaseIrn);
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
                Assert.IsTrue(hostedTopic.SelectedEntityLabelText.Contains(data.CaseIrn), $"Expected label to display {data.CaseIrn} but was {hostedTopic.SelectedEntityLabelText}");
                Assert.AreEqual(data.activityAttachment.AttachmentName, hostedTopic.AttachmentName.Text);
                Assert.AreEqual(data.activityAttachment.FileName ?? string.Empty, hostedTopic.FilePath.Text);
                Assert.AreEqual(data.validEvent.Description, hostedTopic.ActivityEvent.GetText());
                Assert.AreEqual(data.activity.Cycle.ToString(), hostedTopic.EventCycle.Text);
                Assert.IsTrue(hostedTopic.EventCycle.Input.IsDisabled(), "Expected Cycle to be disabled when event is non-cyclic");
                Assert.AreEqual(data.activity.ActivityType.Name, hostedTopic.ActivityType.Text);
                Assert.AreEqual(data.activity.ActivityCategory.Name, hostedTopic.ActivityCategory.Text);
                Assert.AreEqual(data.activityAttachment.AttachmentType?.Name ?? string.Empty, hostedTopic.AttachmentType.GetText());
                Assert.AreEqual(data.activityAttachment.Language?.Name, hostedTopic.Language.GetText());
                Assert.AreEqual(data.activityAttachment.PageCount.ToString(), hostedTopic.PageCount.Text);

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
                hostedTopic.ActivityEvent.OpenPickList();
                hostedTopic.ActivityEvent.Close();
                hostedTopic.Save();
            });

            var requestMessage = page.LifeCycleMessages.Last();
            Assert.AreEqual("onNavigate", requestMessage.Action);
            Assert.AreEqual(true, requestMessage.Payload);
        }

        protected void VerifyDelete(BrowserType browserType, bool fromCase = true)
        {
            var componentName = fromCase ? "Hosted Case Attachment" : "Hosted Contact Activity Attachment";
            var data = new CaseDetailsAttachmentSetup().AttachmentSetup();
            SetupRowSecurity(data.CaseId);

            var driver = BrowserProvider.Get(browserType);
            if (fromCase)
            {
                SignIn(driver, "/#/deve2e/hosted-test", _rowSecurity.user.Username, _rowSecurity.user.Password);
            }
            else
            {
                SignIn(driver, "/#/deve2e/hosted-test");
            }

            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = componentName;
            driver.WaitForAngular();

            if (fromCase)
            {
                page.CasePicklist.SelectItem(data.CaseIrn);
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
                Assert.IsTrue(hostedTopic.SelectedEntityLabelText.Contains(data.CaseIrn), $"Expected label to display {data.CaseIrn} but was {hostedTopic.SelectedEntityLabelText}");
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

            if (fromCase)
            {
                page.CasePicklist.SelectItem(data.CaseIrn);
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

        protected void SetupRowSecurity(int caseId)
        {
            _rowSecurity = DbSetup.Do(x =>
            {
                var @case = x.DbContext.Set<Case>().Single(_ => _.Id == caseId);

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
                        }
                    }
                };

                var user = new Users(x.DbContext).WithRowLevelAccess(rowAccessDetail).Create();

                return new
                {
                    user,
                    rowAccessDetail
                };
            });
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedCaseAttachment : HostedCaseAttachmentBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedCaseAttachmentMaintenance(BrowserType browserType)
        {
            VerifyMaintenance(browserType);
        }

        [TestCase(BrowserType.Chrome, Ignore = "Flacky Test")]
        [TestCase(BrowserType.Ie, Ignore = "Flacky Test")]
        public void HostedCaseAttachmentMaintenanceAdd(BrowserType browserType)
        {
            var data = new CaseDetailsAttachmentSetup().AttachmentSetup();
            SetupRowSecurity(data.CaseId);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test", _rowSecurity.user.Username, _rowSecurity.user.Password);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case Attachment";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(data.CaseIrn);
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
                Assert.IsTrue(hostedTopic.SelectedEntityLabelText.Contains(data.CaseIrn), $"Expected label to display {data.CaseIrn} but was {hostedTopic.SelectedEntityLabelText}");

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
                    hostedTopic.AttachmentType.Typeahead.Clear();
                    hostedTopic.AttachmentType.Typeahead.SendKeys(data.newOption.attachmentType);
                    hostedTopic.AttachmentType.Typeahead.SendKeys(Keys.ArrowDown);
                    hostedTopic.AttachmentType.Typeahead.SendKeys(Keys.Enter);
                    hostedTopic.Language.Typeahead.Clear();
                    hostedTopic.Language.Typeahead.SendKeys(data.newOption.language);
                    hostedTopic.Language.Typeahead.SendKeys(Keys.ArrowDown);
                    hostedTopic.Language.Typeahead.SendKeys(Keys.Enter);

                    hostedTopic.Save();
                    driver.WaitForAngular();
                }
            });

            Assert.AreEqual(3, new CaseDetailsAttachmentSetup().CountAttachments(data.CaseId), "Adds two attachments making the count to 3");

            var requestMessage = page.LifeCycleMessages.Last();
            Assert.AreEqual("onNavigate", requestMessage.Action);
            Assert.AreEqual(true, requestMessage.Payload);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteCaseAttachment(BrowserType browserType)
        {
            VerifyDelete(browserType);
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedCaseAttachmentFromContactActivity : HostedCaseAttachmentBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedCaseAttachmentMaintenance(BrowserType browserType)
        {
            VerifyMaintenance(browserType, false);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteCaseAttachment(BrowserType browserType)
        {
            VerifyDelete(browserType, false);
        }
    }
}