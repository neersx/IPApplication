using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.IPPlatform.FileApp.Builders;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.Integration.IPPlatform.FileApp.Post;
using Inprotech.Integration.IPPlatform.FileApp.Validators;
using InprotechKaizen.Model.Persistence;
using FileCaseEntity = InprotechKaizen.Model.Integration.FileCase;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    public interface IFileApi
    {
        Task<(InstructResult Result, FileCase UpdatedFileCase)> UpdateCountrySelection(FileSettings fileSetting, FileCaseModel fileCaseModel);

        Task<InstructResult> GetViewLink(FileSettings fileSetting, FileInstructAllowedCase caseDetails);

        Task<InstructResult> GetViewLink(FileSettings fileSetting, int caseId);
    }

    public class FileApi : IFileApi
    {
        readonly IFileApiClient _apiClient;
        readonly IIndex<string, IFileCaseBuilder> _caseBuilders;
        readonly IDbContext _dbContext;
        readonly IIndex<string, IPostInstructionCreationTasks> _tasks;
        readonly IIndex<string, IFileCaseValidator> _validators;

        public FileApi(IFileApiClient apiClient,
                       IIndex<string, IFileCaseBuilder> caseBuilders,
                       IIndex<string, IFileCaseValidator> validators,
                       IIndex<string, IPostInstructionCreationTasks> tasks,
                       IDbContext dbContext)
        {
            _apiClient = apiClient;
            _caseBuilders = caseBuilders;
            _validators = validators;
            _tasks = tasks;
            _dbContext = dbContext;
        }

        public async Task<(InstructResult Result, FileCase UpdatedFileCase)> UpdateCountrySelection(FileSettings fileSetting, FileCaseModel fileCaseModel)
        {
            if (fileSetting == null) throw new ArgumentNullException(nameof(fileSetting));
            if (fileCaseModel == null) throw new ArgumentNullException(nameof(fileCaseModel));

            var builder = _caseBuilders[fileCaseModel.IpType];
            var validator = _validators[fileCaseModel.IpType];

            var fileCase = await _apiClient.Get<FileCase>(fileSetting.CasesApi(fileCaseModel.ParentCaseId));

            if (fileCase == null)
            {
                fileCase = await builder.Build(fileCaseModel.ParentCaseId);

                if (!validator.TryValidate(fileCase, out InstructResult invalid))
                {
                    return (invalid, fileCase);
                }

                fileCase.Countries.AddRange(fileCaseModel.CountrySelections
                                                         .Select(_ => _.ToCountry()));

                if (!validator.TryValidateCountrySelection(fileCase, fileCase.Countries, out InstructResult invalidCountrySelection))
                {
                    return (invalidCountrySelection, fileCase);
                }

                var resultFileCase = await _apiClient.Post<FileCase>(fileSetting.CasesApi(), fileCase);

                var instructResult = resultFileCase == null
                    ? InstructResult.Error(ErrorCodes.UnableToAccessFile)
                    : InstructResult.Progress(resultFileCase.Links.ByRel("wizard"));

                if (resultFileCase != null && _tasks.TryGetValue(fileCaseModel.IpType, out IPostInstructionCreationTasks tasks))
                {
                    await tasks.Perform(fileSetting, resultFileCase);
                }

                return (instructResult, resultFileCase);
            }

            var existingSelection = new List<string>(fileCase.Countries.Select(_ => _.Code));
            var existingInstructed = new List<string>();
            if (fileCase.Status == FileStatuses.Instructed)
            {
                var instructions = await _apiClient.Get<IEnumerable<Instruction>>(fileSetting.InstructionsApi(fileCaseModel.ParentCaseId));
                existingInstructed = instructions.Where(_ => _.Status != "DRAFT")
                                                    .Select(_ => _.CountryCode)
                                                    .Distinct()
                                                    .ToList();
            }

            var newCountrySelections = fileCaseModel.CountrySelections
                                         .Where(_ => !existingSelection.Contains(_.Code))
                                         .Select(_ => _.ToCountry())
                                         .ToArray();

            if (newCountrySelections.Any())
            {
                fileCase.AddCountries(newCountrySelections);
                fileCase.RemoveCountries(existingInstructed);

                if (!validator.TryValidateCountrySelection(fileCase, fileCase.Countries, out InstructResult invalidCountrySelection))
                {
                    return (invalidCountrySelection, fileCase);
                }

                await _apiClient.Put<IEnumerable<Country>>(fileSetting.UpdateCountrySelectionApi(fileCaseModel.ParentCaseId), fileCase.Countries);

                fileCase = await _apiClient.Get<FileCase>(fileSetting.CasesApi(fileCaseModel.ParentCaseId));
            }

            return (InstructResult.Progress(fileCase.Links.ByRel("wizard")), fileCase);
        }

        public async Task<InstructResult> GetViewLink(FileSettings fileSetting, FileInstructAllowedCase caseDetails)
        {
            if (fileSetting == null) throw new ArgumentNullException(nameof(fileSetting));

            string link = null;

            var fileCaseEntity = _dbContext.Set<FileCaseEntity>()
                                           .SingleOrDefault(_ => _.CaseId == caseDetails.CaseId && _.IpType == caseDetails.IpType);

            if (fileCaseEntity == null)
            {
                return InstructResult.Error(ErrorCodes.CaseNotInFile);
            }

            if (string.IsNullOrWhiteSpace(fileCaseEntity.Status) || fileCaseEntity.Status == FileStatuses.Draft)
            {
                link = await GetParentViewLink(fileSetting, caseDetails.ParentCaseId, caseDetails.CountryCode);
            }
            else if (fileCaseEntity.ParentCaseId.HasValue)
            {
                var identificationCode = fileCaseEntity.InstructionGuid.HasValue ? fileCaseEntity.InstructionGuid.ToString() : caseDetails.CountryCode;
                var instruction = await _apiClient.Get<Instruction>(fileSetting.InstructionsApi(fileCaseEntity.ParentCaseId.ToString(), identificationCode));
                link = instruction.Links.ByRel("progress");
                link = link.Replace("{countryCode}", identificationCode);
            }

            return string.IsNullOrWhiteSpace(link) ? InstructResult.Error(ErrorCodes.IncorrectFileUrl) : InstructResult.Progress(link);
        }

        public async Task<InstructResult> GetViewLink(FileSettings fileSetting, int caseId)
        {
            var link = await GetParentViewLink(fileSetting, caseId);
            return string.IsNullOrWhiteSpace(link) ? InstructResult.Error(ErrorCodes.IncorrectFileUrl) : InstructResult.Progress(link);
        }

        async Task<string> GetParentViewLink(FileSettings fileSetting, int caseId, string countryCode = null)
        {
            var fileCase = await _apiClient.Get<FileCase>(fileSetting.CasesApi(caseId.ToString()), NotFoundHandling.Throw404);

            var wizardLink = fileCase.Links.ByRel("wizard");
            if (string.IsNullOrWhiteSpace(countryCode) || !string.IsNullOrWhiteSpace(wizardLink))
            {
                return fileCase.Links.ByRel("wizard") ?? fileCase.Links.ByRel("progress");
            }

            return fileCase.Links.ByRel("progress");
        }
    }
}