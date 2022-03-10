using System;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.DmsIntegration.Component
{
    public interface ICaseFolderCriteriaResolver
    {
        Task<DmsSearchCriteria> Resolve(int caseKey, IManageSettings testSettings = null);
    }

    public class CaseFolderCriteriaResolver : ICaseFolderCriteriaResolver
    {
        readonly IDbContext _dbContext;
        readonly IDmsSettingsProvider _dmsSettingsProvider;
        readonly IDocItemRunner _docItemRunner;
        readonly ISiteControlReader _siteControlReader;

        public CaseFolderCriteriaResolver(IDbContext dbContext, IDmsSettingsProvider dmsSettingsProvider, ISiteControlReader siteControlReader, IDocItemRunner docItemRunner)
        {
            _dbContext = dbContext;
            _dmsSettingsProvider = dmsSettingsProvider;
            _siteControlReader = siteControlReader;
            _docItemRunner = docItemRunner;
        }

        public async Task<DmsSearchCriteria> Resolve(int caseKey, IManageSettings testSettings = null)
        {
            var docItemName = string.Empty;

            try
            {
                var settings = testSettings ?? await _dmsSettingsProvider.Provide();

                var nameTypes = settings.NameTypesRequired?.ToArray();

                var @case = await _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                                            .SingleAsync(_ => _.Id == caseKey);

                var criteria = new DmsSearchCriteria
                {
                    CaseKey = caseKey,
                    CaseReference = @case.Irn
                };

                docItemName = testSettings != null ? testSettings.DataItemCodes?.CaseDataItem : _siteControlReader.Read<string>(SiteControls.DMSCaseSearchDocItem);

                if (!string.IsNullOrWhiteSpace(docItemName))
                {
                    var p = DefaultDocItemParameters.ForDocItemSqlQueries(@case.Irn);
                    var transformedSearchString = _docItemRunner.Run(docItemName, p).ScalarValue<string>();
                    criteria.CaseReference = transformedSearchString;
                }

                if (!nameTypes.Any())
                {
                    var dmsNameTypes = _siteControlReader.Read<string>(SiteControls.DMSNameTypes);
                    nameTypes = dmsNameTypes?.Split(new[] {","}, StringSplitOptions.RemoveEmptyEntries) ?? new string[0];
                }

                if (nameTypes.Any())
                {
                    var dmsNameEntities = await (from cn in _dbContext.Set<CaseName>()
                                                 where cn.CaseId == caseKey && nameTypes.Contains(cn.NameType.NameTypeCode)
                                                 select new DmsNameEntity
                                                 {
                                                     NameKey = cn.NameId,
                                                     NameCode = cn.Name.NameCode,
                                                     NameType = cn.NameTypeId
                                                 }).Distinct().ToArrayAsync();

                    docItemName = testSettings != null ? testSettings.DataItemCodes?.NameDataItem : _siteControlReader.Read<string>(SiteControls.DMSNameSearchDocItem);

                    foreach (var dmsNameEntity in dmsNameEntities)
                    {
                        if (!string.IsNullOrWhiteSpace(docItemName) && !string.IsNullOrWhiteSpace(dmsNameEntity.NameCode))
                        {
                            var p = DefaultDocItemParameters.ForDocItemSqlQueries(dmsNameEntity.NameCode);
                            var transformedNameCode = _docItemRunner.Run(docItemName, p).ScalarValue<string>();
                            dmsNameEntity.NameCode = transformedNameCode;
                        }
                    }

                    criteria.CaseNameEntities.AddRange(dmsNameEntities);
                }

                return criteria;
            }
            catch (SqlException sex)
            {
                var message =
                    $"There was an error in assembling the case criterion for document lookup in the DMS, as a result of the execution of '{docItemName}'." +
                    Environment.NewLine +
                    "If 'DMS Case Search Doc Item' is configured, ensure the format of the returned value meets the Case 'Search Field' requirement.";

                throw new DmsConfigurationException(message, sex);
            }
        }
    }
}