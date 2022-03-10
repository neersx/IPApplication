using System.Linq;
using Inprotech.Integration.CaseSource.FileApp;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Integration.PtoAccess;
using Xunit;
using FileCaseEntity = InprotechKaizen.Model.Integration.FileCase;

namespace Inprotech.Tests.Integration.CaseSource.FileApp
{
    public class FileAppSourceRestrictorFacts : FactBase
    {
        [Fact]
        public void ShouldNotReturnAsItDoesNotExistsAsFilingInstructionsInFile()
        {
            var caseId = Fixture.Integer();

            var source = new[]
            {
                new EligibleCaseItem
                {
                    CaseKey = caseId
                }
            }.AsQueryable();

            var r = new FileAppSourceRestrictor(Db).Restrict(source, DownloadType.All);

            Assert.Empty(r);
        }

        [Fact]
        public void ShouldReturnBecauseItExistsAsFilingInstructionsInFile()
        {
            var caseId = Fixture.Integer();

            var source = new[]
            {
                new EligibleCaseItem
                {
                    CaseKey = caseId
                }
            }.AsQueryable();

            new FileCaseEntity
            {
                CaseId = caseId
            }.In(Db);

            var r = new FileAppSourceRestrictor(Db).Restrict(source, DownloadType.All);

            Assert.NotEmpty(r);
        }
    }
}