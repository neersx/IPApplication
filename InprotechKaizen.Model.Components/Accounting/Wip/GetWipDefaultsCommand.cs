using System;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public interface IGetWipDefaultsCommand
    {
        Task<WipDefaults> GetWipDefaults(int userIdentityId, string culture, WipTemplateFilterCriteria filterCriteria, int? caseKey, string activityKey = null);
    }

    public class GetWipDefaultsCommand : IGetWipDefaultsCommand
    {
        readonly IDbContext _dbContext;

        public GetWipDefaultsCommand(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<WipDefaults> GetWipDefaults(int userIdentityId, string culture, WipTemplateFilterCriteria filterCriteria, int? caseKey, string activityKey = null)
        {
            var inputParameters = new Parameters
                                  {
                                      {"@pnUserIdentityId", userIdentityId},
                                      {"@psCulture", culture},
                                      {"@pnCaseKey", caseKey},
                                      {"@psOldWIPTemplateKey", activityKey},
                                      {"@pbDefaultWIPTemplate", true},
                                      {"@ptWIPTemplateFilter", filterCriteria.Build().ToString()}
                                  };

            var wipInformation = new WipDefaults();

            using var command = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.WipManagement.GetWipDefault, inputParameters);
            using var dr = await command.ExecuteReaderAsync();
            if (!dr.Read()) return wipInformation;

            if (!dr.IsDBNull(dr.GetOrdinal("StaffKey")))
            {
                wipInformation.StaffKey = Convert.ToInt32(dr["StaffKey"]);
                wipInformation.StaffName = dr["StaffName"].ToString();
                wipInformation.StaffCode = dr["StaffCode"].ToString();
                wipInformation.ProfitCentreKey = dr["ProfitCentreCode"].ToString();
                wipInformation.ProfitCentreDescription = dr["ProfitCentre"].ToString();
            }

            if (!dr.IsDBNull(dr.GetOrdinal("NameKey")))
            {
                wipInformation.NameKey = Convert.ToInt32(dr["NameKey"]);
                wipInformation.Name = dr["Name"].ToString();
                wipInformation.NameCode = dr["NameCode"].ToString();
            }

            if (!dr.IsDBNull(dr.GetOrdinal("CaseKey")))
            {
                wipInformation.CaseKey = Convert.ToInt32(dr["CaseKey"]);
                wipInformation.CaseReference = dr["CaseReference"].ToString();
            }

            if (!dr.IsDBNull(dr.GetOrdinal("AssociateKey")))
            {
                wipInformation.AssociateKey = Convert.ToInt32(dr["AssociateKey"]);
                wipInformation.AssociateName = dr["AssociateName"].ToString();
                wipInformation.AssociateCode = dr["AssociateCode"].ToString();
            }

            wipInformation.LocalCurrencyCode = dr["LocalCurrencyCode"].ToString();
            wipInformation.LocalDecimalPlaces = !dr.IsDBNull(dr.GetOrdinal("LocalDecimalPlaces"))
                ? Convert.ToInt32(dr["LocalDecimalPlaces"])
                : 2;

            if (!dr.IsDBNull(dr.GetOrdinal("WIPTemplateKey")))
            {
                wipInformation.WIPTemplateKey = dr["WIPTemplateKey"].ToString();
                wipInformation.WIPTemplateDescription = dr["WIPTemplateDescription"].ToString();
            }

            if (!dr.IsDBNull(dr.GetOrdinal("SeparateMarginFlag")))
                wipInformation.SeparateMarginFlag = Convert.ToBoolean(dr["SeparateMarginFlag"]);
 
            if (!dr.IsDBNull(dr.GetOrdinal("NarrativeKey")))
            {
                wipInformation.NarrativeKey = Convert.ToInt32(dr["NarrativeKey"]);
                wipInformation.NarrativeCode = dr["NarrativeCode"].ToString();
                wipInformation.NarrativeTitle = dr["NarrativeTitle"].ToString();
                wipInformation.NarrativeText = dr["NarrativeText"].ToString();
            }
            return wipInformation;
        }
    }
}