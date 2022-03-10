using System;
using System.Data;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Presentation
{
    public interface IBillFormatResolver
    {
        Task<BillFormat> Resolve(int userIdentityId, string culture, BillFormatCriteria billFormatCriteria);
        Task<BillFormat> Resolve(int userIdentityId, string culture, int billFormatId);
    }

    public class BillFormatResolver : IBillFormatResolver
    {
        readonly IDbContext _dbContext;

        public BillFormatResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<BillFormat> Resolve(int userIdentityId, string culture, int billFormatId)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.FetchBestBillFormat,
                                                                        new Parameters
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnBillFormatId", billFormatId }
                                                                        });

            using var dr = await command.ExecuteReaderAsync();

            return await dr.ReadAsync()
                ? BuildBillFormatFromRawData(dr)
                : new BillFormat();
        }

        public async Task<BillFormat> Resolve(int userIdentityId, string culture, BillFormatCriteria billFormatCriteria)
        {
            if (billFormatCriteria == null) throw new ArgumentNullException(nameof(billFormatCriteria));

            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.FetchBestBillFormat,
                                                                        new Parameters
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnLanguage", billFormatCriteria.LanguageId },
                                                                            {"@pnEntityNo", billFormatCriteria.EntityId},
                                                                            {"@pnNameNo", billFormatCriteria.NameId },
                                                                            {"@psCaseType", billFormatCriteria.CaseType },
                                                                            {"@psAction", billFormatCriteria.Action},
                                                                            {"@psPropertyType", billFormatCriteria.PropertyType},
                                                                            {
                                                                                "@pnRenewalWIP", billFormatCriteria.TypeOfWipIncluded switch
                                                                                {
                                                                                    TypeOfWipIncluded.IncludeRenewalWip => 1,
                                                                                    TypeOfWipIncluded.IncludeNonRenewalWip => 0,
                                                                                    _ => null
                                                                                }
                                                                            },
                                                                            {"@pnSingleCase", billFormatCriteria.IsSingleCase },
                                                                            {"@pnEmployeeNo", billFormatCriteria.StaffId }
                                                                        });

            using var dr = await command.ExecuteReaderAsync();

            return await dr.ReadAsync()
                ? BuildBillFormatFromRawData(dr)
                : new BillFormat();
        }

        static BillFormat BuildBillFormatFromRawData(IDataRecord dr)
        {
            return new BillFormat
            {
                BillFormatId = dr.GetField<short>("BillFormatId"),
                FormatName = dr.GetField<string>("FormatName"),
                NameId = dr.GetField<int?>("NameNo"),
                LanguageId = dr.GetField<int?>("Language"),
                EntityId = dr.GetField<int?>("EntityNo"),
                CaseType = dr.GetField<string>("CaseType"),
                Action = dr.GetField<string>("Action"),
                StaffId = dr.GetField<int?>("EmployeeNo"),

                Description = dr.GetField<string>("BillFormatDesc"),
                BillFormatReport = dr.GetField<string>("BillFormatReport"),

                ConsolidateByChargeType = dr.GetField<short?>("ConsolidateChTyp"),
                ConsolidateDiscounts = dr.GetField<short?>("ConsolidateDisc"),
                ConsolidateMargins = dr.GetField<short?>("ConsolidateMar"),
                ConsolidateOverheadRecoveries = dr.GetField<short?>("ConsolidateOR"),
                ConsolidatePaidDisbursements = dr.GetField<short?>("ConsolidatePD"),
                ConsolidateServiceCharges = dr.GetField<short?>("ConsolidateSC"),
                DiscountWipCode = dr.GetField<string>("DiscountWIPCode"),
                MarginWipCode = dr.GetField<string>("MarginWIPCode"),
                CoveringLetterId = dr.GetField<short?>("CoveringLetter"),
                DebitNoteId = dr.GetField<short?>("DebitNote"),
                AreDetailsRequired = dr.GetField<short?>("DetailsRequired"),
                ExpenseGroupTitle = dr.GetField<string>("ExpenseGroupTitle"),
                
                OfficeId = dr.GetField<int?>("OfficeId"),
                PropertyType = dr.GetField<string>("PropertyType"),
                IsRenewalWipOnly = dr.GetField<decimal?>("RenewalWIP") switch
                {
                    1 => true, /* Only match on bills with purely renewal related WIP */
                    0 => false, /* Only match on bills with purely non-renewal related WIP */
                    _ => null
                },
                IsSingleCaseOnly = dr.GetField<decimal?>("SingleCase") switch
                {
                    1 => true, /* Only match on bills with a single case */
                    0 => false, /* Only match on bills with multiple cases */
                    _ => null
                },
                SortCase = dr.GetField<short?>("SortCase"),
                SortCaseMode = dr.GetField<short?>("SortCaseMode"),
                SortCaseTitle = dr.GetField<short?>("SortCaseTitle"),
                SortCaseDebtorRef = dr.GetField<short?>("SortCaseDebtorRef"),
                
                SortDate = dr.GetField<short?>("SortDate"),

                SortWipCategory = dr.GetField<short?>("SortWIPCategory"),
                DocumentTypeId = dr.GetField<int?>("DocumentType"),
                SortTaxCode = dr.GetField<int?>("SortTaxCode")
            };
        }
    }

    public class BillFormatCriteria
    {
        public int? LanguageId { get; set; }
        public int? EntityId { get; set; }
        public int? NameId { get; set; }
        public string CaseType { get; set; }
        public string Action { get; set; }
        public string PropertyType { get; set; }
        public TypeOfWipIncluded TypeOfWipIncluded { get; set; }
        public int? IsSingleCase { get; set; }
        public int? StaffId { get; set; }
    }

    public enum TypeOfWipIncluded
    {
        IncludeNonRenewalWip,
        IncludeRenewalWip,
        IncludeBoth
    }
}
