using System.Linq;
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
using InprotechKaizen.Model.Documents;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.GenerateWord
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    public class HostedGenerateWordDoc : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var doc2 = StorageServiceSetup.MakeAvailable("doc.docx", "Docs");
            var mapped = StorageServiceSetup.MakeAvailable("sample.epf", "Mapped");
            _successfulPath = doc2.folder;

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

        string _successfulPath;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ShouldWorkAppropriatelyInHostedMode(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.ConfigureAttachmentsIntegration)
                                  .WithPermission(ApplicationTask.MaintainCaseAttachments, Allow.Create)
                                  .WithPermission(ApplicationTask.CreateMsWordDocument).Create();

            Document failingDestinationDocument = null;
            Document successfulDestinationDocument;
            DeliveryMethod successfulDeliveryMethod;
            var failingDestination = Fixture.String(10);
            var @case = DbSetup.Do(x =>
            {
                var case1 = new CaseBuilder(x.DbContext).CreateWithSummaryData().Case;
                failingDestinationDocument = new DocumentBuilder(x.DbContext).Create(Fixture.String(10));
                failingDestinationDocument.ConsumersMask = failingDestinationDocument.ConsumersMask | (int)LetterConsumers.Cases;
                failingDestinationDocument.Template = Fixture.String(10);
                failingDestinationDocument.DocumentType = (int) DocumentType.Word;
                var failingDeliveryMethod = new DeliveryMethod
                {
                    FileDestination = failingDestination,
                    Description = Fixture.String(10),
                    DestinationStoredProcedure = Fixture.String(10),
                    EmailStoredProcedure = Fixture.String(10),
                    Type = KnownDeliveryTypes.SaveDraftEmail
                };
                x.InsertWithNewId(failingDeliveryMethod);
                failingDestinationDocument.DeliveryMethodId = failingDeliveryMethod.Id;

                successfulDestinationDocument = new DocumentBuilder(x.DbContext).Create(Fixture.String(10));
                successfulDestinationDocument.ConsumersMask = successfulDestinationDocument.ConsumersMask | (int)LetterConsumers.Cases;
                successfulDestinationDocument.Template = Fixture.String(10);
                successfulDestinationDocument.DocumentType = (int) DocumentType.Word;

                successfulDeliveryMethod = new DeliveryMethod
                {
                    FileDestination = _successfulPath,
                    Description = Fixture.String(10),
                    DestinationStoredProcedure = Fixture.String(10),
                    EmailStoredProcedure = Fixture.String(10),
                    Type = KnownDeliveryTypes.SaveDraftEmail
                };
                successfulDestinationDocument.DeliveryMethodId = successfulDeliveryMethod.Id;

                x.InsertWithNewId(successfulDeliveryMethod);
                x.DbContext.SaveChanges();
                return case1;
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

            page.CasePicklist.SelectItem(@case.Irn);
            driver.WaitForAngular();
            
            page.IsWordCheckBox.Click();
            driver.WaitForAngular();

            page.GenerateWordSubmitButton.Click();
            driver.WaitForAngular();
            driver.DoWithinFrame(() =>
            {
                driver.With<GenerateWordDoc.GenerateWordModalPageObject>(modal =>
                {
                    modal.Document.EnterAndSelect(failingDestinationDocument?.Name);
                    driver.WaitForAngular();
                    Assert.False(modal.AddAsAttachment.IsChecked);
                    modal.GenerateButton.Click();
                    driver.Wait().ForAlert();
                    var alert = driver.SwitchTo().Alert();
                    Assert.True(alert.Text.StartsWith("inprodoc:"));
                    alert.Accept();
                });
            });
            var requestMessage = page.LifeCycleMessages.Last();
            Assert.AreEqual("onNavigate", requestMessage.Action);
        }
    }
}