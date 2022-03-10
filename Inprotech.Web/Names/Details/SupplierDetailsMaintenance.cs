using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Processing;
using Inprotech.Web.Names.Maintenance.Models;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Names.Payment;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using Currency = InprotechKaizen.Model.Cases.Currency;
using Name = InprotechKaizen.Model.Names.Name;

namespace Inprotech.Web.Names.Details
{
    public interface ISupplierDetailsMaintenance
    {
        Task<NameSupplierDetailData> GetSupplierDetails(int nameId);
        Creditor SaveSupplierDetails(int nameId, SupplierDetailsSaveModel data);
        void SaveAssociatedNameAndRecalculateDerivedAttention(int nameId, SupplierDetailsSaveModel data, bool recalculateDerivedAttention);
    }

    public class SupplierDetailsMaintenance : ISupplierDetailsMaintenance
    {
        readonly string _culture;
        readonly IDbContext _dbContext;
        readonly IFormattedNameAddressTelecom _formattedNameAddressTelecom;
        readonly ISecurityContext _securityContext;
        readonly IAsyncCommandScheduler _asyncCommandScheduler;

        public SupplierDetailsMaintenance(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IFormattedNameAddressTelecom formattedNameAddressTelecom, ISecurityContext securityContext, IAsyncCommandScheduler asyncCommandScheduler)
        {
            _dbContext = dbContext;
            _formattedNameAddressTelecom = formattedNameAddressTelecom;
            _culture = preferredCultureResolver.Resolve();
            _securityContext = securityContext;
            _asyncCommandScheduler = asyncCommandScheduler;
        }

