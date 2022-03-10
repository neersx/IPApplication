using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Documents;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess
{
    public class DocumentIssuesFacts : FactBase
    {
        readonly ISimpleExcelExporter _excelExporter = Substitute.For<ISimpleExcelExporter>();
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();

        DocumentIssues CreateSubject()
        {
            _fileSystem.AbsolutePath(Arg.Any<string>()).Returns(x => x[0]);
            _fileSystem.OpenWrite(Arg.Any<string>()).Returns(new MemoryStream());
            _excelExporter.Export(null).ReturnsForAnyArgs(new MemoryStream());

            return new DocumentIssues(Db, _excelExporter, _fileSystem);
        }

        [Fact]
        public async Task DoesNotSaveWhenThereAreNoErrors()
        {
            var subject = CreateSubject();

            await subject.Prepare(Fixture.String());

            _excelExporter.DidNotReceiveWithAnyArgs().Export(null);
        }

        [Fact]
        public async Task SavesDocumentLevelIssues()
        {
            var d = new Document
            {
                ApplicationNumber = "123",
                PublicationNumber = "456",
                RegistrationNumber = "789",
                Errors = new ErrorBuilder
                {
                    ActivityType = GetType().AssemblyQualifiedName,
                    Message = "Oh bummer!"
                }.Build()
            }.In(Db);

            var subject = CreateSubject();

            await subject.Prepare(Fixture.String());

            _excelExporter
                .Received(1)
                .Export(Arg.Is<IEnumerable<DocumentLevelErrorDetail>>(_
                                                                          => _.Single().ApplicationNumber == d.ApplicationNumber &&
                                                                             _.Single().PublicationNumber == d.PublicationNumber &&
                                                                             _.Single().RegistrationNumber == d.RegistrationNumber &&
                                                                             _.Single().Activity == GetType().FullName &&
                                                                             _.Single().Message == "Oh bummer!"));
        }
    }
}