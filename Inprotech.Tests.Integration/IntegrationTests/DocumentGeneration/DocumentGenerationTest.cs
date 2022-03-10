using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.DocumentGeneration;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.DocumentGeneration;
using InprotechKaizen.Model.Components.DocumentGeneration.Services;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Documents;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.DocumentGeneration
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class DocumentGenerationTest : IntegrationTest
    {
        [Test]
        public async Task PdfGenerationExecution()
        {
            var docPath = StorageServiceSetup.MakeAvailable("pf1077.pdf", "Templates");
            var data = DbSetup.Do(setup =>
            {
                var d = new CaseBuilder(setup.DbContext).CreateWithSummaryData();
                var formsDirectorySiteControl = setup.DbContext.Set<SiteControl>().First(_ => _.ControlId == SiteControls.PDFFormsDirectory);
                formsDirectorySiteControl.StringValue = docPath.folder;
                var deliveryMethod = setup.InsertWithNewId(new DeliveryMethod {Description = "save", Type = KnownDeliveryTypes.Save});

                var document = setup.InsertWithNewId(new Document("form", "Form 1077")
                {
                    DocumentType = (short) DocumentType.PDF,
                    Template = Path.Combine(docPath.folder, docPath.file),
                    DeliveryMethodId = deliveryMethod.Id
                });

                var item = setup.DbContext.Set<DocItem>().SingleOrDefault(di => di.Name.Equals("MXMPDF_ADP_ADD_FOR_SERV"));
                setup.DbContext.SaveChanges();

                setup.Insert(new FormFields {DocumentId = document.Id, FieldDescription = null, FieldName = "ADP NUMBER AGENT", FieldType = (int) FieldType.Text, ItemId = item.Id});

                setup.DbContext.SaveChanges();

                return new
                {
                    d.Case
                };
            });

            var model = new PdfGenerationModel {DocumentId = 123, DocumentName = "documentA", EntryPoint = data.Case.Irn, Template = docPath.file};
            var generationResult = ApiClient.Post<DocumentGenerationResult>($"attachment/case/{data.Case.Id}/document/generate-pdf", JsonConvert.SerializeObject(model));

            Assert.NotNull(generationResult);
            Assert.True(generationResult.IsSuccess);
            Assert.Null(generationResult.Errors);
            Assert.NotNull(generationResult.FileIdentifier);

            var fileResult = ApiClient.Get<HttpResponseMessage>($"attachment/case/{data.Case.Id}/document/get-pdf?fileKey={generationResult.FileIdentifier}");
            Assert.NotNull(fileResult);
            Assert.True(fileResult.IsSuccessStatusCode);
            Assert.NotNull(await fileResult.Content.ReadAsByteArrayAsync());
        }

        [Test]
        public async Task PdfGenerationXfaExecution()
        {
            var docDirectory = Path.Combine(Path.GetDirectoryName(typeof(Program).Assembly.Location) ?? string.Empty, "Assets");
            var docPath = Path.Combine(docDirectory, "updated_IDS.pdf");
            var data = DbSetup.Do(setup =>
            {
                var d = new CaseBuilder(setup.DbContext).CreateWithSummaryData();
                var formsDirectorySiteControl = setup.DbContext.Set<SiteControl>().First(_ => _.ControlId == SiteControls.PDFFormsDirectory);
                formsDirectorySiteControl.StringValue = docDirectory;
                var deliveryMethod = setup.InsertWithNewId(new DeliveryMethod {Description = "save", Type = KnownDeliveryTypes.Save});

                var document = setup.InsertWithNewId(new Document("formXFA", "Form XFA")
                {
                    DocumentType = (short) DocumentType.PDF,
                    Template = docPath,
                    DeliveryMethodId = deliveryMethod.Id
                });

                var item = setup.DbContext.Set<DocItem>().SingleOrDefault(di => di.Name.Equals("IDS_XFA")) ?? setup.InsertWithNewId(new DocItem
                {
                    Name = "IDS_XFA",
                    Sql = "xml_GetIDSDetails",
                    Description = "Information Disclure Statement for XFA",
                    ItemType = 1,
                    EntryPointUsage = 1,
                    SqlDescribe = "4",
                    SqlInto = ":l[0]"
                });

                setup.DbContext.SaveChanges();

                setup.Insert(new FormFields {DocumentId = document.Id, FieldDescription = null, FieldName = "XFA", FieldType = (int) FieldType.XFA, ItemId = item.Id});

                setup.DbContext.SaveChanges();

                return new
                {
                    d.Case
                };
            });

            var model = new PdfGenerationModel {DocumentId = 123, DocumentName = "documentA ", EntryPoint = data.Case.Irn, Template = "updated_IDS.pdf"};
            var generationResult = ApiClient.Post<DocumentGenerationResult>($"attachment/case/{data.Case.Id}/document/generate-pdf", JsonConvert.SerializeObject(model));

            Assert.NotNull(generationResult);
            Assert.True(generationResult.IsSuccess);
            Assert.NotNull(generationResult.FileIdentifier);
            Assert.Null(generationResult.Errors);

            var fileResult = ApiClient.Get<HttpResponseMessage>($"attachment/case/{data.Case.Id}/document/get-pdf?fileKey={generationResult.FileIdentifier}");
            Assert.NotNull(fileResult);
            Assert.True(fileResult.IsSuccessStatusCode);
            Assert.NotNull(await fileResult.Content.ReadAsByteArrayAsync());
        }
    }
}