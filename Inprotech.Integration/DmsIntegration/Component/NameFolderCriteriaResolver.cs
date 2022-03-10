using System;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.DmsIntegration.Component
{
    public interface INameFolderCriteriaResolver
    {
        Task<DmsSearchCriteria> Resolve(int nameKey, IManageSettings settings = null);
    }

    public class NameFolderCriteriaResolver : INameFolderCriteriaResolver
    {
        readonly IDocItemRunner _docItemRunner;
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;

        public NameFolderCriteriaResolver(IDbContext dbContext, ISiteControlReader siteControlReader, IDocItemRunner docItemRunner)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
            _docItemRunner = docItemRunner;
        }

        public async Task<DmsSearchCriteria> Resolve(int nameKey, IManageSettings settings = null)
        {
            var docItemName = string.Empty;

            try
            {
                var name = await _dbContext.Set<Name>().SingleAsync(_ => _.Id == nameKey);

                var criteria = new DmsSearchCriteria {NameEntity = {NameKey = nameKey, NameCode = name.NameCode}};
                
                docItemName = settings != null ? settings.DataItemCodes.NameDataItem : _siteControlReader.Read<string>(SiteControls.DMSNameSearchDocItem);

                if (!string.IsNullOrWhiteSpace(docItemName) && !string.IsNullOrWhiteSpace(criteria.NameEntity.NameCode))
                {
                    var p = DefaultDocItemParameters.ForDocItemSqlQueries(criteria.NameEntity.NameCode);
                    var transformedNameCode = _docItemRunner.Run(docItemName, p).ScalarValue<string>();
                    criteria.NameEntity.NameCode = transformedNameCode;
                }

                return criteria;
            }
            catch (SqlException sex)
            {
                var message =
                    $"There was an error in assembling the name criterion for document lookup in the DMS, as a result of the execution of '{docItemName}'." +
                    Environment.NewLine +
                    "If 'DMS Name Search Doc Item' is configured, ensure the format of the returned value matches the intended Custom Field 1 value format.";

                throw new DmsConfigurationException(message, sex);
            }
        }
    }
}