        public async Task<NameSupplierDetailData> GetSupplierDetails(int nameId)
        {
            var supplier = _dbContext.Set<Name>().SingleOrDefault(v => v.Id == nameId);
            if (supplier == null) throw new ArgumentNullException(nameof(supplier));

            var paymentNameResult = (from an in _dbContext.Set<AssociatedName>()
                                     where an.Id == nameId && an.Relationship == KnownRelations.Pay
                                    select new
                                    {
                                        SendToName = an.RelatedNameId,
                                        SendToAttention = an.ContactId,
                                        SendToAddress = an.PostalAddressId

                                    }).FirstOrDefault();

            var nameIds = new List<int>();
            if (paymentNameResult?.SendToName != null) nameIds.Add(paymentNameResult.SendToName);
            if (paymentNameResult?.SendToAttention != null) nameIds.Add((int) paymentNameResult.SendToAttention);
            if (supplier.MainContactId != null) nameIds.Add((int) supplier.MainContactId);
            var formattedNames = await _formattedNameAddressTelecom.GetFormatted(nameIds.ToArray());

            var addressIds = new List<int>();
            if (paymentNameResult?.SendToAddress != null) addressIds.Add((int) paymentNameResult.SendToAddress);
            if (supplier.PostalAddressId != null) addressIds.Add((int) supplier.PostalAddressId);
            var formattedAddresses = await _formattedNameAddressTelecom.GetAddressesFormatted(addressIds.ToArray());
        
            var hasOutstandingPurchases = _dbContext.Set<CreditorItem>().Count(_ => _.AccountCreditorId == nameId && _.LocalBalance != 0) > 0;

            var creditor = _dbContext.Set<Creditor>().Where(_ => _.NameId == nameId);
            var currency = _dbContext.Set<Currency>();
            var exRateSchedule = _dbContext.Set<ExchangeRateSchedule>();
            var profitCenter = _dbContext.Set<ProfitCentre>();
            var ledgerAccount = _dbContext.Set<LedgerAccount>();
            var wipDisbursement = _dbContext.Set<WipTemplate>();
            var crRestrictions = _dbContext.Set<CrRestriction>();

            var supplierDetails = await (from cr in creditor
                                         join cur in currency on cr.PurchaseCurrency equals cur.Id into currencyDetails
                                         from curD in currencyDetails.DefaultIfEmpty()
                                         join ers in exRateSchedule on cr.ExchangeScheduleId equals ers.Id into exRateScheduleDetails
                                         from ersD in exRateScheduleDetails.DefaultIfEmpty()
                                         join pc in profitCenter on cr.ProfitCentre equals pc.Id into profitCenterDetails
                                         from pcD in profitCenterDetails.DefaultIfEmpty()
                                         join la in ledgerAccount on cr.ExpenseAccount equals la.Id into ledgerAccountDetails
                                         from laD in ledgerAccountDetails.DefaultIfEmpty()
                                         join wt in wipDisbursement on cr.DisbursementWipCode equals wt.WipCode into wipDisbursementDetails
                                         from wtD in wipDisbursementDetails.DefaultIfEmpty()
                                         join rst in crRestrictions on cr.RestrictionId equals rst.Id into crRestrictionsDetails
                                         from rstD in crRestrictionsDetails.DefaultIfEmpty()
                                         select new NameSupplierData
                                         {
                                             SupplierType = cr.SupplierType.ToString(),
                                             PurchaseDescription = cr.PurchaseDescription,
                                             DefaultTaxCode = cr.DefaultTaxCode,
                                             TaxTreatmentCode = cr.TaxTreatment != null ? cr.TaxTreatment.ToString() : null,
                                             PaymentTermNo = cr.PaymentTermNo != null ? cr.PaymentTermNo.ToString() : null,
                                             Instruction = cr.Instructions != null ? DbFuncs.GetTranslation(cr.Instructions, null, cr.InstructionsTId, _culture) : null,
                                             WithPayee = cr.ChequePayee,
                                             PayVia = cr.PaymentMethod != null ? cr.PaymentMethod.ToString() : null,
                                             IntoBankAccountCode = cr.BankNameNo == null ? string.Empty : cr.BankAccountOwner + "^" + cr.BankNameNo + "^" + cr.BankSequenceNo,
                                             ReasonCode = cr.RestrictionReasonCode,
                                             PurchaseCurrencyCode = cr.PurchaseCurrency,
                                             PurchaseCurrency = curD != null ? DbFuncs.GetTranslation(curD.Description, null, curD.DescriptionTId, _culture) : null,
                                             ExchangeRateId = ersD != null ? ersD.Id : (int?) null,
                                             ExchangeRateCode = ersD != null ? ersD.ExchangeScheduleCode : string.Empty,
                                             ExchangeRateDesc = ersD != null ? DbFuncs.GetTranslation(ersD.Description, null, ersD.DescriptionTId, _culture) : null,
                                             ProfitCentreCode = pcD != null ? pcD.Id : null,
                                             ProfitCentreDesc = pcD != null ? DbFuncs.GetTranslation(pcD.Name, null, pcD.NameTId, _culture) : null,
                                             LedgerAccId = laD != null ? laD.Id : (int?) null,
                                             LedgerAccCode = laD != null ? laD.AccountCode : null,
                                             LedgerAccDesc = laD != null ? laD.Description : null,
                                             WipCode = cr.DisbursementWipCode,
                                             WipDisbursement = wtD != null ? wtD.Description : null,
                                             RestrictionKey = rstD != null ? rstD.Id.ToString() : string.Empty
                                         }).SingleOrDefaultAsync();

            if (supplierDetails != null)
            {
                return new NameSupplierDetailData
                {
                    SupplierType = supplierDetails.SupplierType,
                    PurchaseDescription = supplierDetails.PurchaseDescription,
                    PurchaseCurrency = new CodeDescPair {Code = supplierDetails.PurchaseCurrencyCode, Description = supplierDetails.PurchaseCurrency},
                    ExchangeRate = new CodeDescPair {Id = supplierDetails.ExchangeRateId.ToString(), Code = supplierDetails.ExchangeRateCode, Description = supplierDetails.ExchangeRateDesc},
                    DefaultTaxCode = supplierDetails.DefaultTaxCode,
                    TaxTreatmentCode = supplierDetails.TaxTreatmentCode,
                    PaymentTermNo = supplierDetails.PaymentTermNo,
                    ProfitCentre = new CodeDescPair {Code = supplierDetails.ProfitCentreCode, Description = supplierDetails.ProfitCentreDesc},
                    LedgerAcc = new CodeDescPair {Id = supplierDetails.LedgerAccId.ToString(), Code = supplierDetails.LedgerAccCode, Description = supplierDetails.LedgerAccDesc},
                    WipDisbursement = new CodeDescPair {Key = supplierDetails.WipCode, Value = supplierDetails.WipDisbursement},
                    SendToName = paymentNameResult?.SendToName == null
                        ? null
                        : new Picklists.Name
                        {
                            Key = formattedNames[paymentNameResult.SendToName].NameId,
                            Code = formattedNames[paymentNameResult.SendToName].NameCode,
                            DisplayName = formattedNames[paymentNameResult.SendToName].Name
                        },
                    SendToAttentionName = paymentNameResult?.SendToAttention == null
                        ? null
                        : new Picklists.Name
                        {
                            Key = formattedNames[(int) paymentNameResult.SendToAttention].NameId,
                            Code = formattedNames[(int) paymentNameResult.SendToAttention].NameCode,
                            DisplayName = formattedNames[(int) paymentNameResult.SendToAttention].Name
                        },
                    SendToAddress = paymentNameResult?.SendToAddress == null
                        ? null
                        : new AddressPicklistItem
                        {
                            Id = formattedAddresses[(int) paymentNameResult.SendToAddress].Id,
                            Address = formattedAddresses[(int) paymentNameResult.SendToAddress].Address
                        },
                    Instruction = supplierDetails.Instruction,
                    WithPayee = supplierDetails.WithPayee,
                    PaymentMethod = supplierDetails.PayVia,
                    IntoBankAccountCode = supplierDetails.IntoBankAccountCode,
                    RestrictionKey = supplierDetails.RestrictionKey,
                    OldRestrictionKey = supplierDetails.RestrictionKey,
                    ReasonCode = supplierDetails.ReasonCode,
                    SupplierName = new Picklists.Name
                    {
                        Key = supplier.Id,
                        Code = supplier.NameCode,
                        DisplayName = supplier.Formatted()
                    },
                    SupplierNameAddress = supplier.PostalAddressId == null 
                        ? null 
                        : new AddressPicklistItem
                        {
                            Id = formattedAddresses[(int) supplier.PostalAddressId].Id,
                            Address = formattedAddresses[(int) supplier.PostalAddressId].Address
                        },
                    SupplierMainContact = supplier.MainContactId == null
                        ? null
                        : new Picklists.Name
                        {
                            Key = formattedNames[(int) supplier.MainContactId].NameId,
                            Code = formattedNames[(int) supplier.MainContactId].NameCode,
                            DisplayName = formattedNames[(int) supplier.MainContactId].Name
                        },
                    OldSendToName = paymentNameResult?.SendToName == null
                        ? new Picklists.Name
                        {
                            Key = supplier.Id,
                            Code = supplier.NameCode,
                            DisplayName = supplier.Formatted()
                        }
                        : new Picklists.Name
                        {
                            Key = formattedNames[paymentNameResult.SendToName].NameId,
                            Code = formattedNames[paymentNameResult.SendToName].NameCode,
                            DisplayName = formattedNames[paymentNameResult.SendToName].Name
                        },
                    OldSendToAttentionName = paymentNameResult?.SendToAttention == null
                        ? null
                        : new Picklists.Name
                        {
                            Key = formattedNames[(int) paymentNameResult.SendToAttention].NameId,
                            Code = formattedNames[(int) paymentNameResult.SendToAttention].NameCode,
                            DisplayName = formattedNames[(int) paymentNameResult.SendToAttention].Name
                        },
                    OldSendToAddress = paymentNameResult?.SendToAddress == null
                        ? supplier.PostalAddressId == null 
                            ? null : new AddressPicklistItem
                        {
                            Id = formattedAddresses[(int) supplier.PostalAddressId].Id,
                            Address = formattedAddresses[(int) supplier.PostalAddressId].Address
                        }
                        : new AddressPicklistItem
                        {
                            Id = formattedAddresses[(int) paymentNameResult.SendToAddress].Id,
                            Address = formattedAddresses[(int) paymentNameResult.SendToAddress].Address
                        },
                    HasOutstandingPurchases = hasOutstandingPurchases
                };
            }
            return new NameSupplierDetailData();
        }

