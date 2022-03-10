using System.Data.Entity;
using System.Threading.Tasks;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using InprotechKaizen.Model.Persistence;
using FileCaseEntity = InprotechKaizen.Model.Integration.FileCase;

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.Activities
{
    public interface IFileCaseUpdator
    {
        Task UpdateFileCase(DataDownload dataDownload, Instruction instruction);
    }

    public class FileCaseUpdator : IFileCaseUpdator
    {
        readonly IDbContext _dbContext;

        public FileCaseUpdator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task UpdateFileCase(DataDownload dataDownload, Instruction instruction)
        {
            var fileCase = dataDownload.GetExtendedDetails<FileCase>();

            var caseId = dataDownload.Case.CaseKey;
            var statusToUpdate = instruction.Status;

            var fileCaseEntity = await _dbContext.Set<FileCaseEntity>()
                                                 .SingleOrDefaultAsync(_ => _.CaseId == caseId && _.IpType == fileCase.IpType);

            if (fileCaseEntity != null && fileCaseEntity.Status != statusToUpdate)
            {
                fileCaseEntity.Status = statusToUpdate;
                await _dbContext.SaveChangesAsync();
            }
        }
    }
}