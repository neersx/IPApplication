using System;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using InprotechKaizen.Model.Persistence;
using FileCaseEntity = InprotechKaizen.Model.Integration.FileCase;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    public interface IFileIntegrationStatus
    {
        Task Update(FileSettings fileSetting, FileCaseModel fileCaseModel, FileCase updatedFileCase);
    }

    public class FileIntegrationStatus : IFileIntegrationStatus
    {
        readonly IDbContext _dbContext;
        readonly IFileIntegrationEvent _fileIntegrationEvent;

        public FileIntegrationStatus(IDbContext dbContext, IFileIntegrationEvent fileIntegrationEvent)
        {
            _dbContext = dbContext;
            _fileIntegrationEvent = fileIntegrationEvent;
        }

        public async Task Update(FileSettings fileSetting, FileCaseModel fileCaseModel, FileCase updatedFileCase)
        {
            if (fileSetting == null) throw new ArgumentNullException(nameof(fileSetting));
            if (fileCaseModel == null) throw new ArgumentNullException(nameof(fileCaseModel));
            if (updatedFileCase == null) throw new ArgumentNullException(nameof(updatedFileCase));
            
            using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var parentCaseId = int.Parse(fileCaseModel.ParentCaseId);

                var db = _dbContext.Set<FileCaseEntity>();

                if (!db.Any(_ => _.CaseId == parentCaseId && _.IpType == updatedFileCase.IpType))
                {
                    db.Add(new FileCaseEntity
                    {
                        CaseId = parentCaseId,
                        IpType = updatedFileCase.IpType
                    });

                    await _dbContext.SaveChangesAsync();
                }

                foreach (var country in updatedFileCase.Countries)
                {
                    var countrySelectedInFile = fileCaseModel
                            .CountrySelections
                            .SingleOrDefault(_ => _.Code == country.Code && _.Irn == country.Ref);

                    if (countrySelectedInFile == null)
                    {
                        // End user can select/deselect countries
                        continue;
                    }

                    if (fileSetting.FileIntegrationEvent.HasValue)
                    {
                        await _fileIntegrationEvent.AddOrUpdate(countrySelectedInFile.CaseId, fileSetting);
                    }

                    if (!db.Any(_ => _.CaseId == countrySelectedInFile.CaseId && _.IpType == updatedFileCase.IpType && _.ParentCaseId == parentCaseId))
                    {
                        db.Add(new FileCaseEntity
                        {
                            CaseId = countrySelectedInFile.CaseId,
                            CountryCode = countrySelectedInFile.Code,
                            IpType = updatedFileCase.IpType,
                            InstructionGuid = country.InstructionGuid,
                            ParentCaseId = parentCaseId
                        });

                        await _dbContext.SaveChangesAsync();
                    }
                }

                tcs.Complete();
            }
        }
    }
}