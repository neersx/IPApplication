using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public interface IProtocolDisbursements
    {
        Task<Disbursement> Retrieve(int userIdentityId, string culture, int transKey, string protocolKey, string protocolDateString);
    }

    public class ProtocolDisbursements : IProtocolDisbursements
    {
        readonly IDbContext _dbContext;
        readonly ILogger<ProtocolDisbursements> _logger;

        public ProtocolDisbursements(IDbContext dbContext, ILogger<ProtocolDisbursements> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task<Disbursement> Retrieve(int userIdentityId, string culture, int transKey, string protocolKey, string protocolDateString)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.WipManagement.ListProtocolDisbursements,
                                                                        new Dictionary<string, object>
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnCreditItemTransKey", transKey},
                                                                            {"@psProtocolKey", protocolKey},
                                                                            {"@psProtocolDate", protocolDateString}
                                                                        });
            using var dr = await command.ExecuteReaderAsync();
            if (!dr.Read())
                throw new Exception("Could not load Protocol Details.");

            var disbursement = new Disbursement();
            TranslateDisbursementBase(disbursement, dr);
            if (dr.NextResult())
            {
                while (dr.Read())
                {
                    if (!Convert.ToBoolean(dr["DiscountFlag"]) && !Convert.ToBoolean(dr["MarginFlag"]))
                        disbursement.DissectedDisbursements.Add(TranslateDisbursementWip(dr));
                    else if (Convert.ToBoolean(dr["DiscountFlag"]) && !Convert.ToBoolean(dr["MarginFlag"]))
                        UpdateDiscount(disbursement.DissectedDisbursements.Last(), dr);
                    else if (!Convert.ToBoolean(dr["DiscountFlag"]) && Convert.ToBoolean(dr["MarginFlag"]))
                        UpdateMargin(disbursement.DissectedDisbursements.Last(), dr);
                    else if (Convert.ToBoolean(dr["DiscountFlag"]) && Convert.ToBoolean(dr["MarginFlag"]))
                        UpdateMarginDiscount(disbursement.DissectedDisbursements.Last(), dr);
                }
            }
            
            _logger.Trace($"Disbursement Retrieved ProtocolKey={protocolKey}/ProtocolDate={protocolDateString}", disbursement);

            return disbursement ;
        }

        static void TranslateDisbursementBase(Disbursement db, IDataReader dr)
        {
            db.AssociateKey = Convert.ToInt32(dr["CreditorKey"]);
            db.AssociateNameCode = dr["CreditorCode"] as string;
            db.AssociateName = dr["CreditorName"] as string;
            db.EntityKey = Convert.ToInt32(dr["EntityKey"]);
            db.InvoiceNo = dr["InvoiceKey"] as string;
            db.Currency = dr["Currency"] as string;
            db.CurrencyDescription = dr["CurrencyDescription"] as string;
            db.TotalAmount = Convert.ToDecimal(dr["PurchaseValue"]);
        }

        static void UpdateDiscount(DisbursementWip dw, IDataReader dr)
        {
            dw.Discount = Math.Abs(Convert.ToDecimal(dr["LocalValue"]));

            if (!dr.IsDBNull(dr.GetOrdinal("ForeignValue")))
                dw.ForeignDiscount = Math.Abs(Convert.ToDecimal(dr["ForeignValue"]));
        }

        static void UpdateMargin(DisbursementWip dw, IDataReader dr)
        {
            dw.Margin = Convert.ToDecimal(dr["LocalValue"]);

            if (!dr.IsDBNull(dr.GetOrdinal("ForeignValue")))
                dw.ForeignMargin = Convert.ToDecimal(dr["ForeignValue"]);
        }

        static void UpdateMarginDiscount(DisbursementWip dw, IDataReader dr)
        {
            dw.LocalDiscountForMargin = Convert.ToDecimal(dr["LocalValue"]);

            if (!dr.IsDBNull(dr.GetOrdinal("ForeignValue")))
                dw.ForeignDiscountForMargin = Convert.ToDecimal(dr["ForeignValue"]);
        }

        static DisbursementWip TranslateDisbursementWip(IDataReader dr)
        {
            var dw = new DisbursementWip
                         {
                             WIPSeqNo = Convert.ToInt16(dr["WIPSeqNo"]),
                             TransDate = Convert.ToDateTime(dr["TransDate"]),
                             WIPCode = dr["WIPCode"] as string,
                             Description = dr["WIPDescription"] as string
                         };

            if (!dr.IsDBNull(dr.GetOrdinal("CaseKey")))
            {
                dw.CaseKey = Convert.ToInt32(dr["CaseKey"]);
                dw.IRN = dr["IRN"] as string;
            }

            if (!dr.IsDBNull(dr.GetOrdinal("CreditorKey")))
            {
                dw.NameKey = Convert.ToInt32(dr["CreditorKey"]);
                dw.NameCode = dr["CreditorNameCode"] as string;
                dw.Name = dr["CreditorName"] as string;
            }

            dw.StaffKey = Convert.ToInt32(dr["EmployeeKey"]);
            dw.StaffNameCode = dr["EmployeeNameCode"] as string;
            dw.StaffName = dr["EmployeeName"] as string;

            dw.Amount = Convert.ToDecimal(dr["LocalCost"]);

            if (!dr.IsDBNull(dr.GetOrdinal("MarginNo")))
                dw.MarginNo = Convert.ToInt32(dr["MarginNo"]);

            if (Convert.ToDecimal(dr["LocalValue"]) - dw.Amount != 0)
                dw.Margin = Convert.ToDecimal(dr["LocalValue"]) - dw.Amount;

            dw.CurrencyCode = dr["ForeignCurrency"] as string;

            if (!string.IsNullOrEmpty(dw.CurrencyCode))
            {
                if (!dr.IsDBNull(dr.GetOrdinal("ForeignCost")))
                    dw.ForeignAmount = Convert.ToDecimal(dr["ForeignCost"]);

                if (Convert.ToDecimal(dr["ForeignValue"]) - dw.Amount != 0)
                    dw.ForeignMargin = Convert.ToDecimal(dr["ForeignValue"]) - dw.ForeignAmount;
            }

            if (!dr.IsDBNull(dr.GetOrdinal("NarrativeKey")))
                dw.NarrativeKey = Convert.ToInt32(dr["NarrativeKey"]);

            dw.DebitNoteText = dr["DebitNoteText"] as string;
            dw.VerificationNo = dr["VerificationNo"] as string;

            if (!dr.IsDBNull(dr.GetOrdinal("EnteredQuantity")))
                dw.Quantity = Convert.ToInt32(dr["EnteredQuantity"]);
            return dw;
        }
    }

    public class Disbursement
    {
        public List<DisbursementWip> DissectedDisbursements { get; } = new ();

        public int EntityKey { get; set; }
        public int? TransKey { get; set; }
        public DateTime? TransDate { get; set; }

        public int? AssociateKey { get; set; }
        public string AssociateNameCode { get; set; }
        public string AssociateName { get; set; }

        public string Currency { get; set; }
        public string CurrencyDescription { get; set; }
        public decimal TotalAmount { get; set; }
        public bool CreditWIP { get; set; }
        public string InvoiceNo { get; set; }
        public string VerificationNo { get; set; }

        public string ProtocolKey { get; set; }
        public string ProtocolDate { get; set; }
    }

    public class DisbursementWip
    {
        public int WIPSeqNo { get; set; }
        public DateTime? TransDate { get; set; }
        public int? NameKey { get; set; }
        public string NameCode { get; set; }
        public string Name { get; set; }

        public int? CaseKey { get; set; }
        public string IRN { get; set; }

        public int StaffKey { get; set; }
        public string StaffNameCode { get; set; }
        public string StaffName { get; set; }

        public string WIPCode { get; set; }
        public string Description { get; set; }
        public string ProductCode { get; set; }
        public int? ProductKey { get; set; }
        public string ProductCodeDescription { get; set; }
        public decimal Amount { get; set; }
        public decimal? Margin { get; set; }
        public decimal? ForeignMargin { get; set; }
        public decimal? Discount { get; set; }
        public decimal? ForeignDiscount { get; set; }
        public string CurrencyCode { get; set; }
        public decimal? ForeignAmount { get; set; }
        public decimal? ExchRate { get; set; }
        public int? Quantity { get; set; }
        public int? NarrativeKey { get; set; }
        public string NarrativeCode { get; set; }
        public string NarrativeText { get; set; }
        public string DebitNoteText { get; set; }
        public string VerificationNo { get; set; }
        public decimal? LocalCost1 { get; set; }
        public decimal? LocalCost2 { get; set; }
        public int? MarginNo { get; set; }
        public decimal? LocalDiscountForMargin { get; set; }
        public decimal? ForeignDiscountForMargin { get; set; }
        public string DateStyle { get; set; }
        public bool IsSplitDebtorWip { get; set; }
        public decimal? DebtorSplitPercentage { get; set; }
        public int? LocalDecimalPlaces { get; set; }
        public List<DisbursementWip> SplitWipItems { get; } = new();
    }
}
