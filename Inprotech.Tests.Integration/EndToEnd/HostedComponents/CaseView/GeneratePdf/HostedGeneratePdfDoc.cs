using System.IO;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Attachments;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Attachments;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.DocumentGeneration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Documents;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.GeneratePdf
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    public class HostedGeneratePdfDoc : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var doc2 = StorageServiceSetup.MakeAvailable("doc.docx", "Docs");
            var mapped = StorageServiceSetup.MakeAvailable("sample.epf", "Mapped");

            var settings = new AttachmentSetting
            {
                IsRestricted = true,
                NetworkDrives = new AttachmentSetting.NetworkDrive[0],
                StorageLocations = new[]
                {
                    new AttachmentSetting.StorageLocation {AllowedFileExtensions = "txt,pdf,docx", Name = "Documents-Docs", Path = doc2.folder},
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

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ShouldWorkAppropriatelyInHostedMode(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.ConfigureAttachmentsIntegration)
                                  .WithPermission(ApplicationTask.MaintainCaseAttachments, Allow.Create)
                                  .WithPermission(ApplicationTask.CreateMsWordDocument).Create();

            Document successfulDestinationDocument = null;
            
            var docPath = StorageServiceSetup.MakeAvailable("pf1077.pdf", "Templates");
            var data = DbSetup.Do(x =>
            {
                var d = new CaseBuilder(x.DbContext).CreateWithSummaryData();
                var formsDirectorySiteControl = x.DbContext.Set<SiteControl>().First(_ => _.ControlId == SiteControls.PDFFormsDirectory);
                formsDirectorySiteControl.StringValue = docPath.folder;
                var deliveryMethod = x.InsertWithNewId(new DeliveryMethod {Description = "save", Type = KnownDeliveryTypes.SaveDraftEmail});

                successfulDestinationDocument = x.InsertWithNewId(new Document("form", "Form 1077")
                {
                    DocumentType = (short) DocumentType.PDF,
                    Template = Path.Combine(docPath.folder, docPath.file),
                    DeliveryMethodId = deliveryMethod.Id
                });
                successfulDestinationDocument.ConsumersMask = successfulDestinationDocument.ConsumersMask | (int) LetterConsumers.Cases;

                var item = x.DbContext.Set<DocItem>().SingleOrDefault(di => di.Name.Equals("MXMPDF_ADP_ADD_FOR_SERV"));
                x.DbContext.SaveChanges();

                x.Insert(new FormFields {DocumentId = successfulDestinationDocument.Id, FieldDescription = null, FieldName = "ADP NUMBER AGENT", FieldType = 6, ItemId = item?.Id});

                x.DbContext.SaveChanges();
                return new
                {
                    user,
                    d.Case
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/attachments", user.Username, user.Password);
            driver.With<AttachmentsSettingsPage>(settingPage =>
            {
                var topic = new AttachmentsSettingsPage.StorageLocationsTopic(driver);
                topic.Grid.ClickDelete(1);
                settingPage.Save();
            });

            SignIn(driver, "/#/deve2e/hosted-test", user.Username, user.Password);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Generate Document Case";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(data.Case.Irn);
            driver.WaitForAngular();
            page.GenerateWordSubmitButton.Click();
            driver.WaitForAngular();
            driver.DoWithinFrame(() =>
            {
                driver.With<GenerateWordDoc.GenerateWordModalPageObject>(modal =>
                {
                    modal.Document.EnterAndSelect(successfulDestinationDocument?.Name);
                    driver.WaitForAngular();
                    Assert.False(modal.AddAsAttachment.IsChecked);
                    modal.GenerateButton.Click();
                });
            });
        }
    }
}