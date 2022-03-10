using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.IntegrationServer.PtoAccess.FileApp.Activities;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json;
using Xunit;
using FileCase = InprotechKaizen.Model.Integration.FileCase;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class FileCaseUpdatorFacts : FactBase
    {
        public FileCaseUpdatorFacts()
        {
            _subject = new FileCaseUpdator(Db);
        }

        readonly IFileCaseUpdator _subject;

        [Fact]
        public async Task UpdatesChildCaseStatus()
        {
            new FileCase {CaseId = 1, IpType = "SomeType"}.In(Db);
            new FileCase {CaseId = 2, ParentCaseId = 1, IpType = "SomeType"}.In(Db);

            var fileCase = new FileCase {Id = 1, IpType = "SomeType", Status = "Status1"};
            var instruction = new Instruction {Status = "NewStatus"};

            var dataDownload = new DataDownload {AdditionalDetails = JsonConvert.SerializeObject(fileCase), Case = new EligibleCase(2, "AU")};

            await _subject.UpdateFileCase(dataDownload, instruction);

            var result = Db.Set<FileCase>().Single(_ => _.CaseId == 2);
            Assert.Equal(2, result.CaseId);
            Assert.Equal("NewStatus", result.Status);
        }
    }
}