using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Banking;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names.Payment;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Names.Details
{
    public interface INameViewResolver
    {
        IEnumerable<KeyValuePair<string, string>> GetSupplierTypes();
        IEnumerable<KeyValuePair<string, string>> GetTaxTreatment();
        IEnumerable<KeyValuePair<string, string>> GetTaxRates();
        IEnumerable<KeyValuePair<string, string>> GetPaymentTerms();
        IEnumerable<KeyValuePair<string, string>> GetPaymentMethods();
        IEnumerable<KeyValuePair<string, string>> GetIntoBankAccounts(int nameId);
        IEnumerable<KeyValuePair<string, string>> GetPaymentRestrictions();
        IEnumerable<KeyValuePair<string, string>> GetReasonsForRestrictions();
        bool CheckNameMaintainPermission();
    }

    public class NameViewResolver : INameViewResolver
    {
        readonly string _culture;
        readonly IDbContext _dbContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public NameViewResolver(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ITaskSecurityProvider taskSecurityProvider)
        {
            _dbContext = dbContext;
            _culture = preferredCultureResolver.Resolve();
            _taskSecurityProvider = taskSecurityProvider;
        }

        public IEnumerable<KeyValuePair<string, string>> GetSupplierTypes()
        {
            var supplierTypes = _dbContext.Set<TableCode>()
                                       .Select(_ => new
                                       {
                                           _.Id,
                                           Description = DbFuncs.GetTranslation(_.Name, null, _.NameTId, _culture),
                                           _.TableTypeId
                                       })
                                       .Where(_ => _.TableTypeId == (short)TableTypes.SupplierType)
                                       .ToArray();

            return supplierTypes.Select(_ => new KeyValuePair<string, string>(_.Id.ToString(), _.Description));
        }

        public IEnumerable<KeyValuePair<string, string>> GetTaxTreatment()
        {
            var taxTreatments = _dbContext.Set<TableCode>()
                                         .Select(_ => new
                                         {
                                             _.Id,
                                             Description = DbFuncs.GetTranslation(_.Name, null, _.NameTId, _culture),
                                             _.TableTypeId
                                         })
                                         .Where(_ => _.TableTypeId == (short)TableTypes.TaxTreatment)
                                         .ToArray();

            return taxTreatments.Select(_ => new KeyValuePair<string, string>(_.Id.ToString(), _.Description));
        }

        public IEnumerable<KeyValuePair<string, string>> GetTaxRates()
        {
            var taxRates = _dbContext.Set<TaxRate>()
                                         .Select(_ => new
                                         {
                                             Id = _.Code,
                                             Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, _culture)
                                         })
                                         .ToArray();

            return taxRates.Select(_ => new KeyValuePair<string, string>(_.Id.ToString(), _.Description));
        }

        public IEnumerable<KeyValuePair<string, string>> GetPaymentTerms()
        {
            var paymentTerms = _dbContext.Set<Frequency>()
                                     .Select(_ => new
                                     {
                                         _.Id,
                                         Description = DbFuncs.GetTranslation(_.Name, null, _.NameTId, _culture),
                                         _.FrequencyType
                                     })
                                     .Where(_ => _.FrequencyType == (short)1)
                                     .ToArray();

            return paymentTerms.Select(_ => new KeyValuePair<string, string>(_.Id.ToString(), _.Description));
        }

        public IEnumerable<KeyValuePair<string, string>> GetPaymentMethods()
        {

            var paymentMethods = _dbContext.Set<PaymentMethods>()
                                         .Select(_ => new
                                         {
                                             _.Id,
                                             Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, _culture),
                                             UsedBy = (short)_.UsedBy
                                         })
                                         .Where(_ => (_.UsedBy & (short) KnownPaymentMethod.Payable) == (short) KnownPaymentMethod.Payable)
                                         .ToArray();

            return paymentMethods.Select(_ => new KeyValuePair<string, string>(_.Id.ToString(), _.Description));
        }

        public IEnumerable<KeyValuePair<string, string>> GetIntoBankAccounts(int nameId)
        {

            var bankAccounts = _dbContext.Set<BankAccount>()
                                         .Select(_ => new
                                         {
                                             Code = _.AccountOwner+ "^" + _.BankNameNo + "^" + _.SequenceNo,
                                             _.Description,
                                             _.AccountOwner
                                         })
                                         .Where(_ => _.AccountOwner == nameId)
                                         .ToArray();

            return bankAccounts.Select(_ => new KeyValuePair<string, string>(_.Code.ToString(), _.Description));
        }

        public IEnumerable<KeyValuePair<string, string>> GetPaymentRestrictions()
        {

            var paymentRestrictions = _dbContext.Set<CrRestriction>()
                                         .Select(_ => new
                                         {
                                             _.Id,
                                             Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, _culture)
                                         })
                                         .ToArray();

            return paymentRestrictions.Select(_ => new KeyValuePair<string, string>(_.Id.ToString(), _.Description));
        }

        public IEnumerable<KeyValuePair<string, string>> GetReasonsForRestrictions()
        {
            var reasonForRestriction = _dbContext.Set<Reason>()
                                         .Select(_ => new
                                         {
                                             _.Code,
                                             UsedBy = (int)_.UsedBy,
                                             Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, _culture)
                                         })
                                         .Where(_ => (_.UsedBy & (int) KnownApplicationUsage.AccountsPayable) == (int) KnownApplicationUsage.AccountsPayable ||
                                                     (_.UsedBy & (int) KnownApplicationUsage.AccountsReceivable) == (int) KnownApplicationUsage.AccountsReceivable)
                                         .ToArray();

            return reasonForRestriction.Select(_ => new KeyValuePair<string, string>(_.Code.ToString(), _.Description));
        }

        public bool CheckNameMaintainPermission()
        {
            return _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainName);
        }
    }
}