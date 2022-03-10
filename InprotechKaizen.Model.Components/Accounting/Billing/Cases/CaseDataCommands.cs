using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Cases
{
    public interface ICaseDataCommands
    {
        Task<CaseData> GetCase(int userIdentityId, string culture, int caseKey, int raisedByStaffKey);

        Task<IEnumerable<CaseData>> GetCases(int userIdentityId, string culture, int caseListKey, int raisedByStaffKey);

        Task<IEnumerable<CaseData>> GetOpenItemCases(int userIdentityId, string culture, int? entityNo = null, int? transNo = null, MergeXmlKeys mergeXmlKeys = null);
    }

    public class CaseDataCommands : ICaseDataCommands
    {
        static readonly Dictionary<string, string[]> CompatibilityFieldsMap = new()
        {
            {StoredProcedures.Billing.GetCaseDetailsFromCaseList, null},
            {StoredProcedures.Billing.GetCaseDetail, null},
            {StoredProcedures.Billing.GetBillCases, null}
        };

        readonly IDbContext _dbContext;

        public CaseDataCommands(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<CaseData>> GetOpenItemCases(int userIdentityId, string culture, int? entityNo = null, int? transNo = null, MergeXmlKeys mergeXmlKeys = null)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetBillCases,
                                                                        new Parameters
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnItemEntityNo", entityNo},
                                                                            {"@pnItemTransNo", transNo},
                                                                            {"@psMergeXMLKeys", mergeXmlKeys?.ToString()}
                                                                        });

            var caseList = new List<CaseData>();

            using var dr = await command.ExecuteReaderAsync();

            while (await dr.ReadAsync())
            {
                CompatibilityFieldsMap[StoredProcedures.Billing.GetBillCases] ??= Enumerable.Range(0, dr.FieldCount)
                                                                                            .Select(i => dr.GetName(i))
                                                                                            .ToArray();

                var fields = CompatibilityFieldsMap[StoredProcedures.Billing.GetBillCases];

                caseList.Add(BuildCaseDataFromRawData(dr, fields));
            }

            if (await dr.NextResultAsync())
            {
                while (dr.Read())
                {
                    var caseKey = (int) dr["CaseKey"];
                    var caseData = caseList.First(_ => _.CaseId == caseKey);
                    caseData.UnpostedTimeList.Add(BuildCaseUnpostedTimeFromRaw(dr));
                }
            }

            return caseList;
        }

        public async Task<CaseData> GetCase(int userIdentityId, string culture, int caseKey, int raisedByStaffKey)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetCaseDetail,
                                                                        new Parameters
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnCaseKey", caseKey},
                                                                            {"@pnRaisedByStaffKey", raisedByStaffKey}
                                                                        });

            using var dr = await command.ExecuteReaderAsync();

            var caseData = new CaseData();
            if (await dr.ReadAsync())
            {
                CompatibilityFieldsMap[StoredProcedures.Billing.GetCaseDetail] ??= Enumerable.Range(0, dr.FieldCount)
                                                                                             .Select(i => dr.GetName(i))
                                                                                             .ToArray();

                var fields = CompatibilityFieldsMap[StoredProcedures.Billing.GetCaseDetail];

                caseData = BuildCaseDataFromRawData(dr, fields);
            }

            if (await dr.NextResultAsync())
            {
                while (await dr.ReadAsync()) caseData.UnpostedTimeList.Add(BuildCaseUnpostedTimeFromRaw(dr));
            }

            return caseData;
        }

        public async Task<IEnumerable<CaseData>> GetCases(int userIdentityId, string culture, int caseListKey, int raisedByStaffKey)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetCaseDetailsFromCaseList,
                                                                        new Parameters
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnCaseListKey", caseListKey},
                                                                            {"@pnRaisedByStaffKey", raisedByStaffKey}
                                                                        });

            using var dr = await command.ExecuteReaderAsync();

            var caseData = new List<CaseData>();
            while (await dr.ReadAsync())
            {
                CompatibilityFieldsMap[StoredProcedures.Billing.GetCaseDetailsFromCaseList] ??= Enumerable.Range(0, dr.FieldCount)
                                                                                                          .Select(i => dr.GetName(i))
                                                                                                          .ToArray();

                var fields = CompatibilityFieldsMap[StoredProcedures.Billing.GetCaseDetailsFromCaseList];

                caseData.Add(BuildCaseDataFromRawData(dr,
                                                      fields,
                                                      cd =>
                                                      {
                                                          cd.CaseListId = caseListKey;
                                                          return cd;
                                                      }));
            }

            return caseData;
        }

        static CaseData BuildCaseDataFromRawData(IDataRecord dr, string[] fields, Func<CaseData, CaseData> modifier = null)
        {
            var caseData = new CaseData
            {
                CaseId = dr.GetField<int>("CaseKey"),
                CaseReference = dr.GetField<string>("IRN"),
                Title = dr.GetField<string>("Title"),
                CaseTypeCode = dr.GetField<string>("CaseTypeCode"),
                CaseTypeDescription = dr.GetField<string>("CaseTypeDescription"),
                CountryCode = dr.GetField<string>("CountryCode"),
                PropertyType = dr.GetField<string>("PropertyType"),
                TotalCredits = dr.GetField<decimal?>("TotalCredits"),
                OpenAction = dr.GetField<string>("OpenAction"),
                IsMainCase = dr.GetField<int>("IsMainCase") == 1,
                LanguageId = dr.GetField<int?>("LanguageKey"),
                LanguageDescription = dr.GetField<string>("LanguageDescription"),
                BillSourceCountryCode = dr.GetField<string>("BillSourceCountryCode"),
                TaxCode = dr.GetField<string>("TaxCode"),
                TaxDescription = dr.GetField<string>("TaxDescription"),
                CaseProfitCentre = dr.GetField<string>("ProfitCentreCode"),
                TaxRate = dr.GetField<decimal?>("TaxRate"),
                IsMultiDebtorCase = dr.GetField<bool>("IsMultiDebtorCase"),
                OfficeEntityId = fields.Contains("OfficeEntity")
                    ? dr.GetField<int?>("OfficeEntity")
                    : null
            };

            var itemTransNo = dr.GetField<int?>("ItemTransNo");
            if (itemTransNo != null)
            {
                caseData.ItemTransNo = itemTransNo.Value;
            }

            static CaseData EmptyFunc(CaseData cd)
            {
                return cd;
            }

            return (modifier ?? EmptyFunc)(caseData);
        }

        static CaseUnpostedTime BuildCaseUnpostedTimeFromRaw(IDataRecord dr)
        {
            var unpostedTime = new CaseUnpostedTime();

            if (!dr.IsDBNull(dr.GetOrdinal("NameKey")))
            {
                unpostedTime.NameId = (int) dr["NameKey"];
            }

            unpostedTime.Name = dr.GetField<string>("Name");

            if (!dr.IsDBNull(dr.GetOrdinal("StartTime")))
            {
                unpostedTime.StartTime = (DateTime) dr["StartTime"];
            }

            if (!dr.IsDBNull(dr.GetOrdinal("TotalTime")))
            {
                unpostedTime.TotalTime = (DateTime) dr["TotalTime"];
            }

            if (!dr.IsDBNull(dr.GetOrdinal("TimeValue")))
            {
                unpostedTime.TimeValue = (decimal) dr["TimeValue"];
            }

            return unpostedTime;
        }
    }
}