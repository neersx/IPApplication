using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    public interface IFileIntegration
    {
        Task<FileInstruct> InstructAllowedFor(int caseId, FileSettings setting);

        Task<FiledCases> FiledChildCases(int caseId, FileSettings setting);

        Task<FileInstructAllowed> InstructAllowedChildCases(int parentId, FileSettings setting);

        Task<InstructResult> InstructFiling(int caseId);

        Task<InstructResult> InstructFilings(int parentCaseId, string countryCodes);

        Task<InstructResult> ViewFiling(int caseId);
    }

    public class FileIntegration : IFileIntegration
    {
        readonly IFileInstructAllowedCases _allowedCases;
        readonly IMultipleClassApplicationCountries _multipleClassApplicationCountries;
        readonly IDbContext _dbContext;

        readonly IFileAgents _fileAgents;
        readonly IFileApi _fileApi;
        readonly IFileIntegrationStatus _fileIntegrationStatus;
        readonly IFileSettingsResolver _fileSettingsResolver;

        public FileIntegration(IFileSettingsResolver fileSettingsResolver,
                               IFileInstructAllowedCases allowedCases,
                               IMultipleClassApplicationCountries multipleClassApplicationCountries,
                               IFileApi fileApi,
                               IFileAgents fileAgents,
                               IFileIntegrationStatus fileIntegrationStatus,
                               IDbContext dbContext
        )
        {
            _fileSettingsResolver = fileSettingsResolver;
            _allowedCases = allowedCases;
            _multipleClassApplicationCountries = multipleClassApplicationCountries;
            _fileApi = fileApi;
            _fileAgents = fileAgents;
            _fileIntegrationStatus = fileIntegrationStatus;
            _dbContext = dbContext;
        }

        public async Task<FileInstruct> InstructAllowedFor(int caseId, FileSettings setting)
        {
            if (setting == null) throw new ArgumentNullException(nameof(setting));

            var allowedJurisdictions = _fileAgents.FilesInJuridictions().ToArray();

            var caseDetails = await _allowedCases.Retrieve(setting)
                                                 .Where(_ => _.CaseId == caseId || _.ParentCaseId == caseId)
                                                 .Where(_ => _.Filed || allowedJurisdictions.Contains(_.CountryCode))
                                                 .ToArrayAsync();

            var childCases = caseDetails.Where(_ => _.ParentCaseId == caseId).ToArray();
            var filedPct = childCases.Any(_ => _.Filed && _.IpType == IpTypes.PatentPostPct);
            var instructAllowed = caseDetails.Where(_ => _.CaseId == caseId).ToArray();

            if (instructAllowed.Length == 1 && !filedPct)
            {
                var directCase = instructAllowed.Single();
                return new FileInstruct
                {
                    CanInstruct = true,
                    CanView = directCase.Filed,
                    ParentCaseId = directCase.ParentCaseId,
                    CountryCode = directCase.CountryCode
                };
            }

            if (childCases.Any())
            {
                return new FileInstruct
                {
                    CanInstruct = false,
                    CanView = childCases.Any(_ => _.Filed),
                    ParentCaseId = caseId
                };
            }

            var e = instructAllowed.Earliest();
            return e != null
                ? new FileInstruct
                {
                    CanInstruct = true,
                    CanView = e.Filed,
                    ParentCaseId = e.ParentCaseId,
                    CountryCode = e.CountryCode
                }
                : new FileInstruct();
        }

        public async Task<FiledCases> FiledChildCases(int caseId, FileSettings setting)
        {
            if (setting == null) throw new ArgumentNullException(nameof(setting));

            var allowedCases = await _allowedCases.Retrieve(setting)
                                                  .Where(_ => _.ParentCaseId == caseId)
                                                  .ToArrayAsync();

            if (allowedCases.Any(_ => _.ParentCaseId == caseId))
            {
                return new FiledCases
                {
                    ParentCaseId = caseId,
                    FiledCaseIds = allowedCases
                        .Where(_ => _.ParentCaseId == caseId && _.Filed)
                        .Select(_ => _.CaseId)
                };
            }

            return new FiledCases();
        }

        public async Task<FileInstructAllowed> InstructAllowedChildCases(int parentId, FileSettings setting)
        {
            if (setting == null) throw new ArgumentNullException(nameof(setting));

            var allowedJurisdictions = _fileAgents.FilesInJuridictions().ToArray();

            var allowedCases = await _allowedCases.Retrieve(setting)
                                                  .Where(r => !r.Filed && r.ParentCaseId == parentId)
                                                  .Where(_ => allowedJurisdictions.Contains(_.CountryCode))
                                                  .ToArrayAsync();

            if (!allowedCases.Any())
            {
                return new FileInstructAllowed();
            }

            return new FileInstructAllowed
            {
                IsEnabled = true,
                ParentCaseId = parentId,
                CaseIds = allowedCases.Select(_ => _.CaseId)
            };
        }

        public async Task<InstructResult> ViewFiling(int caseId)
        {
            var fileSetting = _fileSettingsResolver.Resolve();

            if (!fileSetting.IsEnabled) return InstructResult.Error(ErrorCodes.RequirementsUnmet);

            var allowedJurisdictions = _fileAgents.FilesInJuridictions().ToArray();

            var caseDetails = await _allowedCases.Retrieve(fileSetting)
                                                 .Where(_ => _.CaseId == caseId || _.ParentCaseId == caseId)
                                                 .Where(_ => _.Filed || allowedJurisdictions.Contains(_.CountryCode))
                                                 .ToArrayAsync();

            var countryCases = caseDetails.Where(_ => _.CaseId == caseId)
                                          .ToArray();

            if (countryCases.Any(_ => _.Filed))
            {
                var filed = countryCases.FirstOrDefault(_ => _.Filed && _.IpType == IpTypes.PatentPostPct)
                            ?? countryCases.First(_ => _.Filed);

                return await _fileApi.GetViewLink(fileSetting, filed);
            }

            if (caseDetails.Any(_ => _.ParentCaseId == caseId && _.IpType == IpTypes.PatentPostPct))
            {
                return await _fileApi.GetViewLink(fileSetting, caseId);
            }

            if (countryCases.Length == 1)
            {
                return await _fileApi.GetViewLink(fileSetting, countryCases.Single());
            }

            if (caseDetails.Any(_ => _.ParentCaseId == caseId))
            {
                return await _fileApi.GetViewLink(fileSetting, caseId);
            }

            return InstructResult.Error(ErrorCodes.CaseNotInFile);
        }

        public async Task<InstructResult> InstructFiling(int caseId)
        {
            var fileSetting = _fileSettingsResolver.Resolve();

            if (!fileSetting.IsEnabled) return InstructResult.Error(ErrorCodes.RequirementsUnmet);
            var cases = _dbContext.Set<InprotechKaizen.Model.Cases.Case>();

            var allowedCases = await (from a in _allowedCases.Retrieve(fileSetting)
                                      join c in cases on a.CaseId equals c.Id
                                      where caseId == a.CaseId
                                      select new FileInstructAllowedCaseDetail
                                      {
                                          IpType = a.IpType,
                                          ParentCaseId = a.ParentCaseId,
                                          CaseId = a.CaseId,
                                          CountryCode = a.CountryCode,
                                          Filed = a.Filed,
                                          EarliestPriority = a.EarliestPriority,
                                          Irn = c.Irn,
                                          LocalClasses = c.LocalClasses
                                      }).ToArrayAsync();

            var allowedCase = allowedCases.Earliest();

            if (allowedCase == null) return InstructResult.Error(ErrorCodes.InvalidCaseForFiling);
            if (allowedCase.Filed) return InstructResult.Error(ErrorCodes.CaseAlreadyFiled);
            
            var multiClass = _multipleClassApplicationCountries.Resolve().ToArray();

            var sameCountry = await (from a in _allowedCases.Retrieve(fileSetting)
                                     where a.IpType == allowedCase.IpType && a.ParentCaseId == allowedCase.ParentCaseId && a.CountryCode == allowedCase.CountryCode
                                     join c in cases on a.CaseId equals c.Id
                                     select new FileInstructAllowedCaseDetail
                                     {
                                         IpType = a.IpType,
                                         ParentCaseId = a.ParentCaseId,
                                         CaseId = a.CaseId,
                                         CountryCode = a.CountryCode,
                                         Filed = a.Filed,
                                         EarliestPriority = a.EarliestPriority,
                                         Irn = c.Irn,
                                         LocalClasses = c.LocalClasses
                                     }).ToArrayAsync();

            var fileCaseModel = new FileCaseModel
            {
                ParentCaseId = $"{allowedCase.ParentCaseId}",
                IpType = allowedCase.IpType
            };

            foreach (var @case in sameCountry)
            {
                if (!_fileAgents.TryGetAgentId(@case.CaseId, out string agentId))
                {
                    return InstructResult.Error(ErrorCodes.IneligibleFileAgent);
                }

                var localClass = @case.LocalClasses;
                if (multiClass.Contains(@case.CountryCode) || fileCaseModel.IpType != IpTypes.TrademarkDirect)
                    localClass = null;

                fileCaseModel.CountrySelections.Add(new CountrySelection
                {
                    Irn = @case.Irn,
                    CaseId = @case.CaseId,
                    Code = @case.CountryCode,
                    Class = localClass,
                    Agent = agentId
                });
            }

            var r = await _fileApi.UpdateCountrySelection(fileSetting, fileCaseModel);

            if (!string.IsNullOrWhiteSpace(r.Result.ErrorCode)) return r.Result;

            await _fileIntegrationStatus.Update(fileSetting, fileCaseModel, r.UpdatedFileCase);

            return r.Result;
        }

        public async Task<InstructResult> InstructFilings(int parentCaseId, string countryCodesCsv)
        {
            if (countryCodesCsv == null) throw new ArgumentNullException(nameof(countryCodesCsv));

            var fileSetting = _fileSettingsResolver.Resolve();

            if (!fileSetting.IsEnabled) return InstructResult.Error(ErrorCodes.RequirementsUnmet);

            var countryCodes = countryCodesCsv.Split(new[] {','}, StringSplitOptions.RemoveEmptyEntries)
                                              .Select(_ => _.Trim())
                                              .ToArray();

            var cases = _dbContext.Set<InprotechKaizen.Model.Cases.Case>();

            var allowedCases = await (from a in _allowedCases.Retrieve(fileSetting)
                                      join c in cases on a.CaseId equals c.Id
                                      where parentCaseId == a.ParentCaseId && countryCodes.Contains(a.CountryCode)
                                      select new FileInstructAllowedCaseDetail
                                      {
                                          IpType = a.IpType,
                                          ParentCaseId = a.ParentCaseId,
                                          CaseId = a.CaseId,
                                          CountryCode = a.CountryCode,
                                          Filed = a.Filed,
                                          EarliestPriority = a.EarliestPriority,
                                          Irn = c.Irn,
                                          LocalClasses = c.LocalClasses
                                      }).ToArrayAsync();

            if (!allowedCases.Any()) return InstructResult.Error(ErrorCodes.InvalidCaseForFiling);
            if (allowedCases.All(_ => _.Filed)) return InstructResult.Error(ErrorCodes.CaseAlreadyFiled);

            var multiClass = _multipleClassApplicationCountries.Resolve().ToArray();

            var fileCaseModel = new FileCaseModel
            {
                ParentCaseId = $"{parentCaseId}",
                IpType = allowedCases.First().IpType
            };

            foreach (var @case in allowedCases.Where(_ => !_.Filed))
            {
                if (!_fileAgents.TryGetAgentId(@case.CaseId, out string agentId))
                {
                    continue;
                }

                var localClass = @case.LocalClasses;
                if (multiClass.Contains(@case.CountryCode) || fileCaseModel.IpType != IpTypes.TrademarkDirect)
                    localClass = null;

                fileCaseModel.CountrySelections.Add(new CountrySelection
                {
                    Irn = @case.Irn,
                    CaseId = @case.CaseId,
                    Code = @case.CountryCode,
                    Class = localClass,
                    Agent = agentId
                });
            }

            if (!fileCaseModel.CountrySelections.Any()) return InstructResult.Error(ErrorCodes.IneligibleFileAgent);

            var r = await _fileApi.UpdateCountrySelection(fileSetting, fileCaseModel);

            if (!string.IsNullOrWhiteSpace(r.Result.ErrorCode)) return r.Result;

            await _fileIntegrationStatus.Update(fileSetting, fileCaseModel, r.UpdatedFileCase);

            return r.Result;
        }
    }
}