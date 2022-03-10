using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Attachments;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.CommonPageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Attachments;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseViewActionEventAttachments : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var doc1 = StorageServiceSetup.MakeAvailable("doc.docx", "Docs");

            var settings = new AttachmentSetting
            {
                IsRestricted = true,
                NetworkDrives = new AttachmentSetting.NetworkDrive[0],
                StorageLocations = new[]
                {
                    new AttachmentSetting.StorageLocation {AllowedFileExtensions = "txt,pdf,docx", Name = "Documents-Docs", Path = doc1.folder}
                }
            };

            using (var db = new AttachmentsSettingsDb())
            {
                db.Setup(settings);
            }
        }

        [TearDown]
        public void CleanupFiles()
        {
            StorageServiceSetup.Delete();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CaseViewAttachmentsActionEventsAdd(BrowserType browserType)
        {
            var data = new CaseDetailsAttachmentSetup().AttachmentSetup();
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

                var user = new Users(x.DbContext).WithRowLevelAccess(rowAccessDetail).Create();

                return new
                {
                    user,
                    rowAccessDetail
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/caseview/{data.CaseId}", rowSecurity.user.Username, rowSecurity.user.Password);

            var actionsTopic = new ActionTopic(driver);
            Assert.AreEqual(1, actionsTopic.EventsGrid.AttachmentIcons.Count, "One attachment icon is displayed");
            actionsTopic.EventsGrid.AttachmentIcons.First().Click();

            var attachments = new AttachmentListObj(driver);
            Assert.AreEqual(1, attachments.AttachmentsGrid.Rows.Count);
            Assert.AreEqual(data.activityAttachment.AttachmentName, attachments.AttachmentName(0));

            attachments.AttachmentsGrid.Rows[0].FindElement(By.TagName("ipx-icon-button")).Click();
            attachments.ContextMenu.Edit();

            var attachmentMaintenancePage = new AttachmentPageObj(driver);
            Assert.IsTrue(attachmentMaintenancePage.SelectedEntityLabelText.Contains(data.CaseIrn), $"Expected label to display {data.CaseIrn} but was {attachmentMaintenancePage.SelectedEntityLabelText}");
            Assert.AreEqual(data.activityAttachment.AttachmentName, attachmentMaintenancePage.AttachmentName.Text);
            Assert.AreEqual(data.activityAttachment.FileName ?? string.Empty, attachmentMaintenancePage.FilePath.Text);
            Assert.AreEqual(data.validEvent.Description, attachmentMaintenancePage.ActivityEvent.GetText());
            Assert.AreEqual(data.activity.Cycle.ToString(), attachmentMaintenancePage.EventCycle.Text);
            Assert.IsTrue(attachmentMaintenancePage.EventCycle.Input.IsDisabled(), "Expected Cycle to be disabled when event is non-cyclic");
            Assert.AreEqual(data.activity.ActivityType.Name, attachmentMaintenancePage.ActivityType.Text);
            Assert.AreEqual(data.activity.ActivityCategory.Name, attachmentMaintenancePage.ActivityCategory.Text);
            Assert.AreEqual(data.activityAttachment.AttachmentType?.Name ?? string.Empty, attachmentMaintenancePage.AttachmentType.GetText());
            Assert.AreEqual(data.activityAttachment.Language?.Name, attachmentMaintenancePage.Language.GetText());
            Assert.AreEqual(data.activityAttachment.PageCount.ToString(), attachmentMaintenancePage.PageCount.Text);
            attachmentMaintenancePage.AttachmentName.Input.Clear();
            attachmentMaintenancePage.AttachmentName.Input.SendKeys($"name{data.CaseIrn}");
            attachmentMaintenancePage.Save();
            Assert.AreEqual($"name{data.CaseIrn}", attachments.AttachmentName(0));

            attachments.Add();
            attachmentMaintenancePage = new AttachmentPageObj(driver);
            Assert.IsTrue(attachmentMaintenancePage.SelectedEntityLabelText.Contains(data.CaseIrn), $"Expected label to display {data.CaseIrn} but was {attachmentMaintenancePage.SelectedEntityLabelText}");
            Assert.AreEqual(data.validEvent.Description, attachmentMaintenancePage.ActivityEvent.GetText());
            Assert.IsTrue(attachmentMaintenancePage.EventCycle.Input.IsDisabled(), "Expected Cycle to be disabled when event is non-cyclic");

            attachmentMaintenancePage.AttachmentName.Input.SendKeys($"test{data.CaseIrn}");
            attachmentMaintenancePage.FilePath.Input.SendKeys("iwl:abcde");
            attachmentMaintenancePage.ActivityType.Input.SelectByText(data.newOption.ActivityType2);
            attachmentMaintenancePage.ActivityCategory.Input.SelectByText(data.newOption.ActivityCategory2);
            attachmentMaintenancePage.ActivityDate.GoToDate(-1);
            attachmentMaintenancePage.AttachmentType.Typeahead.Clear();
            attachmentMaintenancePage.AttachmentType.Typeahead.SendKeys(data.newOption.attachmentType);
            attachmentMaintenancePage.AttachmentType.Typeahead.SendKeys(Keys.ArrowDown);
            attachmentMaintenancePage.AttachmentType.Typeahead.SendKeys(Keys.Enter);
            attachmentMaintenancePage.Language.Typeahead.Clear();
            attachmentMaintenancePage.Language.Typeahead.SendKeys(data.newOption.language);
            attachmentMaintenancePage.Language.Typeahead.SendKeys(Keys.ArrowDown);
            attachmentMaintenancePage.Language.Typeahead.SendKeys(Keys.Enter);
            attachmentMaintenancePage.ActivityEvent.OpenPickList();
            attachmentMaintenancePage.ActivityEvent.Close();
            attachmentMaintenancePage.Save();

            Assert.AreEqual(2, attachments.AttachmentsGrid.Rows.Count);
        }
    }
}