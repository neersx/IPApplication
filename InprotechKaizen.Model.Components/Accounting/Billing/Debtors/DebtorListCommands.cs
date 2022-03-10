using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Notifications.Validation;
using InprotechKaizen.Model.Components.System.Compatibility;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Debtors
{
    public interface IDebtorListCommands
    {
        Task<(IEnumerable<DebtorData> Debtors, IEnumerable<ApplicationAlert> Alerts)> RetrieveDebtorDetails(int userIdentityId, string culture, int? entityId, int? debtorNameId, DateTime? billDate, int? caseId, bool useRenewalDebtor, bool? useSendBillsTo, string action, int? raisedByStaffId);

        Task<(IEnumerable<DebtorData> Debtors, IEnumerable<ApplicationAlert> Alerts)> RetrieveBillDebtors(int userIdentityId, string culture, int entityId, int transactionId, int? raisedByStaffId);

        Task<(IEnumerable<DebtorData> Debtors, IEnumerable<ApplicationAlert> Alerts)> RetrieveDebtorsFromCases(int userIdentityId, string culture, bool useRenewalDebtor, string action, int? caseListId = null, int[] caseIds = null, int? caseId = null);

        Task<DebtorCopiesTo> GetCopiesToContactDetails(int userIdentityId, string culture, int debtorNameId, int copyToNameId);

        Task<IEnumerable<DebtorCopiesTo>> GetCopiesTo(int userIdentityId, string culture, 
                                                      int itemEntityId, int itemTransactionId, int? debtorNameId = null, int? caseId = null, bool useRenewalDebtor = false);
    }

    public class DebtorListCommands : IDebtorListCommands
    {
        readonly IApplicationAlerts _applicationAlerts;
        readonly IStoredProcedureParameterHandler _compatibleParameterHandler;
        readonly IDbContext _dbContext;

        static readonly Dictionary<string, string[]> CompatibilityFieldsMap = new()
        {
            {StoredProcedures.Billing.GetDebtorsFromCaseList, null},
            {StoredProcedures.Billing.GetDebtorDetails, null},
            {StoredProcedures.Billing.GetBillDebtors, null}
        };

        public DebtorListCommands(IDbContext dbContext, IApplicationAlerts applicationAlerts, IStoredProcedureParameterHandler compatibleParameterHandler)
        {
            _dbContext = dbContext;
            _applicationAlerts = applicationAlerts;
            _compatibleParameterHandler = compatibleParameterHandler;
        }

        public async Task<(IEnumerable<DebtorData> Debtors, IEnumerable<ApplicationAlert> Alerts)> RetrieveDebtorDetails(int userIdentityId, string culture, int? entityId, int? debtorNameId, DateTime? billDate, int? caseId, bool useRenewalDebtor, bool? useSendBillsTo, string action, int? raisedByStaffId)
        {
            // If DebtorKey is passed in, only expect 1 result, otherwise, as many rows as there are as debtors in the Case, case is not null.
            // when called with debtor null, send bills to should be true.

            return await ExecuteAsync(StoredProcedures.Billing.GetDebtorDetails,
                                      new Parameters
                                      {
                                          {"@pnUserIdentityId", userIdentityId},
                                          {"@psCulture", culture},
                                          {"@pnEntityKey", entityId},
                                          {"@pnDebtorKey", debtorNameId},
                                          {"@pdtTransDate", billDate},
                                          {"@pnCaseKey", caseId},
                                          {"@pbUseRenewalDebtor", useRenewalDebtor},
                                          {"@pbUseSendBillsTo", useSendBillsTo},
                                          {"@psAction", action},
                                          {"@pnRaisedByStaffKey", raisedByStaffId}
                                      });
        }

        public async Task<(IEnumerable<DebtorData> Debtors, IEnumerable<ApplicationAlert> Alerts)> RetrieveBillDebtors(int userIdentityId, string culture, int entityId, int transactionId, int? raisedByStaffId)
        {
            return await ExecuteAsync(StoredProcedures.Billing.GetBillDebtors,
                                      new Parameters
                                      {
                                          {"@pnUserIdentityId", userIdentityId},
                                          {"@psCulture", culture},
                                          {"@pnItemEntityNo", entityId},
                                          {"@pnItemTransNo", transactionId},
                                          {"@pnRaisedByStaffKey", raisedByStaffId}
                                      });
        }

        public async Task<(IEnumerable<DebtorData> Debtors, IEnumerable<ApplicationAlert> Alerts)> RetrieveDebtorsFromCases(int userIdentityId, string culture, bool useRenewalDebtor, string action, int? caseListId = null, int[] caseIds = null, int? caseId = null)
        {
            var csvCaseIds = caseIds != null && caseIds.Length > 1 ? string.Join(",", caseIds) : null;

            return await ExecuteAsync(StoredProcedures.Billing.GetDebtorsFromCaseList,
                                      new Parameters
                                      {
                                          {"@pnUserIdentityId", userIdentityId},
                                          {"@psCulture", culture},
                                          {"@pnCaseKey", caseId},
                                          {"@pnCaseListKey", caseListId},
                                          {"@psCaseKeyCSVList", csvCaseIds},
                                          {"@pbUseRenewalDebtor", useRenewalDebtor},
                                          {"@psAction", action}
                                      });
        }

        public async Task<DebtorCopiesTo> GetCopiesToContactDetails(int userIdentityId, string culture, int debtorNameId, int copyToNameId)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetCopyToContactDetails,
                                                                        new Dictionary<string, object>
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnCopyToKey", copyToNameId}
                                                                        });
            using var dr = await command.ExecuteReaderAsync();

            if (await dr.ReadAsync())
            {
                return BuildCopiesToFromRawData(debtorNameId, dr);
            }

            return new DebtorCopiesTo();
        }

        public async Task<IEnumerable<DebtorCopiesTo>> GetCopiesTo(int userIdentityId, string culture, 
                                                                   int itemEntityId, int itemTransactionId, int? debtorNameId = null, int? caseId = null, bool useRenewalDebtor = false)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetCopyToNames,
                                                                        new Dictionary<string, object>
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnEntityKey", itemEntityId},
                                                                            {"@pnTransKey", itemTransactionId},
                                                                            {"@pnDebtorKey", debtorNameId},
                                                                            {"@pnCaseKey", caseId},
                                                                            {"@pbUseRenewalDebtor", useRenewalDebtor}
                                                                        });

            using var dr = await command.ExecuteReaderAsync();

            var copies = new List<DebtorCopiesTo>();

            while (await dr.ReadAsync())
            {
                copies.Add(BuildCopiesToFromRawData(debtorNameId, dr));
            }

            return copies.Distinct();
        }

        async Task<(IEnumerable<DebtorData> Debtors, IEnumerable<ApplicationAlert> Alerts)> ExecuteAsync(string procedureName, IDictionary<string, object> parameters)
        {
            try
            {
                _compatibleParameterHandler.Handle(procedureName, parameters);
                
                using var command = _dbContext.CreateStoredProcedureCommand(procedureName, parameters);

                using var dr = await command.ExecuteReaderAsync();

                var debtors = new List<DebtorData>();
                var debtorCopiesTos = new List<DebtorCopiesTo>();
                var debtorDiscounts = new List<DebtorDiscount>();
                var debtorWarnings = new List<DebtorWarning>();
                var debtorReferences = new List<DebtorReference>();

                // common result sets from biw_GetBillDetails, biw_GetDebtorDetails, biw_GetDebtorsFromCaseList
                while (await dr.ReadAsync())
                {
                    CompatibilityFieldsMap[procedureName] ??= Enumerable.Range(0, dr.FieldCount)
                                                                        .Select(i => dr.GetName(i))
                                                                        .ToArray();

                    var fields = CompatibilityFieldsMap[procedureName];
                    debtors.Add(BuildDebtorListFromRawData(dr, fields));
                }

                // result sets from biw_GetBillDetails, biw_GetDebtorDetails
                if (await dr.NextResultAsync())
                {
                    while (await dr.ReadAsync())
                        debtorCopiesTos.Add(BuildCopiesToFromRawData(debtors.First().NameId, dr));
                }

                // result sets from biw_GetBillDetails, biw_GetDebtorDetails
                if (await dr.NextResultAsync())
                {
                    while (await dr.ReadAsync())
                        debtorDiscounts.Add(BuildDebtorDiscountFromRawData(dr));
                }

                // result sets from biw_GetBillDetails, biw_GetDebtorDetails
                if (await dr.NextResultAsync())
                {
                    while (await dr.ReadAsync())
                        debtorWarnings.Add(BuildDebtorWarningsFromRawData(dr));
                }

                // result set from biw_GetBillDebtors
                if (await dr.NextResultAsync())
                {
                    while (await dr.ReadAsync())
                        debtorReferences.Add(BuildDebtorReferenceFromRawData(dr));
                }

                foreach (var debtor in debtors)
                {
                    debtor.CopiesTos.AddRange(debtorCopiesTos.Where(n => n.DebtorNameId == debtor.NameId));

                    debtor.Discounts.AddRange(debtorDiscounts.Where(n => n.NameId == debtor.NameId));

                    debtor.Warnings = debtorWarnings.Where(n => n.NameId == debtor.NameId).ToList();

                    debtor.References = debtorReferences.Where(r => r.DebtorNameId == debtor.NameId).ToList();
                }

                return (debtors, Enumerable.Empty<ApplicationAlert>());
            }
            catch (SqlException ex)
            {
                /*
                 * Could return below alerts
                 * biw_GetDebtorDetails AC15: 'Debtor could not be determined from case.'
                 * biw_PopulateDebtorDetails AC154: 'The Tax Code specified in the ''Tax Code for EU billing'' site control is invalid. Contact your System Administrator to get the site control updated.'            
                 */

                if (!_applicationAlerts.TryParse(ex.Message, out var alerts))
                {
                    throw;
                }

                return (Enumerable.Empty<DebtorData>(), alerts);
            }
        }

        static DebtorCopiesTo BuildCopiesToFromRawData(int? debtorKey, IDataRecord dr)
        {
            var copiesTo = new DebtorCopiesTo();

            var debtor = dr.GetField<int?>("DebtorNo") ?? debtorKey;
            if (debtor != null)
            {
                copiesTo.DebtorNameId = debtor.Value;
            }

            copiesTo.CopyToNameId = dr.GetField<int>("RelatedNameNo");
            copiesTo.CopyToName = dr.GetField<string>("CopyToName");
            copiesTo.ContactNameId = dr.GetField<int?>("ContactNameKey");
            copiesTo.ContactName = dr.GetField<string>("ContactName");
            copiesTo.AddressId = dr.GetField<int?>("AddressKey");
            copiesTo.Address = dr.GetField<string>("Address");
            copiesTo.AddressChangeReasonId = dr.GetField<int?>("AddressChangeReason");

            return copiesTo;
        }

        static DebtorData BuildDebtorListFromRawData(IDataRecord dr, string[] fields)
        {
            return new()
            {
                NameId = dr.GetField<int>("NameNo"),
                NameType = dr.GetField<string>("NameType"),
                NameTypeDescription = dr.GetField<string>("NameTypeDescription"),
                FormattedName = dr.GetField<string>("FormattedName"),
                BillPercentage = dr.GetField<decimal>("BillPercentage"),
                Currency = dr.GetField<string>("Currency"),
                FormattedNameWithCode = fields.Contains("FormattedNameWithCode") 
                    ? dr.GetField<string>("FormattedNameWithCode") 
                    : dr.GetField<string>("FormattedName"),
                BuyExchangeRate = dr.GetField<decimal?>("BuyExchangeRate"),
                SellExchangeRate = dr.GetField<decimal?>("SellExchangeRate"),
                DecimalPlaces = (int) dr["DecimalPlaces"],
                RoundBilledValues = dr.GetField<int?>("RoundBilledValues"),
                ReferenceNo = dr.GetField<string>("ReferenceNo"),
                AttentionName = dr.GetField<string>("AttentionName"),
                AttentionNameId = dr.GetField<int?>("AttentionNameKey"),
                Address = dr.GetField<string>("Address"),
                AddressId = dr.GetField<int?>("AddressKey"),
                AddressChangeReasonId = dr.GetField<int?>("AddressChangeReason"),
                TotalCredits = dr.GetField<decimal>("TotalCredits"),
                Instructions = dr.GetField<string>("Instructions"),
                TaxCode = dr.GetField<string>("TaxCode"),
                TaxDescription = dr.GetField<string>("TaxDescription"),
                TaxRate = dr.GetField<decimal?>("TaxRate"),
                CaseId = dr.GetField<int?>("CaseKey"),
                OpenItemNo = dr.GetField<string>("OpenItemNo"),
                LanguageId = fields.Contains("LanguageKey")
                    ? dr.GetField<int?>("LanguageKey")
                    : null,
                LanguageDescription = fields.Contains("LanguageDescription")
                    ? dr.GetField<string>("LanguageDescription")
                    : null,
                LogDateTimeStamp = dr.GetField<DateTime?>("LogDateTimeStamp"),
                IsMultiCaseAllowed = dr.GetField<byte>("AllowMultiCase") == 1,
                BillFormatProfileId = dr.GetField<int?>("BillFormatProfileKey"),
                BillMapProfileId = dr.GetField<int?>("BillMapProfileKey"),
                BillMapProfileDescription = dr.GetField<string>("BillMapProfileDescription"),
                BillingCap = dr.GetField<decimal?>("BillingCap"),
                BillingCapStart = dr.GetField<DateTime?>("BillingCapStart"),
                BillingCapEnd = dr.GetField<DateTime?>("BillingCapEnd"),
                BilledAmount = dr.GetField<decimal?>("BilledAmount"),
                BillToNameId = dr.GetField<int?>("BillToNameKey"),
                BillToFormattedName = dr.GetField<string>("BillToFormattedName"),
                IsClient = dr.GetField<byte>("IsClient") == 1,
                OfficeEntityId = fields.Contains("OfficeEntity")
                    ? dr.GetField<int?>("OfficeEntity")
                    : null,
                HasOfficeInEu = fields.Contains("HasOfficeInEu") && dr.GetField<byte>("HasOfficeInEu") == 1
            };
        }
        
        static DebtorDiscount BuildDebtorDiscountFromRawData(IDataRecord dr)
        {
            return new()
            {
                NameId = dr.GetField<int>("NameKey"),
                Sequence = dr.GetField<int>("Sequence"),
                DiscountRate = dr.GetField<decimal>("DiscountRate"),
                WipType = dr.GetField<string>("WIPTypeKey"),
                WipTypeDescription = dr.GetField<string>("WIPTypeDescription"),
                WipCategory = dr.GetField<string>("WIPCategoryKey"),
                WipCategoryDescription = dr.GetField<string>("WIPCategoryDescription"),
                PropertyType = dr.GetField<string>("PropertyTypeKey"),
                PropertyTypeDescription = dr.GetField<string>("PropertyTypeDescription"),
                Action = dr.GetField<string>("ActionKey"),
                ActionDescription = dr.GetField<string>("ActionDescription"),
                WipCode = dr.GetField<string>("WIPCodeKey"),
                WipCodeDescription = dr.GetField<string>("WIPCodeDescription"),
                CaseType = dr.GetField<string>("CaseTypeKey"),
                CaseTypeDescription = dr.GetField<string>("CaseTypeDescription"),
                CountryCode = dr.GetField<string>("CountryCode"),
                Country = dr.GetField<string>("Country"),
                ApplyAs = dr.GetField<string>("ApplyAs"),
                BasedOnAmount = dr.GetField<decimal>("BasedOnAmount") == 1,
                CaseOwnerId = dr.GetField<int?>("CaseOwnerKey"),
                CaseOwnerName = dr.GetField<string>("CaseOwnerName"),
                StaffId = dr.GetField<int?>("EmployeeKey"),
                StaffName = dr.GetField<string>("EmployeeName")
            };
        }

        DebtorWarning BuildDebtorWarningsFromRawData(IDataRecord dr)
        {
            return new()
            {
                NameId = dr.GetField<int>("DebtorNameKey"),
                WarningError = _applicationAlerts.TryParse(dr.GetField<string>("WarningXML"), out var alerts)
                            ? alerts.Flatten()
                            : null,
                Severity = (AlertSeverity) dr.GetField<int>("Severity")
            };
        }

        static DebtorReference BuildDebtorReferenceFromRawData(IDataRecord dr)
        {
            return new()
            {
                CaseId = dr.GetField<int>("CaseKey"),
                DebtorNameId = dr.GetField<int>("DebtorKey"),
                ReferenceNo = dr.GetField<string>("ReferenceNo"),
                NameType = dr.GetField<string>("NameType")
            };
        }
    }
}