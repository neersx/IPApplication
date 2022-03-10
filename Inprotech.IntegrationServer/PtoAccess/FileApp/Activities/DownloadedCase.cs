using System;
using System.Data.Entity;
using System.Threading.Tasks;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Diagnostics;
using InprotechKaizen.Model.Persistence;
using FileCaseEntity = InprotechKaizen.Model.Integration.FileCase;

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class DownloadedCase
    {
        readonly IDetailsAvailable _detailsAvailable;
        readonly INewCaseDetailsNotification _newCaseDetailsNotification;
        readonly IPtoAccessCase _ptoAccessCase;
        readonly IFileSettingsResolver _fileSettingsResolver;
        readonly IFileApiClient _apiClient;
        readonly IRuntimeEvents _runtimeEvents;
        readonly IFileCaseUpdator _fileCaseUpdator;
        readonly IDbContext _dbContext;

        public DownloadedCase(IPtoAccessCase ptoAccessCase,
            IFileSettingsResolver fileSettingsResolver,
            IFileApiClient apiClient,
            IDetailsAvailable detailsAvailable,
            INewCaseDetailsNotification newCaseDetailsNotification,
            IRuntimeEvents runtimeEvents,
            IFileCaseUpdator fileCaseUpdator,
            IDbContext dbContext)
        {
            _ptoAccessCase = ptoAccessCase;
            _fileSettingsResolver = fileSettingsResolver;
            _apiClient = apiClient;
            _detailsAvailable = detailsAvailable;
            _newCaseDetailsNotification = newCaseDetailsNotification;
            _runtimeEvents = runtimeEvents;
            _fileCaseUpdator = fileCaseUpdator;
            _dbContext = dbContext;
        }

        public async Task Process(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            await _ptoAccessCase.EnsureAvailable(dataDownload.Case);

            var fileCase = dataDownload.GetExtendedDetails<FileCase>();

            Instruction instruction = null;
            if (fileCase.Status == FileStatuses.Instructed)
            {
                var settings = _fileSettingsResolver.Resolve();

                var dbFileCase = await TempGetFileCase(dataDownload, fileCase.IpType);
                var identificationCode = dbFileCase?.InstructionGuid.HasValue == true ? dbFileCase.InstructionGuid.ToString() : dataDownload.Case.CountryCode;

                instruction = await _apiClient.Get<Instruction>(settings.InstructionsApi(fileCase.Id, identificationCode));

                if (instruction != null)
                {
                    await _fileCaseUpdator.UpdateFileCase(dataDownload, instruction);
                }
            }

            await _detailsAvailable.ConvertToCpaXml(dataDownload, instruction);

            await _newCaseDetailsNotification.NotifyIfChanged(dataDownload);

            await _runtimeEvents.CaseProcessed(dataDownload);
        }

        async Task<FileCaseEntity> TempGetFileCase(DataDownload dataDownload, string ipType)
        {
            var caseId = dataDownload.Case.CaseKey;

            return await _dbContext.Set<FileCaseEntity>()
                                   .SingleOrDefaultAsync(_ => _.CaseId == caseId && _.IpType == ipType);

        }
    }
}