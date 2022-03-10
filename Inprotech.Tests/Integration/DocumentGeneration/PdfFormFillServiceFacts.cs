using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.DocumentGeneration;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.DocumentGeneration.Processor;
using InprotechKaizen.Model.Components.DocumentGeneration.Services;
using InprotechKaizen.Model.Components.DocumentGeneration.Services.Pdf;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.DocumentGeneration
{
    public class PdfFormFillServiceFacts
    {
        public class GetGeneratedPdfDocumentMethod
        {
            [Fact]
            public async Task ShouldNotReturnFileDetailsIfNoneInCache()
            {
                var fixture = new PdfFormFillServiceFixture();
                var fileKey = Fixture.String();

                var result = await fixture.Subject.GetGeneratedPdfDocument(fileKey);

                Assert.NotNull(result);
                Assert.Null(result.Content);
            }

            [Fact]
            public async Task ShouldReturnFileDetailsIfInCache()
            {
                var fixture = new PdfFormFillServiceFixture();
                var fileKey = Fixture.String();
                var fileName = Fixture.String();
                fixture.PdfForm.GetCachedDocument(fileKey).Returns(new CachedDocument
                {
                    FileName = fileName,
                    Data = new byte[0]
                });
                var result = await fixture.Subject.GetGeneratedPdfDocument(fileKey);

                Assert.NotNull(result);
                Assert.NotNull(result.Content);
            }
        }

        public class GeneratePdfDocumentMethod
        {
            [Fact]
            public async Task ShouldGenerateCorrectly()
            {
                var fixture = new PdfFormFillServiceFixture();
                var model = new PdfGenerationModel
                {
                    DocumentId = 123,
                    DocumentName = "abc",
                    EntryPoint = Fixture.String(),
                    Template = Fixture.String()
                };
                var culture = Fixture.String();
                fixture.FormFieldsResolver.Resolve(model.DocumentId, culture).Returns(new List<FieldItem> {new FieldItem {FieldName = "field", FieldType = FieldType.Text}});
                fixture.RunDocItemsManager.Execute(Arg.Any<ItemProcessor[]>()).ReturnsForAnyArgs(new List<ItemProcessor>());
                fixture.PdfForm.EnsureExists(Arg.Any<string>()).ReturnsForAnyArgs("template");
                fixture.PdfForm.Fill(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<ItemProcessor[]>()).Returns(Task.CompletedTask);
                fixture.PdfForm.CacheDocument(Arg.Any<string>(), Arg.Any<string>()).ReturnsForAnyArgs("key");
                var result = await fixture.Subject.GeneratePdfDocument(model, culture);

                Assert.NotNull(result);
                Assert.True(result.IsSuccess);
                Assert.Equal("key", result.FileIdentifier);
            }

            [Fact]
            public async Task ShouldThrowExceptionIfEntryPointNull()
            {
                var fixture = new PdfFormFillServiceFixture();
                var model = new PdfGenerationModel
                {
                    EntryPoint = null,
                    Template = Fixture.String()
                };
                var culture = Fixture.String();

                Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.GeneratePdfDocument(model, culture); }).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowExceptionIfTemplateNull()
            {
                var fixture = new PdfFormFillServiceFixture();
                var model = new PdfGenerationModel
                {
                    Template = null,
                    EntryPoint = Fixture.String()
                };
                var culture = Fixture.String();

                Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.GeneratePdfDocument(model, culture); }).IgnoreAwaitForNSubstituteAssertion();
            }
        }
    }

    public class PdfFormFillServiceFixture : IFixture<IPdfFormFillService>
    {
        public PdfFormFillServiceFixture()
        {
            FormFieldsResolver = Substitute.For<IFormFieldsResolver>();
            RunDocItemsManager = Substitute.For<IRunDocItemsManager>();
            PdfForm = Substitute.For<IPdfForm>();
            StorageServiceClient = Substitute.For<IStorageServiceClient>();
            Subject = new PdfFormFillService(FormFieldsResolver, RunDocItemsManager, PdfForm, StorageServiceClient);
        }

        public IFormFieldsResolver FormFieldsResolver { get; }
        public IRunDocItemsManager RunDocItemsManager { get; }
        public IPdfForm PdfForm { get; }
        public IStorageServiceClient StorageServiceClient { get; }

        public IPdfFormFillService Subject { get; }
    }
}