        public Creditor SaveSupplierDetails(int nameId, SupplierDetailsSaveModel data)
        {
            var creditor = _dbContext.Set<Creditor>().FirstOrDefault(_ => _.NameId == nameId);

            if (creditor == null || data == null) return null;
            UpdateCreditor(data, creditor);
           
            if (data.SendToName != data.OldSendToName)
            {
                SaveAssociatedNameAndRecalculateDerivedAttention(nameId, data, false);
            }

            if (data.HasOutstandingPurchases && data.UpdateOutstandingPurchases)
            {
                UpdateOutStandingPurchases(nameId, string.IsNullOrEmpty(data.RestrictionKey) ? (int?) null : Convert.ToInt32(data.RestrictionKey));
            }

            return creditor;
        }

        public void SaveAssociatedNameAndRecalculateDerivedAttention(int nameId, SupplierDetailsSaveModel data, bool recalculateDerivedAttention)
        {
            if (data.HasChangedSendToName || data.HasChangedSendToAddress || data.HasChangedSendToAttentionName)
            {
                if (data.SendToName != null && data.IsNotDefaultSendToName
                    || data.SendToAttentionName != null && data.IsNotDefaultSendToAddress
                    || data.SendToAddress != null && data.IsNotDefaultSendToAttentionName)
                {
                    var associatedName =
                        _dbContext.Set<AssociatedName>().FirstOrDefault(
                                                                        an => an.Id == nameId &&
                                                                              an.Relationship == KnownRelations.Pay &&
                                                                              an.RelatedNameId == data.OldSendToName.Key
                                                                       );
                    if (associatedName != null)
                    {
                        if (recalculateDerivedAttention)
                        {
                            RecalculateDerivedAttention(data.SendToName.Key, null, data.SendToAttentionName?.Key, data.SupplierName.Key, KnownRelations.Pay, 0);
                        }
                        else
                        {
                            UpdateAssociatedName(nameId, data);
                        }
                    }
                    else
                    {
                        InsertAssociatedName(nameId, data);
                    }
                }
                else
                {
                    if (recalculateDerivedAttention)
                    {
                        RecalculateDerivedAttention(data.SendToName.Key, null, null, data.SupplierName.Key, KnownRelations.Pay, 0);
                    }
                    else
                    {
                        DeleteAssociatedName(nameId, data);
                    }
                }
            }
        }

