using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Integration.Notifications;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess
{
    public class CaseIssuesFacts : FactBase
    {
        readonly ISimpleExcelExporter _excelExporter = Substitute.For<ISimpleExcelExporter>();
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();

        CaseIssues CreateSubject()
        {
            _fileSystem.AbsolutePath(Arg.Any<string>()).Returns(x => x[0]);
            _fileSystem.OpenWrite(Arg.Any<string>()).Returns(new MemoryStream());
            _excelExporter.Export(null).ReturnsForAnyArgs(new MemoryStream());

            return new CaseIssues(Db, _excelExporter, _fileSystem);
        }

        [Fact]
        public async Task DoesNotSaveWhenThereAreNoErrors()
        {
            var subject = CreateSubject();

            await subject.Prepare(Fixture.String());

            _excelExporter.DidNotReceiveWithAnyArgs().Export(null);
        }

        [Fact]
        public async Task SavesCaseLevelIssues()
        {
            var cn = new CaseNotificationBuilder(Db)
            {
                Type = CaseNotificateType.Error,
                ApplicationNumber = "123",
                PublicationNumber = "456",
                RegistrationNumber = "789",
                Body = new ErrorBuilder
                {
                    ActivityType = GetType().AssemblyQualifiedName,
                    Message = "Oh bummer!"
                }.Build()
            }.Build();

            var subject = CreateSubject();

            await subject.Prepare(Fixture.String());

            _excelExporter
                .Received(1)
                .Export(Arg.Is<IEnumerable<CaseLevelErrorDetail>>(_
                                                                      => _.Single().IdentifiedInprotechCaseId == cn.Case.CorrelationId &&
                                                                         _.Single().ApplicationNumber == cn.Case.ApplicationNumber &&
                                                                         _.Single().PublicationNumber == cn.Case.PublicationNumber &&
                                                                         _.Single().RegistrationNumber == cn.Case.RegistrationNumber &&
                                                                         _.Single().Activity == GetType().FullName &&
                                                                         _.Single().Message == "Oh bummer!"));
        }
    }
}