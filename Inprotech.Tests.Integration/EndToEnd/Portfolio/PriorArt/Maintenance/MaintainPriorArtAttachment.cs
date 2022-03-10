using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.HostedComponents.ContactActivity;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.CommonPageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.PriorArt.Maintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    class MaintainPriorArtAttachment : IntegrationTest
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

        [TestCase(BrowserType.Chrome)]
        public void MaintainAttachments(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData();
            
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create | Allow.Delete).Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management", user.Username, user.Password);
            var quickie = new QuickLinks(driver);

            Assert.False(quickie.SlideContainer.Displayed, "Attachment icon not shown when creating a new prior art.");

            user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create | Allow.Delete)
                              .WithPermission(ApplicationTask.MaintainPriorArtAttachment, Allow.Create | Allow.Delete | Allow.Modify)
                              .WithSubjectPermission(ApplicationSubject.Attachments, SubjectAllow.None)
                              .Create();
            driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?priorartId=" + data.Source.Id + "&caseKey=" + data.Case.Id, user.Username, user.Password);
            quickie.Open("contextAttachments");
            var attachments = new AttachmentListObj(driver);

            Assert.AreEqual(1, attachments.AttachmentsGrid.Rows.Count, "The Attachments are displayed.");

            attachments.AttachmentsGrid.Add();
            var attachmentMaintenancePage = new AttachmentPageObj(driver);
            
            Assert.IsFalse(attachmentMaintenancePage.ActivityEvent.Exists, "Ensure Event typeahead is hidden");
            Assert.IsFalse(attachmentMaintenancePage.EventCycle.Exists, "Ensure Event Cycle is hidden");
            Assert.Throws<NoSuchElementException>(() => attachmentMaintenancePage.BrowseDmsButton.IsVisible(), "Ensure that DMS button is not shown");

            var attachmentName = Fixture.AlphaNumericString(20);
            attachmentMaintenancePage.AttachmentName.Input.SendKeys(attachmentName);
            attachmentMaintenancePage.FilePath.Input.SendKeys("iwl:abcde");
            attachmentMaintenancePage.ActivityType.Input.SelectByIndex(attachmentMaintenancePage.ActivityType.Input.Options.Count-1);
            attachmentMaintenancePage.ActivityCategory.Input.SelectByIndex(attachmentMaintenancePage.ActivityCategory.Input.Options.Count-1);
            driver.FindElement(By.CssSelector("div.modal-header-controls button.btn-save span")).TryClick();
            driver.WaitForAngular();

            attachments = new AttachmentListObj(driver);
            Assert.AreEqual(2, attachments.AttachmentsGrid.Rows.Count, "The new attachment is saved.");

            attachments.AttachmentsGrid.OpenContexualTaskMenu(0);
            attachments.ContextMenu.Edit();
            var attachmentMaintenance = new AttachmentPageObj(driver);
            attachmentMaintenance.AttachmentName.Input.Clear();
            attachmentMaintenance.AttachmentName.Input.SendKeys("aVeryNewAttachmentName");
            attachmentMaintenance.ActivityType.Input.SelectByIndex(0);
            driver.WaitForAngular();
            attachmentMaintenance.ActivityCategory.Input.SelectByIndex(0);
            driver.WaitForAngular();
            attachmentMaintenance.ActivityDate.GoToDate(-1);
            driver.WaitForAngular();
            attachmentMaintenance.AttachmentType.Typeahead.Clear();
            attachmentMaintenance.AttachmentType.Typeahead.SendKeys(Keys.ArrowDown);
            attachmentMaintenance.AttachmentType.Typeahead.SendKeys(Keys.ArrowDown);
            attachmentMaintenance.AttachmentType.Typeahead.SendKeys(Keys.Enter);
            driver.WaitForAngular();
            attachmentMaintenance.Language.Typeahead.Clear();
            attachmentMaintenance.Language.Typeahead.SendKeys(Keys.ArrowDown);
            attachmentMaintenance.Language.Typeahead.SendKeys(Keys.ArrowDown);
            attachmentMaintenance.Language.Typeahead.SendKeys(Keys.Enter);
            attachmentMaintenance.Language.Typeahead.SendKeys(Keys.Tab);
            driver.FindElement(By.CssSelector("div.modal-header-controls button.btn-save span")).TryClick();

            Assert.AreEqual("aVeryNewAttachmentName", attachments.AttachmentsGrid.CellText(0,1), "The attachment is updated.");

            attachments.AttachmentsGrid.OpenContexualTaskMenu(0);
            attachments.ContextMenu.Delete();
            var confirmDeleteDialog = new AngularConfirmDeleteModal(driver);
            confirmDeleteDialog.Delete.ClickWithTimeout();
            attachments.AttachmentsGrid.OpenContexualTaskMenu(0);
            attachments.ContextMenu.Delete();
            confirmDeleteDialog.Delete.ClickWithTimeout();

            Assert.AreEqual(0, attachments.AttachmentsGrid.Rows.Count, "The attachments are deleted.");
        }
    }
}