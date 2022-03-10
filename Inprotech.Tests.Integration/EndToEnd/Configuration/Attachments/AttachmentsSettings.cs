using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.HostedComponents;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.CommonPageObjects;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Attachments;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Security;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Attachments
{
    [TestFixture]
    [Category(Categories.E2E)]
    public class AttachmentsSettings : IntegrationTest
    {
        [TearDown]
        public void CleanupFiles()
        {
            StorageServiceSetup.Delete();
        }

        [TestCase(BrowserType.Chrome)]
        public void SaveAttachment(BrowserType browserType)
        {
            var file = StorageServiceSetup.MakeAvailable("file.txt", string.Empty);
            var file2 = StorageServiceSetup.MakeAvailable("doc.docx", "Mapped");
            var pdf = StorageServiceSetup.MakeAvailable("file.pdf", "Pdfs");

            var settings = new AttachmentSetting
            {
                IsRestricted = true,
                NetworkDrives = new[]
                {
                    new AttachmentSetting.NetworkDrive {DriveLetter = "W", NetworkDriveMappingId = 0, UncPath = file2.folder}
                },
                StorageLocations = new[]
                {
                    new AttachmentSetting.StorageLocation {AllowedFileExtensions = "txt,pdf,docx", Name = "Documents", Path = file.folder},
                    new AttachmentSetting.StorageLocation {AllowedFileExtensions = "txt,pdf.docx", Name = "Mapped-Documents", Path = @"W:\", CanUpload = false}
                }
            };

            using (var db = new AttachmentsSettingsDb())
            {
                db.Setup(settings);
            }

            var driver = BrowserProvider.Get(browserType);
            var popup = new CommonPopups(driver);
            SignIn(driver, "/#/configuration/attachments");

            driver.With<AttachmentsSettingsPage>(page =>
            {
                var topic = new AttachmentsSettingsPage.StorageLocationsTopic(driver);

                Assert.AreEqual(2, topic.Grid.Rows.Count);
                Assert.True(topic.Grid.CellIsSelected(0, 4));
                Assert.False(topic.Grid.CellIsSelected(1, 4));

                topic.Grid.Add();
                Assert.True(topic.ModalExists());
                Assert.False(topic.ModalApply.Enabled);
                Assert.True(topic.ModalCancel.Enabled);

                topic.Name.Input.SendKeys("NameFolder2");
                topic.Path.Input.SendKeys(@"W:\");
                Assert.True(topic.Path.HasError);
                topic.Path.Input.Clear();
                topic.Path.Input.SendKeys("Z:\\Assets");
                topic.CanUpload.Click();

                Assert.True(topic.ModalApply.Enabled);
                topic.ModalApply.Click();
                Assert.False(topic.ModalApply.Enabled);
                Assert.True(topic.ModalExists());

                topic.Path.Input.Clear();
                topic.Path.Input.SendKeys(pdf.folder);

                Assert.True(topic.ModalApply.Enabled);
                topic.ModalApply.Click();
                Assert.False(topic.ModalExists());

                Assert.AreEqual(3, topic.Grid.Rows.Count);

                page.Save();
                Assert.True(popup.FlashAlertIsDisplayed());

                Assert.AreEqual(3, topic.Grid.Rows.Count);
                Assert.True(topic.Grid.CellIsSelected(2, 4));
            });

            driver.With<AttachmentsSettingsPage>(page =>
            {
                var topic = new AttachmentsSettingsPage.NetworkDriveTopic(driver);

                Assert.AreEqual(1, topic.Grid.Rows.Count);

                topic.Grid.Add();
                Assert.True(topic.ModalExists());
                Assert.False(topic.ModalApply.Enabled);
                Assert.True(topic.ModalCancel.Enabled);

                topic.Drive.Input.SelectByText("Z");
                Assert.False(topic.ModalApply.Enabled);

                topic.Drive.Input.SelectByText("X");
                topic.Path.Input.SendKeys(file2.folder);

                Assert.True(topic.ModalApply.Enabled);
                topic.ModalApply.Click();
                Assert.False(topic.ModalExists());

                Assert.AreEqual(2, topic.Grid.Rows.Count);
            });

            driver.With<AttachmentsSettingsPage>(page =>
            {
                var topic = new AttachmentsSettingsPage.StorageLocationsTopic(driver);

                topic.Grid.Add();

                topic.Name.Input.SendKeys("NameFolder2");
                Assert.False(topic.ModalApply.Enabled);

                topic.Name.Input.Clear();
                topic.Name.Input.SendKeys("NameFolder3");
                topic.Path.Input.SendKeys("X:\\");

                Assert.True(topic.ModalApply.Enabled);
                topic.ModalApply.Click();
                Assert.False(topic.ModalExists());

                Assert.AreEqual(4, topic.Grid.Rows.Count);

                page.Save();
                Assert.True(popup.FlashAlertIsDisplayed());

                Assert.AreEqual(4, topic.Grid.Rows.Count);
                Assert.AreEqual(2, new AttachmentsSettingsPage.NetworkDriveTopic(driver).Grid.Rows.Count);
            });

            driver.With<AttachmentsSettingsPage>(page =>
            {
                var topic = new AttachmentsSettingsPage.DmsIntegrationTopic(driver);
                Assert.True(topic.DmsToggleDisabled);
            });
        }

        dynamic _rowSecurity;

        [TestCase(BrowserType.Chrome)]
        public void ConfigureDmsAndBrowse(BrowserType browserType)
        {
            new DocumentManagementDbSetup().Setup();
            var data = new CaseDetailsAttachmentSetup().AttachmentSetup();
            SetupRowSecurity(data.CaseId);
            var file = StorageServiceSetup.MakeAvailable("file.txt", string.Empty);

            var settings = new AttachmentSetting
            {
                IsRestricted = true,
                NetworkDrives = new AttachmentSetting.NetworkDrive[] { },
                StorageLocations = new[]
                {
                    new AttachmentSetting.StorageLocation {AllowedFileExtensions = "txt,pdf,docx", Name = "Documents", Path = file.folder}
                }
            };

            using (var db = new AttachmentsSettingsDb())
            {
                db.Setup(settings);
            }

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/attachments");
            driver.With<AttachmentsSettingsPage>(_ =>
            {
                var topic = new AttachmentsSettingsPage.DmsIntegrationTopic(driver);

                Assert.True(topic.DmsToggle.Displayed);
                Assert.True(topic.DmsToggle.Enabled);
                Assert.True(topic.NavigateButton.Enabled);
            });

            driver.WrappedDriver.Url = Env.RootUrl + "/#/deve2e/hosted-test";

            var page = new HostedTestPageObject(driver);
            driver.WaitForAngular();
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

            driver.DoWithinFrame(() =>
            {
                var hostedTopic = new AttachmentPageObj(driver);
                Assert.True(hostedTopic.BrowseDmsButton.IsVisible());
                hostedTopic.BrowseButton.Click();
            });
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
}