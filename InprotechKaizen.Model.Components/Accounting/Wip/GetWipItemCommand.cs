using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public interface IGetWipItemCommand
    {
        Task<WipItem> GetWipItem(int userIdentityId, string culture, int entityKey, int transKey, int wipSeqNo);
    }

    public class GetWipItemCommand : IGetWipItemCommand
    {
        readonly IDbContext _dbContext;
        
        public GetWipItemCommand(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<WipItem> GetWipItem(int userIdentityId, string culture, int entityKey, int transKey, int wipSeqNo)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.WipManagement.GetWipItem,
                                                                        new Dictionary<string, object>
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnEntityKey", entityKey},
                                                                            {"@pnTransKey", transKey},
                                                                            {"@pnWIPSeqKey", wipSeqNo}
                                                                        });
            using var dr = await command.ExecuteReaderAsync();
            var returnWipItem = new WipItem();
            if (dr.Read())
            {
                return TranslateGetWipItemDbResult(dr);
            }

            return returnWipItem;
        }

        static WipItem TranslateGetWipItemDbResult(IDataReader dr)
        {
            var returnItem = new WipItem
            {
                EntityKey = Convert.ToInt32(dr["EntityKey"]),
                Entity = dr["Entity"].ToString(),
                ResponsibleNameKey = Convert.ToInt32(dr["ResponsibleNameKey"]),
                ResponsibleNameCode = dr["ResponsibleNameCode"].ToString(),
                ResponsibleName = dr["ResponsibleName"].ToString(),
                TransKey = Convert.ToInt32(dr["TransKey"]),
                WIPSeqKey = Convert.ToInt16(dr["WIPSeqKey"]),
                TransDate = Convert.ToDateTime(dr["TransDate"]),
                WIPCode = dr["WIPCode"].ToString(),
                WIPDescription = dr["WIPDescription"].ToString(),
                WipCategoryCode = dr["WIPCategoryKey"].ToString()
            };

            if (!dr.IsDBNull(dr.GetOrdinal("RequestedByStaffKey")))
            {
                returnItem.RequestedByStaffKey = Convert.ToInt32(dr["RequestedByStaffKey"]);
                returnItem.RequestedByStaffCode = dr["RequestedByStaffCode"].ToString();
                returnItem.RequestedByStaffName = dr["RequestedByStaffName"].ToString();
            }

            if (!dr.IsDBNull(dr.GetOrdinal("CaseKey")))
            {
                returnItem.CaseKey = Convert.ToInt32(dr["CaseKey"]);
                returnItem.IRN = dr["IRN"].ToString();
                returnItem.CaseReference = dr["IRN"].ToString();
            }

            if (!dr.IsDBNull(dr.GetOrdinal("AcctClientKey")))
            {
                returnItem.AcctClientKey = Convert.ToInt32(dr["AcctClientKey"]);
                returnItem.AcctClientName = dr["AcctClientName"].ToString();
                returnItem.AcctClientCode = dr["AcctClientCode"].ToString();
            }

            if (!dr.IsDBNull(dr.GetOrdinal("StaffKey")))
            {
                returnItem.StaffKey = Convert.ToInt32(dr["StaffKey"]);
                returnItem.StaffName = dr["StaffName"].ToString();
                returnItem.StaffCode = dr["StaffCode"].ToString();
            }

            if (!dr.IsDBNull(dr.GetOrdinal("LocalCurrency")))
            {
                returnItem.LocalCurrency = dr["LocalCurrency"].ToString()
                                                              .NullIfEmptyOrWhitespace();
                if (!dr.IsDBNull(dr.GetOrdinal("LocalDecimalPlaces")))
                {
                    returnItem.LocalDeciamlPlaces = Convert.ToInt32(dr["LocalDecimalPlaces"]);
                }
            }

            if (!dr.IsDBNull(dr.GetOrdinal("ForeignCurrency")))
            {
                returnItem.ForeignCurrency = dr["ForeignCurrency"].ToString()
                                                                  .NullIfEmptyOrWhitespace();
                returnItem.ForeignValue = Convert.ToDecimal(dr["ForeignValue"]);
                returnItem.ForeignBalance = Convert.ToDecimal(dr["ForeignBalance"]);
                returnItem.ExchRate = Convert.ToDecimal(dr["ExchRate"]);

                if (!dr.IsDBNull(dr.GetOrdinal("ForeignDecimalPlaces")))
                {
                    returnItem.ForeignDecimalPlaces = Convert.ToInt32(dr["ForeignDecimalPlaces"]);
                }
            }

            returnItem.LocalValue = Convert.ToDecimal(dr["LocalValue"]);
            returnItem.Balance = Convert.ToDecimal(dr["Balance"]);

            if (!dr.IsDBNull(dr.GetOrdinal("NarrativeKey")))
            {
                returnItem.NarrativeKey = Convert.ToInt32(dr["NarrativeKey"]);
                returnItem.NarrativeCode = dr["NarrativeCode"].ToString();
                returnItem.NarrativeTitle = dr["NarrativeTitle"].ToString();
            }

            returnItem.DebitNoteText = dr["DebitNoteText"].ToString();

            if (!dr.IsDBNull(dr.GetOrdinal("ProductCodeKey")))
            {
                returnItem.ProductCode = Convert.ToInt32(dr["ProductCodeKey"]);
                returnItem.ProductCodeDescription = dr["ProductCodeDescription"].ToString();
            }
            
            if (!dr.IsDBNull(dr.GetOrdinal("ProfitCentreCode")))
            {
                returnItem.EmpProfitCentre = dr["ProfitCentreCode"].ToString();
                returnItem.EmpProfitCentreDescription = dr["ProfitCentre"].ToString();
            }

            if (!dr.IsDBNull(dr.GetOrdinal("WipProfitCentreSource")))
            {
                returnItem.WipProfitCentreSource = Convert.ToInt32(dr["WipProfitCentreSource"]);
            }

            returnItem.DebitNoteText = dr["DebitNoteText"].ToString();

            if (!dr.IsDBNull(dr.GetOrdinal("LogDateTimeStamp")))
            {
                returnItem.LogDateTimeStamp = (DateTime) dr["LogDateTimeStamp"];
            }

            return returnItem;
        }
    }
}