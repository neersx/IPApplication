using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.DocumentGeneration;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class DocumentsPicklistControllerFacts : FactBase
    {
        public class DocumentsPicklistControllerFixture : IFixture<DocumentsPicklistController>
        {
            public DocumentsPicklistControllerFixture(InMemoryDbContext db)
            {
                var cultureResolver = Substitute.For<IPreferredCultureResolver>();

                Subject = new DocumentsPicklistController(db, cultureResolver);
            }
            public DocumentsPicklistController Subject { get; }
        }

        public class Compatibility : FactBase
        {
            [Fact]
            public async Task ShouldReturnTemplatesWithoutInprodoc()
            {
                var controller = new DocumentsPicklistControllerFixture(Db).Subject;

                var doc1 = new Document("dgLib-word", "dglib-word") {ConsumersMask = (int) LetterConsumers.DgLib, DocumentType = (int) DocumentType.Word}.In(Db);
                var doc2 = new Document("notset-word", "notset-word") {ConsumersMask = (int) LetterConsumers.NotSet, DocumentType = (int) DocumentType.Word}.In(Db);
                new Document("inproDoc-word", "inproDoc-word") {ConsumersMask = (int) LetterConsumers.InproDoc, DocumentType = (int) DocumentType.Word}.In(Db);
               
                var options = new DocumentsPicklistController.DocumentGenerationOptions
                {
                    Legacy = true,
                    CaseKey = null,
                    InproDocOnly = false,
                    PdfOnly = false,
                    NameKey = null
                };
                var r = await controller.Search(null, String.Empty, options);

                Assert.Equal(2, r.Pagination.Total);
                var data = r.Data.OfType<DocumentsPicklistController.DocumentPicklistItem>().ToArray();
                Assert.Equal(doc1.Id, data.First().Key);
                Assert.Equal(doc2.Id, data.Last().Key);
            }

            [Fact]
            public async Task ShouldExcludeIncompatibleDocuments()
            {
                var controller = new DocumentsPicklistControllerFixture(Db).Subject;

                new Document("yes 1", "yes 1") {Template = "t", ConsumersMask = (int) LetterConsumers.DgLib}.In(Db);
                new Document("yes 2", "yes 2") {Template = "t", ConsumersMask = (int) LetterConsumers.Cases}.In(Db);
                new Document("no good", "no good") {Template = "t", ConsumersMask = (int) LetterConsumers.InproDoc}.In(Db);
                new Document("yes 3", "yes 3") {Template = "t"}.In(Db);

                var r = await controller.Search(null, "t", new DocumentsPicklistController.DocumentGenerationOptions
                {
                    Legacy = true
                });

                Assert.Equal(3, r.Pagination.Total);
                Assert.DoesNotContain(r.Data, _ => _.Code == "no good");
            }

            [Fact]
            public async Task ShouldFallbackToOtherMatches()
            {
                var controller = new DocumentsPicklistControllerFixture(Db).Subject;

                const string numericSearch = "11";

                new Document("in-exact-doc-Id-Match", string.Empty).In(Db);
                var doc2 = new Document("111", "111").In(Db);

                var r = await controller.Search(null, numericSearch);

                Assert.Equal(1, r.Pagination.Total);
                Assert.Equal(doc2.Id, r.Data.Single().Key);
            }

            [Fact]
            public async Task ShouldOnlyReturnMatchedDocumentNumber()
            {
                var controller = new DocumentsPicklistControllerFixture(Db).Subject;

                var doc = new Document().In(Db);

                var r = await controller.Search(null, doc.Id.ToString());

                Assert.Equal(1, r.Pagination.Total);
                Assert.Equal(doc.Id, r.Data.Single().Key);
            }

            [Fact]
            public async Task ShouldReturnAllIfSearchIsBlank()
            {
                var controller = new DocumentsPicklistControllerFixture(Db).Subject;

                var doc = new Document().In(Db);
                var r = await controller.Search(null, null);

                Assert.Equal(1, r.Pagination.Total);
                Assert.Equal(doc.Id, r.Data.Single().Key);
            }

            [Fact]
            public async Task ShouldReturnExactMatchFirst()
            {
                var controller = new DocumentsPicklistControllerFixture(Db).Subject;

                new Document("name12", "c12").In(Db);
                var doc2 = new Document("name1", "c1").In(Db);
                var r = await controller.Search(null, "name1");

                Assert.Equal(2, r.Pagination.Total);
                Assert.Equal(doc2.Id, r.Data.First().Key);
            }

            [Fact]
            public async Task ShouldReturnMatchedDescription()
            {
                var controller = new DocumentsPicklistControllerFixture(Db).Subject;

                var doc = new Document("name1", "code1").In(Db);
                var r = await controller.Search(null, "name1");

                Assert.Equal(1, r.Pagination.Total);

                dynamic d = r.Data.Single();
                Assert.Equal(doc.Id, d.Key);
            }

            [Fact]
            public async Task ShouldReturnMatchedDocumentCode()
            {
                var controller = new DocumentsPicklistControllerFixture(Db).Subject;

                var doc = new Document("name1", "code1").In(Db);
                var r = await controller.Search(null, "code1");

                Assert.Equal(1, r.Pagination.Total);
                Assert.Equal(doc.Id, r.Data.Single().Key);
            }

            [Fact]
            public async Task ShouldReturnMatchedTemplate()
            {
                var controller = new DocumentsPicklistControllerFixture(Db).Subject;

                var doc = new Document("name1", "code1") {Template = "t1"}.In(Db);
                var r = await controller.Search(null, "t1");

                Assert.Equal(1, r.Pagination.Total);
                Assert.Equal(doc.Template, r.Data.Single().Template);
            }

            [Fact]
            public async Task ShouldReturnResultsInSpecifiedOrder()
            {
                var controller = new DocumentsPicklistControllerFixture(Db).Subject;

                var doc1 = new Document("name2", "c4") {Template = "t"}.In(Db);
                var doc2 = new Document("name2", "c3") {Template = "t"}.In(Db);
                var doc3 = new Document("name1", "c2") {Template = "t"}.In(Db);
                var doc4 = new Document("name1", "c1") {Template = "t"}.In(Db);

                var r = await controller.Search(null, "t");
                var rows = r.Data.ToArray();

                Assert.Equal(4, r.Pagination.Total);
                Assert.Equal(doc4.Id, rows[0].Key);
                Assert.Equal(doc3.Id, rows[1].Key);
                Assert.Equal(doc2.Id, rows[2].Key);
                Assert.Equal(doc1.Id, rows[3].Key);
            }
        }

        public class AdHocTemplates : FactBase
        {
            [Fact]
            public async Task RetreiveDocumentConflictValue()
            {
                var f = new DocumentsPicklistControllerFixture(Db);
                var options = new DocumentsPicklistController.DocumentGenerationOptions
                {
                    Legacy = true,
                    InproDocOnly = true,
                    CaseKey = 434
                };

                await Assert.ThrowsAsync<ArgumentException>(async () => await f.Subject.Search(null, string.Empty, options));
            }

            [Fact]
            public async Task RetreiveDocumentNoNameOrCaseValue()
            {
                var f = new DocumentsPicklistControllerFixture(Db);
                var options = new DocumentsPicklistController.DocumentGenerationOptions
                {
                    InproDocOnly = true
                };

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.Search(null, "BDocument", options));
            }

            [Fact]
            public async Task RetreiveDocumentOnDocumentCodeAndNo()
            {
                var f = new DocumentsPicklistControllerFixture(Db);

                var doc = new Document(1001, "templateA", "codeA", 2) {DeliveryMethodId = 1, ConsumersMask = (int) LetterConsumers.Cases, Name = "ADocument"}.In(Db);
                var doc2 = new Document(2002, "templateB", "CodeB", 2) {DeliveryMethodId = 1, ConsumersMask = (int) LetterConsumers.Cases, Name = "BDocument"}.In(Db);
                new DeliveryMethod
                {
                    Id = 1,
                    FileDestination = "fileDestination",
                    DestinationStoredProcedure = "DestinationSp"
                }.In(Db);
                var @case = new CaseBuilder().BuildWithId(876).In(Db);
                var options = new DocumentsPicklistController.DocumentGenerationOptions
                {
                    Legacy = false,
                    CaseKey = @case.Id,
                    PdfOnly = true
                };

                var r = await f.Subject.Search(null, "codeA", options);
                var data = r.Data.OfType<DocumentsPicklistController.DocumentPicklistItem>().ToArray();
                Assert.Equal(1, data.Count());
                Assert.Equal(doc.Id, data.First().Key);

                var r2 = await f.Subject.Search(null, "200", options);
                var data2 = r2.Data.OfType<DocumentsPicklistController.DocumentPicklistItem>().ToArray();
                Assert.Equal(1, data2.Count());
                Assert.Equal(doc2.Id, data2.First().Key);
            }

            [Fact]
            public async Task RetreiveDocumentOnSearchCaseCorrect()
            {
                var f = new DocumentsPicklistControllerFixture(Db);

                new Document(1, "templateA", 1) {DeliveryMethodId = 1, ConsumersMask = (int) LetterConsumers.Cases, Name = "ADocument"}.In(Db);
                var doc2 = new Document(1, "templateB", 1) {DeliveryMethodId = 1, ConsumersMask = (int) LetterConsumers.Cases, Name = "BDocument", DocumentType = 2}.In(Db);

                var @case = new CaseBuilder().BuildWithId(876).In(Db);
                var options = new DocumentsPicklistController.DocumentGenerationOptions
                {
                    Legacy = false,
                    CaseKey = @case.Id,
                    PdfOnly = true
                };

                var r = await f.Subject.Search(null, "BDocument", options);
                var data = r.Data.OfType<DocumentsPicklistController.DocumentPicklistItem>().ToArray();
                Assert.Equal(1, data.Count());
                Assert.Equal(doc2.Id, data.First().Key);
            }

            [Fact]
            public async Task RetreiveDocumentOnSearchCaseCountryCodeCorrect()
            {
                var f = new DocumentsPicklistControllerFixture(Db);

                var doc1 = new Document(1, "templateA", 1, "countryCode") {DeliveryMethodId = 1, ConsumersMask = (int) LetterConsumers.Cases, Name = "ADocument"}.In(Db);
                new Document(2, "templateB", 1, "countryCode2") {DeliveryMethodId = 1, ConsumersMask = (int) LetterConsumers.Cases, Name = "BDocument"}.In(Db);
                var @case = new CaseBuilder {CountryCode = "countryCode"}.BuildWithId(876).In(Db);
                var options = new DocumentsPicklistController.DocumentGenerationOptions
                {
                    Legacy = false,
                    CaseKey = @case.Id,
                    InproDocOnly = true
                };

                var r = await f.Subject.Search(null, string.Empty, options);
                var data = r.Data.OfType<DocumentsPicklistController.DocumentPicklistItem>().ToArray();
                Assert.Equal(1, data.Count());
                Assert.Equal(doc1.Id, data.First().Key);
            }

            [Fact]
            public async Task RetreiveDocumentOnSearchPdfCorrect()
            {
                var f = new DocumentsPicklistControllerFixture(Db);

                var doc = new Document(1, "templateA", 1) {DeliveryMethodId = 1, ConsumersMask = (int) LetterConsumers.Cases, Name = "ADocument"}.In(Db);
                new Document(2, "templateB", 1) {DeliveryMethodId = 1, ConsumersMask = (int) LetterConsumers.Cases, Name = "ADocument2", DocumentType = 2}.In(Db);
                var @case = new CaseBuilder().BuildWithId(876).In(Db);
                var options = new DocumentsPicklistController.DocumentGenerationOptions
                {
                    Legacy = false,
                    CaseKey = @case.Id,
                    InproDocOnly = true
                };

                var r = await f.Subject.Search(null, "ADoc", options);
                var data = r.Data.OfType<DocumentsPicklistController.DocumentPicklistItem>().ToArray();
                Assert.Equal(1, data.Count());
                Assert.Equal(doc.Id, data.First().Key);
            }

            [Fact]
            public async Task RetrieveDocumentsCorrectOrder()
            {
                var f = new DocumentsPicklistControllerFixture(Db);

                var doc = new Document(1, "templateA", 1) {DeliveryMethodId = 1, ConsumersMask = (int) LetterConsumers.Cases, Name = "ADocument"}.In(Db);
                var doc2 = new Document(2, "templateB", 1) {DeliveryMethodId = 1, ConsumersMask = (int) LetterConsumers.Cases, Name = "BDocument"}.In(Db);
                var @case = new CaseBuilder().BuildWithId(876).In(Db);
                var options = new DocumentsPicklistController.DocumentGenerationOptions
                {
                    Legacy = false,
                    CaseKey = @case.Id,
                    InproDocOnly = true
                };

                var r = await f.Subject.Search(null, string.Empty, options);
                var data = r.Data.OfType<DocumentsPicklistController.DocumentPicklistItem>().ToArray();
                Assert.Equal(2, data.Count());
                Assert.Equal(doc.Id, data.First().Key);
                Assert.Equal(doc2.Id, data.Last().Key);
            }

            [Fact]
            public async Task RetrieveDocumentsNames()
            {
                var f = new DocumentsPicklistControllerFixture(Db);

                var doc = new Document(1, "templateA", 1) {DeliveryMethodId = 1, ConsumersMask = (int) LetterConsumers.Names, Name = "ADocument"}.In(Db);
                var doc2 = new Document(2, "templateB", 1) {DeliveryMethodId = 1, ConsumersMask = (int) LetterConsumers.Names, Name = "BDocument"}.In(Db);
                var nameKey = 10000;
                var options = new DocumentsPicklistController.DocumentGenerationOptions
                {
                    Legacy = false,
                    InproDocOnly = true,
                    NameKey = nameKey
                };

                var r = await f.Subject.Search(null, string.Empty, options);
                var data = r.Data.OfType<DocumentsPicklistController.DocumentPicklistItem>().ToArray();
                Assert.Equal(2, data.Count());
                Assert.Equal(doc.Id, data.First().Key);
                Assert.Equal(doc2.Id, data.Last().Key);
            }

            [Fact]
            public async Task RetrieveWordDocumentsNoDigitTemplateForCase()
            {
                var f = new DocumentsPicklistControllerFixture(Db);

                new Document("case-dgLib-word", "case-dglib-word") {ConsumersMask = (int) LetterConsumers.Cases + (int) LetterConsumers.DgLib, DocumentType = (int) DocumentType.Word}.In(Db);
                var doc1 = new Document("case-notset-word", "case-notset-word") {ConsumersMask = (int) LetterConsumers.Cases, DocumentType = (int) DocumentType.Word}.In(Db);
                var doc2 = new Document("case-inproDoc-word", "case-inproDoc-word") {ConsumersMask = (int) LetterConsumers.Cases + (int) LetterConsumers.InproDoc, DocumentType = (int) DocumentType.Word}.In(Db);
                var @case = new CaseBuilder().BuildWithId(876).In(Db);
                var options = new DocumentsPicklistController.DocumentGenerationOptions
                {
                    Legacy = false,
                    CaseKey = @case.Id,
                    InproDocOnly = true
                };

                var r = await f.Subject.Search(null, string.Empty, options);
                var data = r.Data.OfType<DocumentsPicklistController.DocumentPicklistItem>().ToArray();
                Assert.Equal(2, data.Count());
                Assert.Equal(doc2.Id, data.First().Key);
                Assert.Equal(doc1.Id, data.Last().Key);
            }

            [Fact]
            public async Task RetrievePdfDocumentsForCase()
            {
                var f = new DocumentsPicklistControllerFixture(Db);

                var pdf1 = new Document("case-inproDoc-pdf", "case-inproDoc-pdf") {ConsumersMask = (int) LetterConsumers.Cases + (int) LetterConsumers.InproDoc, DocumentType = (int) DocumentType.PDF}.In(Db);
                var pdf2 = new Document("case-notSet-pdf", "case-notSet-pdf") {ConsumersMask = (int) LetterConsumers.Cases, DocumentType = (int) DocumentType.PDF}.In(Db);
                var pdf3 = new Document("case-dgLib-pdf", "case-dgLib-pdf") {ConsumersMask = (int) LetterConsumers.Cases + (int) LetterConsumers.DgLib, DocumentType = (int) DocumentType.PDF}.In(Db);

                var @case = new CaseBuilder().BuildWithId(876).In(Db);
                var options = new DocumentsPicklistController.DocumentGenerationOptions
                {
                    Legacy = false,
                    CaseKey = @case.Id,
                    PdfOnly = true
                };

                var r = await f.Subject.Search(null, string.Empty, options);
                var data = r.Data.OfType<DocumentsPicklistController.DocumentPicklistItem>().ToArray();
                Assert.Equal(3, data.Count());
                Assert.Equal(pdf3.Id, data.First().Key);
                Assert.Equal(pdf1.Id, data[1].Key);
                Assert.Equal(pdf2.Id, data.Last().Key);
            }

            [Fact]
            public async Task RetrieveWordDocumentsNoDigitTemplateForName()
            {
                var f = new DocumentsPicklistControllerFixture(Db);

                new Document("name-dgLib-word", "name-dglib-word") {ConsumersMask = (int) LetterConsumers.Names + (int) LetterConsumers.DgLib, DocumentType = (int) DocumentType.Word}.In(Db);
                var doc1 = new Document("name-notset-word", "name-notset-word") {ConsumersMask = (int) LetterConsumers.Names, DocumentType = (int) DocumentType.Word}.In(Db);
                var doc2 = new Document("name-inproDoc-word", "name-inproDoc-word") {ConsumersMask = (int) LetterConsumers.Names + (int) LetterConsumers.InproDoc, DocumentType = (int) DocumentType.Word}.In(Db);
                var options = new DocumentsPicklistController.DocumentGenerationOptions
                {
                    Legacy = false,
                    NameKey = 123,
                    InproDocOnly = true
                };

                var r = await f.Subject.Search(null, string.Empty, options);
                var data = r.Data.OfType<DocumentsPicklistController.DocumentPicklistItem>().ToArray();
                Assert.Equal(2, data.Count());
                Assert.Equal(doc2.Id, data.First().Key);
                Assert.Equal(doc1.Id, data.Last().Key);
            }

            [Fact]
            public async Task RetrievePdfDocumentsForName()
            {
                var f = new DocumentsPicklistControllerFixture(Db);

                var pdf1 = new Document("name-inproDoc-pdf", "name-inproDoc-pdf") {ConsumersMask = (int) LetterConsumers.Names + (int) LetterConsumers.InproDoc, DocumentType = (int) DocumentType.PDF}.In(Db);
                var pdf2 = new Document("name-notSet-pdf", "name-notSet-pdf") {ConsumersMask = (int) LetterConsumers.Names, DocumentType = (int) DocumentType.PDF}.In(Db);
                var pdf3 = new Document("name-dgLib-pdf", "name-dgLib-pdf") {ConsumersMask = (int) LetterConsumers.Names + (int) LetterConsumers.DgLib, DocumentType = (int) DocumentType.PDF}.In(Db);

                var options = new DocumentsPicklistController.DocumentGenerationOptions
                {
                    Legacy = false,
                    NameKey = 123,
                    PdfOnly = true
                };

                var r = await f.Subject.Search(null, string.Empty, options);
                var data = r.Data.OfType<DocumentsPicklistController.DocumentPicklistItem>().ToArray();
                Assert.Equal(3, data.Count());
                Assert.Equal(pdf3.Id, data.First().Key);
                Assert.Equal(pdf1.Id, data[1].Key);
                Assert.Equal(pdf2.Id, data.Last().Key);
            }
        }
    }
}