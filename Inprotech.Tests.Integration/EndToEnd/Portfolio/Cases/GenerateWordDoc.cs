using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Attachments;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.CommonPageObjects;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Attachments;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.DocumentGeneration;
using InprotechKaizen.Model.Documents;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    public class GenerateWordDoc : IntegrationTest
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
        public void ShouldSeeWordOptionIfHasTaskSecurity(BrowserType browserType)
        {
            Document failingDestinationDocument = null;
            Document successfulDestinationDocument = null;
            DeliveryMethod successfulDeliveryMethod = null;
            var failingDestination = Fixture.String(10);

            var data = DbSetup.Do(x =>
            {
                var case1 = new CaseBuilder(x.DbContext).CreateWithSummaryData().Case;

                failingDestinationDocument = new DocumentBuilder(x.DbContext).Create(Fixture.String(10));
                failingDestinationDocument.ConsumersMask = failingDestinationDocument.ConsumersMask | (int) LetterConsumers.Cases;
                failingDestinationDocument.Template = Fixture.String(10);
                failingDestinationDocument.DocumentType = (int) DocumentType.Word;
                var failingDeliveryMethod = new DeliveryMethod
                {
                    FileDestination = failingDestination,
                    Description = Fixture.String(10),
                    DestinationStoredProcedure = string.Empty,
                    EmailStoredProcedure = Fixture.String(10),
                    Type = KnownDeliveryTypes.SaveDraftEmail
                };
                x.InsertWithNewId(failingDeliveryMethod);
                failingDestinationDocument.DeliveryMethodId = failingDeliveryMethod.Id;

                successfulDestinationDocument = new DocumentBuilder(x.DbContext).Create(Fixture.String(10));
                successfulDestinationDocument.ConsumersMask = successfulDestinationDocument.ConsumersMask | (int) LetterConsumers.Cases;
                successfulDestinationDocument.Template = Fixture.String(10);
                successfulDestinationDocument.DocumentType = (int)DocumentType.Word;
                successfulDestinationDocument.ActivityType = 5802;
                successfulDestinationDocument.ActivityCategory = 5901;

                successfulDeliveryMethod = new DeliveryMethod
                {
                    FileDestination = _successfulPath,
                    Description = Fixture.String(10),
                    DestinationStoredProcedure = string.Empty,
                    EmailStoredProcedure = string.Empty,
                    Type = KnownDeliveryTypes.SaveDraftEmail
                };
                x.InsertWithNewId(successfulDeliveryMethod);
                successfulDestinationDocument.DeliveryMethodId = successfulDeliveryMethod.Id;
                var user = new Users(x.DbContext)
                           .WithPermission(ApplicationTask.ConfigureAttachmentsIntegration)
                           .WithPermission(ApplicationTask.CreateMsWordDocument)
                           .Create();
                x.DbContext.SaveChanges();
                return new
                {
                    user,
                    case1
                };
            });
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/attachments", data.user.Username, data.user.Password);
            driver.With<AttachmentsSettingsPage>(settingPage =>
            {
                var topic = new AttachmentsSettingsPage.StorageLocationsTopic(driver);
                topic.Grid.ClickDelete(1);
                settingPage.Save();
            });

            SignIn(driver, $"/#/caseview/{data.case1.Id}?isE2e=1", data.user.Username, data.user.Password);

            var leftMenuTabs = driver.FindElements(By.CssSelector(".topic-menu ul.nav-tabs li"));
            Assert.AreEqual(2, leftMenuTabs.Count);

            leftMenuTabs[1].WithJs().Click();
            driver.WaitForAngular();
            var tasks = driver.FindElements(By.CssSelector(".topic-menu div.tab-content div.tab-pane.content-block.active ul li"));

            Assert.AreEqual(1, tasks.Count);
            tasks[0].WithJs().Click();
            driver.WaitForAngular();

            driver.With<GenerateWordModalPageObject>(modal =>
            {
                Assert.True(modal.Modal.Displayed);

                modal.Document.EnterAndSelect(failingDestinationDocument?.Name);
                driver.WaitForAngular();
                Assert.False(modal.AddAsAttachment.IsChecked);
                Assert.False(modal.AttachmentPage.AttachmentName.Input.Enabled);
                Assert.False(modal.AttachmentPage.FilePath.Input.Enabled);
                Assert.True(modal.AttachmentPage.ActivityType.IsDisabled);
                Assert.True(modal.GenerateButton.Enabled);

                modal.AddAsAttachment.Click();
                Assert.True(modal.AttachmentPage.AttachmentName.Input.Enabled);
                Assert.True(modal.AttachmentPage.FilePath.Input.Enabled);
                Assert.False(modal.AttachmentPage.ActivityType.IsDisabled);
                Assert.AreEqual("attach.doc", modal.AttachmentPage.FileName.Text);
                Assert.False(modal.GenerateButton.Enabled);

                driver.WaitForAngular();
                Assert.AreEqual(failingDestination, modal.AttachmentPage.FilePath.Text);
                Assert.True(modal.AttachmentPage.FilePath.HasError, "Should show error because file path is not in attachment settings");
                Assert.False(modal.GenerateButton.Enabled);

                modal.Document.EnterAndSelect(successfulDestinationDocument?.Name);
                driver.WaitForAngular();
                Assert.False(modal.AttachmentPage.FilePath.HasError, "Should not show error because file path is in attachment settings");

                Assert.AreEqual(successfulDeliveryMethod.FileDestination, modal.AttachmentPage.FilePath.Text);
                Assert.AreEqual("attach.doc", modal.AttachmentPage.FileName.Text);
                Assert.AreEqual("5802", modal.AttachmentPage.ActivityType.Value);
                Assert.AreEqual("5901", modal.AttachmentPage.ActivityCategory.Value);
                Assert.True(modal.GenerateButton.Enabled);
                modal.GenerateButton.Click();
                driver.Wait().ForAlert();
                var alert = driver.SwitchTo().Alert();
                Assert.True(alert.Text.StartsWith("inprodoc:"));
                alert.Accept();
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ShouldNotSeeWordOptionIfHasNoTaskSecurity(BrowserType browserType)
        {
            var user = new Users().Create();

            var @case = DbSetup.Do(x =>
            {
                var case1 = new CaseBuilder(x.DbContext).CreateWithSummaryData().Case;
                return case1;
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/caseview/{@case.Id}", user.Username, user.Password);

            var leftMenuTabs = driver.FindElements(By.CssSelector(".topic-menu ul.nav-tabs li"));
            Assert.AreEqual(1, leftMenuTabs.Count);
        }

        public class GenerateWordModalPageObject : PageObject
        {
            public GenerateWordModalPageObject(NgWebDriver driver) : base(driver)
            {
            }

            public AngularPicklist Document => new AngularPicklist(Driver).ByName("documentName");
            public AngularCheckbox AddAsAttachment => new AngularCheckbox(Driver).ByName("addAsAttachment");
            public NgWebElement GenerateButton => Driver.FindElement(By.CssSelector(".btn-save"));
            public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
            public AttachmentPageObj AttachmentPage => new AttachmentPageObj(Driver);
        }
    }
}