        void UpdateCreditor(SupplierDetailsSaveModel data, Creditor creditor)
        {
            creditor.SupplierType = Convert.ToInt32(data.SupplierType);
            creditor.PurchaseDescription = data.PurchaseDescription;
            creditor.DefaultTaxCode = string.IsNullOrEmpty(data.DefaultTaxCode) ? null : data.DefaultTaxCode;
            creditor.TaxTreatment = string.IsNullOrEmpty(data.TaxTreatmentCode) ? (int?) null : Convert.ToInt32(data.TaxTreatmentCode);
            creditor.PaymentTermNo = string.IsNullOrEmpty(data.PaymentTermNo) ? (int?) null : Convert.ToInt32(data.PaymentTermNo);
            creditor.Instructions = data.Instruction;
            creditor.ChequePayee = data.WithPayee;
            creditor.PurchaseCurrency = data.PurchaseCurrency?.Code;
            creditor.ExpenseAccount = string.IsNullOrEmpty(data.LedgerAcc?.Id) ? (int?) null : Convert.ToInt32(data.LedgerAcc.Id);
            creditor.ProfitCentre = data.ProfitCentre?.Code;
            creditor.PaymentMethod = string.IsNullOrEmpty(data.PaymentMethod) ? (int?) null : Convert.ToInt32(data.PaymentMethod);
            creditor.RestrictionId = string.IsNullOrEmpty(data.RestrictionKey) ? (int?) null : Convert.ToInt32(data.RestrictionKey);
            creditor.RestrictionReasonCode = string.IsNullOrEmpty(data.RestrictionKey) ? null : data.ReasonCode;
            creditor.DisbursementWipCode = data.WipDisbursement?.Key;
            creditor.ExchangeScheduleId = string.IsNullOrEmpty(data.ExchangeRate?.Id) ? (int?) null : Convert.ToInt32(data.ExchangeRate.Id);

            if (string.IsNullOrEmpty(data.IntoBankAccountCode)) return;
            var bankData = data.IntoBankAccountCode.Split('^');
            creditor.BankAccountOwner = Convert.ToInt32(bankData[0]);
            creditor.BankNameNo = Convert.ToInt32(bankData[1]);
            creditor.BankSequenceNo = Convert.ToInt32(bankData[2]);
        }

