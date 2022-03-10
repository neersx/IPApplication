using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Integration.DocumentGeneration;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Attachment;
using InprotechKaizen.Model.Components.DocumentGeneration.Delivery;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Attachment
{
    public class CaseDocumentServiceControllerFacts
    {
        public class DocumentDataMethod : FactBase
        {
            [Fact]
            public async Task ShouldCallComponentMethodAndReturnResult()
            {
                var caseId = Fixture.Integer();
                var documentId = Fixture.Integer();
                var fixture = new CaseDocumentServiceControllerFixture(Db);
                var localTemplatePath = Fixture.String();
                var networkTemplatesPath = Fixture.String();
                var fileName = Fixture.String();
                var directoryName = Fixture.String();

                fixture.CaseNamesAdhocDocumentData.Resolve(caseId, null, documentId, true).Returns(Task.FromResult(new AdhocDocumentDataModel
                {
                    LocalTemplatesPath = localTemplatePath,
                    NetworkTemplatesPath = networkTemplatesPath,
                    FileName = fileName,
                    DirectoryName = directoryName
                }));

                var result = await fixture.Subject.DocumentData(caseId, documentId, true);

                fixture.CaseNamesAdhocDocumentData.Received(1).Resolve(caseId, null, documentId, true).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(localTemplatePath, result.LocalTemplatesPath);
                Assert.Equal(networkTemplatesPath, result.NetworkTemplatesPath);
                Assert.Equal(fileName, result.FileName);
                Assert.Equal(directoryName, result.DirectoryName);
            }
        }

        public class DeliveryDestinationMethod : FactBase
        {
            [Fact]
            public async Task ShouldCallComponentMethodAndReturnResult()
            {
                var caseId = Fixture.Integer();
                var documentId = Fixture.Integer();
                var fixture = new CaseDocumentServiceControllerFixture(Db);
                var fileName = Fixture.String();
                var directoryName = Fixture.String();
                fixture.DeliveryDestinationResolver.ResolveForCaseNames(caseId, null, (short)documentId).Returns(Task.FromResult(new DeliveryDestination
                {
                    FileName = fileName,
                    DirectoryName = directoryName
                }));

                var result = await fixture.Subject.DeliveryDestination(caseId, documentId);

                fixture.DeliveryDestinationResolver.Received(1).ResolveForCaseNames(caseId, null, (short)documentId).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(fileName, result.FileName);
                Assert.Equal(directoryName, result.DirectoryName);
            }
        }
        public class DocumentActivityMethod : FactBase
        {
            [Fact]
            public async Task ShouldCallComponentMethodAndReturnResult()
            {
                var caseId = Fixture.Integer();
                var documentId = Fixture.Short();
                var activityType = Fixture.Integer();
                var activityCategory = Fixture.Integer();
                new Document()
                {
                    Id = documentId,
                    ActivityType = activityType,
                    ActivityCategory = activityCategory
                }.In(Db);
                var fixture = new CaseDocumentServiceControllerFixture(Db);

                var result = await fixture.Subject.DocumentActivity(caseId, documentId);

                Assert.Equal(activityType, result.ActivityType);
                Assert.Equal(activityCategory, result.ActivityCategory);
            }
        }

        public class GeneratePdfDocumentMethod : FactBase
        {
            [Fact]
            public async Task ShouldThrowExceptionIfModelIsNull()
            {
                var nameId = Fixture.Integer();
                var fixture = new CaseDocumentServiceControllerFixture(Db);

                await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await fixture.Subject.GeneratePdfDocument(nameId, null);
                });
            }

            [Fact]
            public async Task ShouldCallChildComponentsCorrectly()
            {
                var nameId = Fixture.Integer();
                var culture = Fixture.String();
                var fixture = new CaseDocumentServiceControllerFixture(Db);
                var model = new PdfGenerationModel();
                var expectedResult = new DocumentGenerationResult();
                fixture.PreferredCultureResolver.Resolve().Returns(culture);
                fixture.PdfFormFillService.GeneratePdfDocument(model, culture).Returns(Task.FromResult(expectedResult));
                var result = await fixture.Subject.GeneratePdfDocument(nameId, model);

                fixture.PreferredCultureResolver.Received(1).Resolve();
                fixture.PdfFormFillService.Received(1).GeneratePdfDocument(model, culture).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(expectedResult, result);
            }
        }
        public class CaseDocumentServiceControllerFixture : IFixture<CaseDocumentServiceController>
        {
            
            public CaseDocumentServiceControllerFixture(InMemoryDbContext db)
            {
                CaseNamesAdhocDocumentData = Substitute.For<ICaseNamesAdhocDocumentData>();
                DeliveryDestinationResolver = Substitute.For<IDeliveryDestinationResolver>();
                PdfFormFillService = Substitute.For<IPdfFormFillService>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new CaseDocumentServiceController(db, CaseNamesAdhocDocumentData, DeliveryDestinationResolver, PdfFormFillService, PreferredCultureResolver);
            }

            public IPdfFormFillService PdfFormFillService { get; }
            public IPreferredCultureResolver PreferredCultureResolver { get; }
            public ICaseNamesAdhocDocumentData CaseNamesAdhocDocumentData { get; }
            public IDeliveryDestinationResolver DeliveryDestinationResolver { get; }

            public CaseDocumentServiceController Subject { get; }
        }
    }
}