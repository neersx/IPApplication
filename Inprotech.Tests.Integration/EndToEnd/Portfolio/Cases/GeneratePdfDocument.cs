using System.IO;
using System.Linq;
using Inprotech.Infrastructure;
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
using InprotechKaizen.Model.Components.DocumentGeneration.Services;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Documents;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class GeneratePdfDocument : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var doc2 = StorageServiceSetup.MakeAvailable("file.pdf", "Docs");
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
        public void ShouldSeeWarningsIfHavingFieldErrors(BrowserType browserType)
        {
            Document failingDestinationDocument;
            Document successfulDestinationDocument;
            DeliveryMethod successfulDeliveryMethod;
            var failingDestination = Fixture.String(10);

            var data = DbSetup.Do(x =>
            {
                var case1 = new CaseBuilder(x.DbContext).CreateWithSummaryData().Case;

                failingDestinationDocument = new DocumentBuilder(x.DbContext).Create(Fixture.String(10));
                failingDestinationDocument.ConsumersMask = failingDestinationDocument.ConsumersMask | (int)LetterConsumers.Cases;
                failingDestinationDocument.Template = Fixture.String(10);
                failingDestinationDocument.DocumentType = (int) DocumentType.PDF;
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
                successfulDestinationDocument.ConsumersMask = successfulDestinationDocument.ConsumersMask | (int)LetterConsumers.Cases;
                successfulDestinationDocument.Template = Fixture.String(10);
                successfulDestinationDocument.DocumentType = (int)DocumentType.PDF;
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
                           .WithPermission(ApplicationTask.CreatePdfDocument)
                           .Create();
                x.DbContext.SaveChanges();

                var docDirectory = Path.Combine(Path.GetDirectoryName(typeof(Program).Assembly.Location) ?? string.Empty, "Assets");
                var docPath = Path.Combine(docDirectory, "updated_IDS.pdf");
                var formsDirectorySiteControl = x.DbContext.Set<SiteControl>().First(_ => _.ControlId == SiteControls.PDFFormsDirectory);
                formsDirectorySiteControl.StringValue = docDirectory;
                var deliveryMethod = x.InsertWithNewId(new DeliveryMethod { Description = "save", Type = KnownDeliveryTypes.SaveDraftEmail });

                var document = x.InsertWithNewId(new Document("form 1077", "Form 1077")
                {
                    DocumentType = (short)DocumentType.PDF,
                    ConsumersMask = (int)LetterConsumers.Cases,
                    Template = Path.Combine(docDirectory, docPath),
                    DeliveryMethodId = deliveryMethod.Id
                });
                var item = x.DbContext.Set<DocItem>().SingleOrDefault(di => di.Name.Equals("MXMPDF_ADP_ADD_FOR_SERV"));
                x.DbContext.SaveChanges();

                x.Insert(new FormFields { DocumentId = document.Id, FieldDescription = null, FieldName = "Field not exists", FieldType = (int)FieldType.CheckBox, ItemId = item.Id });

                x.DbContext.SaveChanges();
                return new
                {
                    user,
                    case1,
                    document
                };
            });
            var driver = BrowserProvider.Get(browserType);

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
                modal.Document.EnterAndSelect(data.document.Code);
                driver.WaitForAngular();
                Assert.False(modal.AddAsAttachment.IsChecked);
                Assert.True(modal.GenerateButton.Enabled);
                modal.GenerateButton.Click();
                driver.WaitForAngular();
            });

            driver.With<WarningsModalPageObject>(modal =>
            {
                Assert.True(modal.Modal.Displayed);
                Assert.True(modal.AlertInfo.Displayed);
                Assert.AreEqual(1, modal.Grid.Rows.Count);
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ShouldNotSeePdfOptionIfHasNoTaskSecurity(BrowserType browserType)
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

        public class WarningsModalPageObject : PageObject
        {
            public WarningsModalPageObject(NgWebDriver driver) : base(driver)
            {
            }

            public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));

            public NgWebElement AlertInfo => Driver.Wait().ForVisible(By.CssSelector("div.alert-warning"));
            public AngularKendoGrid Grid=>new AngularKendoGrid(Driver,"generateDocumentErros" );
        }
    }
}