        void UpdateAssociatedName(int nameId, SupplierDetailsSaveModel data)
        {
            if (data.SendToName != null)
            {
                _dbContext.Update(from an in _dbContext.Set<AssociatedName>()
                                             where an.Id == nameId && an.Relationship == KnownRelations.Pay && an.RelatedNameId == data.OldSendToName.Key
                                             select an,
                                             _ => new AssociatedName
                                             {
                                                 RelatedNameId = data.SendToName.Key, 
                                                 ContactId = data.SendToAttentionName == null ? (int?) null : data.SendToAttentionName.Key,
                                                 PostalAddressId = data.SendToAddress == null ? (int?) null : data.SendToAddress.Id
                                             });
            }
        }

        void DeleteAssociatedName(int nameId, SupplierDetailsSaveModel data)
        {
            _dbContext.Delete(from an in _dbContext.Set<AssociatedName>()
                                         where an.Id == nameId &&
                                               an.Relationship == KnownRelations.Pay &&
                                               an.RelatedNameId == data.OldSendToName.Key
                                         select an);
        }

        void InsertAssociatedName(int nameId, SupplierDetailsSaveModel data)
        {
            if (data.SendToName != null)
            {
                var actualName = _dbContext.Set<Name>().FirstOrDefault(n => n.Id == nameId);
                var relatedName = _dbContext.Set<Name>().FirstOrDefault(n => n.Id == data.SendToName.Key);

                var associatedName = new AssociatedName(actualName, relatedName, KnownRelations.Pay, 0)
                {
                    Id = nameId,
                    Relationship = KnownRelations.Pay,
                    RelatedNameId = data.SendToName.Key,
                    ContactId = data.SendToAttentionName?.Key,
                    PostalAddressId = data.SendToAddress?.Id,
                    Sequence = 0
                };
                _dbContext.Set<AssociatedName>().Add(associatedName);
            }
        }

        void UpdateOutStandingPurchases(int nameId, int? restrictionId)
        {
            
            _dbContext.Update(from ci in _dbContext.Set<CreditorItem>()
                                         where ci.AccountCreditorId == nameId && ci.LocalBalance != 0
                                         select ci,
                                         _ => new CreditorItem
                                         {
                                             RestrictionId = restrictionId
                                         });
        }

