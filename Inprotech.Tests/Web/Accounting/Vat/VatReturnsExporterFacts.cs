using System;
using System.Globalization;
using System.IO;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Accounting.VatReturns;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Vat
{
    public class VatReturnsExporterFacts
    {
        public class ReturnVatPdf
        {
            [Fact]
            void ShouldOchestrateAndCallPdfDocument()
            {
                var f = new VatReturnStoreFixture();
                var storedFileStream = new MemoryStream();
                var outputPdfStream = new MemoryStream();
                var fileId = Guid.NewGuid().ToString();
                var request = new VatPdfExportRequest
                {
                    EntityName = Fixture.String(),
                    FromDate = Fixture.PastDate().ToString(CultureInfo.InvariantCulture),
                    ToDate = Fixture.FutureDate().ToString(CultureInfo.InvariantCulture),
                    PdfId = fileId
                };

                f.Filesystem.OpenRead(Path.Combine("vat", $"{fileId}-0.dat"))
                 .Returns(storedFileStream);

                f.Subject.ReturnVatPdf(outputPdfStream, fileId,$"{request.EntityName} {request.FromDate}-to-{request.ToDate}");

                f.CryptoService.Received(1).Decrypt(Arg.Any<string>());
                f.PdfDocument.Received(1).Generate(outputPdfStream, $"{request.EntityName} {request.FromDate}-to-{request.ToDate}.pdf", Arg.Any<string>());
            }
        }

        public class ExportVatReturnPdf
        {
            dynamic CreateVatData()
            {
                return new
                {
                    FromDate = Fixture.PastDate().ToString("dd-MM-yyyy"),
                    ToDate = Fixture.PastDate().ToString("dd-MM-yyyy"),
                    EntityName = "entity",
                    VatNo = "12345",
                    VatValues = new[]
                    {
                        "0.00",
                        "1.25",
                        "2",
                        "3",
                        "4",
                        "5",
                        "6",
                        "7",
                        "8"
                    }, 
                    selectedEntitiesNames = "entityA, entityB"
                };
            }

            static Stream GenerateStreamFromString(string s)
            {
                var stream = new MemoryStream();
                var writer = new StreamWriter(stream);
                writer.Write(s);
                writer.Flush();
                stream.Position = 0;
                return stream;
            }

            [Fact]
            public void ShouldGenerateEncryptedFileContentForTheFailedFullfilled()
            {
                const bool isFullFilled = true;
                const string fileContent = @"##LabelVatBox1####BoxVal1####failureResponse####submitFailedDetails####responseErrorAndMessage####liErrorText##";
                var f = new VatReturnStoreFixture();
                f.Filesystem.OpenRead(Arg.Any<string>())
                 .Returns(GenerateStreamFromString(fileContent));

                var result = f.Subject.ExportVatReturnToPdf(CreateVatData(), new
                {
                    IsSuccessful = false,
                    code = "BUSINESS_ERROR",
                    message = "Business validation error",
                    errors = new[]
                    {
                        new {code = "DUPLICATE_SUBMISSION", message = "The VAT return was already submitted for the given period."}
                    }
                }, isFullFilled);

                Assert.Equal(Guid.Empty.ToString(), result);

                var expected = "accounting.vatSubmitter.vatBox10.00blockaccounting.vatSubmitter.submitFailedBUSINESS_ERROR: Business validation error<li>DUPLICATE_SUBMISSION: The VAT return was already submitted for the given period.</li>";
                f.CryptoService.Received(1).Encrypt(expected);
            }

            [Fact]
            public void ShouldGenerateEncryptedFileContentForTheFailedNonFullfilled()
            {
                const bool isFullFilled = false;
                const string fileContent = @"##LabelVatBox1####BoxVal1####failureResponse####submitFailedDetails####responseErrorAndMessage####liErrorText##";
                var f = new VatReturnStoreFixture();
                f.Filesystem.OpenRead(Arg.Any<string>())
                 .Returns(GenerateStreamFromString(fileContent));

                var result = f.Subject.ExportVatReturnToPdf(CreateVatData(), new
                {
                    IsSuccessful = false,
                    Data = new
                    {
                        code = "BUSINESS_ERROR",
                        message = "Business validation error",
                        errors = new[]
                        {
                            new {code = "DUPLICATE_SUBMISSION", message = "The VAT return was already submitted for the given period."}
                        }
                    }
                }, isFullFilled);

                Assert.Equal(Guid.Empty.ToString(), result);

                var expected = "accounting.vatSubmitter.vatBox10.00blockaccounting.vatSubmitter.submitFailedBUSINESS_ERROR: Business validation error<li>DUPLICATE_SUBMISSION: The VAT return was already submitted for the given period.</li>";
                f.CryptoService.Received(1).Encrypt(expected);
            }

            [Fact]
            public void ShouldGenerateEncryptedFileContentForTheSuccessfullyFullfilled()
            {
                const bool isFullFilled = true;
                const string fileContent = @"##LabelVatBox1####BoxVal1####failureResponse####PaymentIndicator##";
                var f = new VatReturnStoreFixture();
                f.Filesystem.OpenRead(Arg.Any<string>())
                 .Returns(GenerateStreamFromString(fileContent));

                var result = f.Subject.ExportVatReturnToPdf(CreateVatData(), new
                {
                    IsSuccessful = true,
                    ProcessingDate = Fixture.Today(),
                    PaymentIndicator = "DD",
                    FormBundleNumber = Fixture.Integer(),
                    ChargeRefNumber = Fixture.String()
                }, isFullFilled);

                Assert.Equal(Guid.Empty.ToString(), result);

                var expected = "accounting.vatSubmitter.vatBox10.00noneDD";
                f.CryptoService.Received(1).Encrypt(expected);
            }

            [Fact]
            public void ShouldGenerateEncryptedFileContentForTheSuccessfullyNonFullfilled()
            {
                const bool isFullFilled = false;
                const string fileContent = @"##LabelVatBox1####BoxVal1####failureResponse####PaymentIndicator####LabelSubmitSuccessful##";
                var f = new VatReturnStoreFixture();
                f.Filesystem.OpenRead(Arg.Any<string>())
                 .Returns(GenerateStreamFromString(fileContent));

                var result = f.Subject.ExportVatReturnToPdf(CreateVatData(), new
                {
                    IsSuccessful = true,
                    Data = new
                    {
                        processingDate = Fixture.Today(),
                        paymentIndicator = "DD",
                        formBundleNumber = Fixture.Integer(),
                        chargeRefNumber = Fixture.String()
                    }
                }, isFullFilled);

                Assert.Equal(Guid.Empty.ToString(), result);

                var expected = "accounting.vatSubmitter.vatBox10.00noneDDaccounting.vatSubmitter.submitSuccessful";
                f.CryptoService.Received(1).Encrypt(expected);
            }

            [Fact]
            public void ShouldGenerateEncryptedMultipleEntityFileContentForTheSuccessfulSubmit()
            {
                const bool isFullFilled = false;
                const string fileContent = @"##LabelMultipleEntities####BoxVal2####failureResponse####PaymentIndicator####LabelSubmitSuccessful##";
                var f = new VatReturnStoreFixture();
                f.Filesystem.OpenRead(Arg.Any<string>())
                 .Returns(GenerateStreamFromString(fileContent));

                var result = f.Subject.ExportVatReturnToPdf(CreateVatData(), new
                {
                    IsSuccessful = true,
                    Data = new
                    {
                        processingDate = Fixture.Today(),
                        paymentIndicator = "DD",
                        formBundleNumber = Fixture.Integer(),
                        chargeRefNumber = Fixture.String()
                    }
                }, isFullFilled);

                Assert.Equal(Guid.Empty.ToString(), result);

                var expected = "entityA, entityB1.25noneDDaccounting.vatSubmitter.submitSuccessful";
                f.CryptoService.Received(1).Encrypt(expected);
            }
        }

        public class VatReturnStoreFixture : IFixture<VatReturnsExporter>
        {
            public VatReturnStoreFixture()
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(new User());

                var cultureResolver = Substitute.For<IPreferredCultureResolver>();
                cultureResolver.ResolveAll().Returns(new[] {"en"});

                CryptoService = Substitute.For<ICryptoService>();
                CryptoService.Encrypt(Arg.Any<string>()).Returns(x => x[0]);
                CryptoService.Decrypt(Arg.Any<string>()).Returns(x => x[0]);

                var translator = Substitute.For<IStaticTranslator>();
                translator.Translate(Arg.Any<string>(), Arg.Any<string[]>()).Returns(x => x[0]);

                PdfDocument = Substitute.For<IPdfDocument>();

                Filesystem = Substitute.For<IFileSystem>();
                Filesystem.AbsolutePath("vat").Returns("vat");

                Subject = new VatReturnsExporter(translator, cultureResolver, Filesystem, CryptoService, () => Guid.Empty, securityContext, PdfDocument);
            }

            public IPdfDocument PdfDocument { get; set; }

            public ICryptoService CryptoService { get; set; }

            public IFileSystem Filesystem { get; set; }

            public VatReturnsExporter Subject { get; }
        }
    }
}