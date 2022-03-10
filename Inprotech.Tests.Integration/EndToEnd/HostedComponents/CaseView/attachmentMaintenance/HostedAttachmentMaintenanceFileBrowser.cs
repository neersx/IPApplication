using System.Collections.Generic;
using System.IO;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Attachments;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.CommonPageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Attachments;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Security;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.AttachmentMaintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedAttachmentMaintenanceFileBrowser : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var pdfFile = StorageServiceSetup.MakeAvailable("file.pdf", "Pdfs");
            StorageServiceSetup.MakeAvailable("1.zip", "Docs");
            StorageServiceSetup.MakeAvailable("file.txt", "Docs");
            StorageServiceSetup.MakeAvailable("file.pdf", "Docs\\New");
            StorageServiceSetup.MakeAvailable("file2.pdf", "Docs\\Old");
            StorageServiceSetup.MakeAvailable("doc.docx", string.Empty);
            var doc2 = StorageServiceSetup.MakeAvailable("doc.docx", "Docs");
            var mapped = StorageServiceSetup.MakeAvailable("sample.epf", "Mapped");

            var settings = new AttachmentSetting
            {
                IsRestricted = true,
                NetworkDrives = new AttachmentSetting.NetworkDrive[0],
                StorageLocations = new[]
                {
                    new AttachmentSetting.StorageLocation {AllowedFileExtensions = "txt,pdf,docx", Name = "Documents-Docs", Path = doc2.folder},
                    new AttachmentSetting.StorageLocation {AllowedFileExtensions = "txt,pdf,docx", Name = "Documents-Pdfs", Path = pdfFile.folder, CanUpload = false},
                    new AttachmentSetting.StorageLocation {AllowedFileExtensions = "txt,pdf,docx", Name = "Documents-Mapped", Path = mapped.folder}
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

        dynamic _rowSecurity;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedAttachmentMaintenanceFileExplorer(BrowserType browserType)
        {
            var data = new CaseDetailsAttachmentSetup().AttachmentSetup();
            SetupRowSecurity(data.CaseId);
            StorageServiceSetup.MakeAvailable("doc.docx", "Mapped");
            var fileInvalidExtention = StorageServiceSetup.MakeAvailable("chicken-tonight.png", "Mapped");
            var fileUploadInValid = StorageServiceSetup.MakeAvailable("FakePdf.pdf", "Mapped");

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/attachments");
            driver.With<AttachmentsSettingsPage>(settingPage =>
            {
                var topic = new AttachmentsSettingsPage.StorageLocationsTopic(driver);
                topic.Grid.ClickDelete(2);
                settingPage.Save();
            });

            SignIn(driver, "/#/deve2e/hosted-test", _rowSecurity.user.Username, _rowSecurity.user.Password);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case Attachment";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(data.CaseIrn);
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
                hostedTopic.BrowseButton.Click();

                var modal = hostedTopic.Modal;
                Assert.NotNull(modal);
                var grid = hostedTopic.FilesListGrid;
                Assert.NotNull(grid);
                var treeView = hostedTopic.DirectoryTree;
                Assert.AreEqual(2, treeView.Folders.Count);
                treeView.Folders[0].Click();
                Assert.AreEqual(2, grid.Rows.Count);
                Assert.AreEqual("file.txt", grid.Cell(1, 0).Text);
                Assert.AreEqual(".txt", grid.Cell(1, 2).Text);
                grid.Cell(1, 0).ClickWithTimeout();
                Assert.AreEqual("file.txt", hostedTopic.FileValue);
                Assert.NotNull(hostedTopic.PathValue);
                Assert.AreEqual("Documents-Docs", treeView.Folders[0].Name);
                treeView.Folders[0].Expand();
                Assert.AreEqual(2, treeView.Folders[0].Children.Count);
                Assert.AreEqual("New", treeView.Folders[0].Children[0].Name);
                Assert.AreEqual("Old", treeView.Folders[0].Children[1].Name);
                var selectedFilePath = Path.Combine(hostedTopic.PathValue, hostedTopic.FileValue);
                hostedTopic.OkButton.Click();
                Assert.AreEqual(selectedFilePath, hostedTopic.FilePath.Text);
            });

            driver.DoWithinFrame(() =>
            {
                var hostedTopic = new AttachmentPageObj(driver);
                hostedTopic.BrowseButton.Click();

                var modal = hostedTopic.Modal;
                Assert.NotNull(modal);
                var treeView = hostedTopic.DirectoryTree;
                Assert.AreEqual(2, treeView.Folders.Count);
                Assert.True(treeView.Folders[0].IsSelected);
                treeView.Folders[1].Click();
                Assert.True(hostedTopic.UploadFilesButton.IsDisabled());
                treeView.Folders[0].Click();

                hostedTopic.UploadFilesButton.Click();

                var uploadModal = hostedTopic.UploadModal;
                Assert.NotNull(uploadModal);

                var kendoUpload = hostedTopic.UploadComponent;
                kendoUpload.Upload(Path.Combine(fileInvalidExtention.folder, fileInvalidExtention.file));
                kendoUpload.Upload(Path.Combine(fileUploadInValid.folder, fileUploadInValid.file));

                var list = kendoUpload.FilesListItems.ToArray();
                Assert.AreEqual(2, list.Length);

                Assert.False(string.IsNullOrWhiteSpace(kendoUpload.ErrorMessage(list[0])));
                Assert.True(string.IsNullOrWhiteSpace(kendoUpload.ErrorMessage(list[1])));

                kendoUpload.UploadButton.Click();
                Assert.False(kendoUpload.IsUploadButtonVisible);

                Assert.AreEqual(2, list.Length);
                Assert.False(string.IsNullOrWhiteSpace(kendoUpload.ErrorMessage(list[0])));
                Assert.False(string.IsNullOrWhiteSpace(kendoUpload.ErrorMessage(list[1])));

                hostedTopic.CloseModal(uploadModal);

                var grid = hostedTopic.FilesListGrid;
                Assert.AreEqual(2, grid.Rows.Count);
            });
        }

        void SetupRowSecurity(int caseId)
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

                var user = new Users(x.DbContext).WithRowLevelAccess(rowAccessDetail).WithPermission(ApplicationTask.ConfigureAttachmentsIntegration).Create();

                return new
                {
                    user,
                    rowAccessDetail
                };
            });
        }
    }
}