        void RecalculateDerivedAttention(int mainNameKey,
                                               int? oldAttentionKey = null, int? newAttentionKey = null, int? associatedNameKey = null, string associatedRelation = null, short? associatedSequence = null)
        {

            var parameterDictionary = new Dictionary<string, object>
            {
                {"@pnUserIdentityId", _securityContext.User.Id},
                {"@pnMainNameKey", mainNameKey},
                {"@pbCalledFromCentura", false}
            };
            if (newAttentionKey != null)
            {
                parameterDictionary.Add("@pnNewAttentionKey", newAttentionKey);
            }
            if (oldAttentionKey != null)
            {
                parameterDictionary.Add("@pnOldAttentionKey", oldAttentionKey);
            }
            if (associatedNameKey != null)
            {
                parameterDictionary.Add("@pnAssociatedNameKey", associatedNameKey);
            }
            if (associatedRelation != null)
            {
                parameterDictionary.Add("@psAssociatedRelation", $"'{associatedRelation}'");
            }
            if (associatedSequence != null)
            {
                parameterDictionary.Add("@pnAssociatedSequence", associatedSequence);
            }
            
            _asyncCommandScheduler.ScheduleAsync(Contracts.StoredProcedures.RecalculateDerivedAttention, parameterDictionary);
        }
    }

    public class NameSupplierData
    {
        public string SupplierType { get; set; }
        public string PurchaseDescription { get; set; }
        public string PurchaseCurrencyCode { get; set; }
        public string PurchaseCurrency { get; set; }
        public int? ExchangeRateId { get; set; }
        public string ExchangeRateCode { get; set; }
        public string ExchangeRateDesc { get; set; }
        public string DefaultTaxCode { get; set; }
        public string TaxTreatmentCode { get; set; }
        public string PaymentTermNo { get; set; }
        public string ProfitCentreCode { get; set; }
        public string ProfitCentreDesc { get; set; }
        public int? LedgerAccId { get; set; }
        public string LedgerAccCode { get; set; }
        public string LedgerAccDesc { get; set; }
        public string WipCode { get; set; }
        public string WipDisbursement { get; set; }
        public string Address { get; set; }
        public string Instruction { get; set; }
        public string WithPayee { get; set; }
        public string PayVia { get; set; }
        public string IntoBankAccountCode { get; set; }
        public string RestrictionKey { get; set; }
        public string ReasonCode { get; set; }
    }
    public class NameSupplierDetailData
    {
        public string SupplierType { get; set; }
        public string PurchaseDescription { get; set; }
        public CodeDescPair PurchaseCurrency { get; set; }
        public CodeDescPair ExchangeRate { get; set; }
        public string DefaultTaxCode { get; set; }
        public string TaxTreatmentCode { get; set; }
        public string PaymentTermNo { get; set; }
        public CodeDescPair ProfitCentre { get; set; }
        public CodeDescPair LedgerAcc { get; set; }
        public CodeDescPair WipDisbursement { get; set; }
        public Picklists.Name SendToAttentionName { get; set; }
        public Picklists.Name SendToName { get; set; }
        public AddressPicklistItem SendToAddress { get; set; }
        public string Instruction { get; set; }
        public string WithPayee { get; set; }
        public string PaymentMethod { get; set; }
        public string IntoBankAccountCode { get; set; }
        public string RestrictionKey { get; set; }
        public string OldRestrictionKey { get; set; }
        public string ReasonCode { get; set; }
        public Picklists.Name SupplierName { get; set; }
        public AddressPicklistItem SupplierNameAddress { get; set; }
        public Picklists.Name SupplierMainContact { get; set; }
        public Picklists.Name OldSendToAttentionName { get; set; }
        public Picklists.Name OldSendToName { get; set; }
        public AddressPicklistItem OldSendToAddress { get; set; }
        public bool HasOutstandingPurchases { get; set; }
    }
    public class CodeDescPair
    {
        public string Id { get; set; }
        public string Code { get; set; }
        public string Description { get; set; }
        public string Key { get; set; }
        public string Value { get; set; }
    }
}
