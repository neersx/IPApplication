using System.Collections.Generic;
using System.Xml.Linq;
using Inprotech.Contracts;
using Inprotech.Tests.Web.Builders.BulkCaseImport;
using Inprotech.Web.BulkCaseImport;
using Inprotech.Web.BulkCaseImport.Validators;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport
{
    public class CpaXmlImportFacts
    {
        public class CpaXmlImportFixture : IFixture<CpaXmlImport>
        {
            public CpaXmlImportFixture()
            {
                CpaXmlValidator = Substitute.For<ICpaXmlValidator>();
                CpaXmlToEde = Substitute.For<ICpaXmlToEde>();
                FileSystem = Substitute.For<IFileSystem>();

                Subject = new CpaXmlImport(CpaXmlValidator, CpaXmlToEde, FileSystem);
            }

            public ICpaXmlToEde CpaXmlToEde { get; }

            public IFileSystem FileSystem { get; }

            public ICpaXmlValidator CpaXmlValidator { get; }
            public CpaXmlImport Subject { get; }
        }

        public class ExecuteMethod
        {
            const string SenderFileName = "xmlFile.xml";
            const string CpaxmlContent = "<cpaxml />";
            const string CpaxmlFileStoredOnServer = "server location";

            [Fact]
            public void OrchestrateCpaXmlLoadToEde()
            {
                var f = new CpaXmlImportFixture();
                XNamespace ns;
                List<ValidationError> errors;
                f.CpaXmlValidator.Validate(CpaxmlContent, SenderFileName, out ns, out errors)
                 .ReturnsForAnyArgs(
                                    x =>
                                    {
                                        x[2] = XNamespace.None;
                                        x[3] = new List<ValidationError>();
                                        return true;
                                    });

                f.FileSystem
                 .AbsoluteUniquePath(Arg.Any<string>(), Arg.Any<string>())
                 .Returns(CpaxmlFileStoredOnServer);

                int batchNumber;
                f.CpaXmlToEde.PrepareEdeBatch(Arg.Any<string>(), out batchNumber).Returns(true);

                var r = f.Subject.Execute(CpaxmlContent, SenderFileName);

                Assert.Equal("success", r.Result);

                f.FileSystem.Received(1).WriteAllText(CpaxmlFileStoredOnServer, CpaxmlContent);

                f.CpaXmlToEde.Received(1).PrepareEdeBatch(CpaxmlFileStoredOnServer, out batchNumber);

                f.CpaXmlToEde.Received(1).Submit(batchNumber);
            }

            [Fact]
            public void OrchestrateCpaXmlLoadToEdeWhenXmlHasNamespaceSpecified()
            {
                var f = new CpaXmlImportFixture();

                XNamespace ns;
                List<ValidationError> errors;
                f.CpaXmlValidator.Validate(Arg.Any<string>(), Arg.Any<string>(), out ns, out errors)
                 .ReturnsForAnyArgs(x =>
                 {
                     x[2] = (XNamespace) "http://www.cpasoftwaresolutions.com";
                     x[3] = new List<ValidationError>();
                     return true;
                 });

                f.FileSystem
                 .AbsoluteUniquePath(Arg.Any<string>(), Arg.Any<string>())
                 .Returns(CpaxmlFileStoredOnServer);

                int batchNumber;
                f.CpaXmlToEde.PrepareEdeBatch(Arg.Any<string>(), out batchNumber).Returns(true);

                var cpaxml = new CpaXmlBuilder().Build().ToString();

                var r = f.Subject.Execute(cpaxml, SenderFileName);

                Assert.Equal("success", r.Result);

                f.FileSystem.Received(0).WriteAllText(CpaxmlFileStoredOnServer, cpaxml);

                f.CpaXmlToEde.Received(1).PrepareEdeBatch(CpaxmlFileStoredOnServer, out batchNumber);

                f.CpaXmlToEde.Received(1).Submit(batchNumber);
            }

            [Fact]
            public void ReturnsErrorFromCpaXmlToEde()
            {
                var f = new CpaXmlImportFixture();

                XNamespace ns;
                List<ValidationError> errors;
                f.CpaXmlValidator.Validate(Arg.Any<string>(), Arg.Any<string>(), out ns, out errors)
                 .ReturnsForAnyArgs(x =>
                 {
                     x[2] = XNamespace.None;
                     x[3] = new List<ValidationError>();
                     return true;
                 });

                f.FileSystem
                 .AbsoluteUniquePath(Arg.Any<string>(), Arg.Any<string>())
                 .Returns(CpaxmlFileStoredOnServer);

                int batchNumber;

                f.CpaXmlToEde.PrepareEdeBatch(Arg.Any<string>(), out batchNumber).Returns(false);

                var r = f.Subject.Execute(CpaxmlContent, SenderFileName);

                Assert.Equal("blocked", r.Result);

                Assert.NotEmpty(r.Errors);
            }

            [Fact]
            public void ReturnsErrorFromValidator()
            {
                var f = new CpaXmlImportFixture();

                XNamespace ns;
                List<ValidationError> errors;
                f.CpaXmlValidator.Validate(Arg.Any<string>(), Arg.Any<string>(), out ns, out errors)
                 .ReturnsForAnyArgs(x =>
                 {
                     x[2] = XNamespace.None;
                     x[3] = new List<ValidationError>(new[] {new ValidationError("errorMessage")});
                     return false;
                 });

                int batchNumber;

                var r = f.Subject.Execute(CpaxmlContent, SenderFileName);

                Assert.Equal("invalid-input", r.Result);

                Assert.NotEmpty(r.Errors);

                f.FileSystem.DidNotReceive().WriteAllText(Arg.Any<string>(), Arg.Any<string>());

                f.CpaXmlToEde.DidNotReceive().PrepareEdeBatch(Arg.Any<string>(), out batchNumber);
            }

            [Fact]
            public void ThrowsAnErrorWhenNothingIsProvided()
            {
                var exception = Record.Exception(
                                                 () => { new CpaXmlImportFixture().Subject.Execute(null, null); });

                Assert.NotNull(exception);
            }
        }
    }
}