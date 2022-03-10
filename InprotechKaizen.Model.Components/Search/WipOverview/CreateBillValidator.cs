using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Search.WipOverview
{
    public enum CreateBillValidationType
    {
        SingleBill,
        MultipleBill
    }

    public interface ICreateBillValidator
    {
        Task<IEnumerable<CreateBillValidationError>> Validate(IEnumerable<CreateBillRequest> listOfRequest, CreateBillValidationType validationType);
    }

    public class CreateBillValidator : ICreateBillValidator
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;

        public CreateBillValidator(IDbContext dbContext, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
        }

        public async Task<IEnumerable<CreateBillValidationError>> Validate(IEnumerable<CreateBillRequest> listOfRequest, CreateBillValidationType validationType)
        {
            var errors = new List<CreateBillValidationError>();

            var requests = listOfRequest as CreateBillRequest[] ?? listOfRequest.ToArray();
            var caseKeys = requests.Where(x => x.CaseKey.HasValue).Select(x => x.CaseKey);

            var selectedCases = await (from c in _dbContext.Set<Case>()
                                       join cs in _dbContext.Set<Status>() on c.StatusCode equals cs.Id into cs1
                                       from cs in cs1.DefaultIfEmpty()
                                       join cn in _dbContext.Set<CaseName>() on c.Id equals cn.CaseId into cn1
                                       from cn in cn1.DefaultIfEmpty()
                                       where caseKeys.Contains(c.Id)
                                       select new
                                       {
                                           CaseKey = c.Id,
                                           c.TypeId,
                                           c.Irn,
                                           PreventBilling = cs == null ? null : cs.PreventBilling,
                                           NameNo = cn == null ? (int?)null : cn.NameId,
                                           NameTypeId = cn == null ? null : cn.NameTypeId,
                                           NameExpiryDate = cn == null ? null : cn.ExpiryDate
                                       }).ToArrayAsync();

            var preventedBillingCaseRefs = selectedCases.Where(x => x.PreventBilling.HasValue && x.PreventBilling.Value)
                                                        .Select(x => x.Irn).Distinct().ToArray();
            if (preventedBillingCaseRefs.Any())
            {
                errors.Add(new CreateBillValidationError { CaseReference = string.Join(", ", preventedBillingCaseRefs), ErrorCode = "AC113" });
            }

            var noDebtorCaseKeys = requests.Where(x => !x.DebtorKey.HasValue)
                                           .Select(x => x.CaseKey).Distinct().ToArray();
            if (noDebtorCaseKeys.Any())
            {
                var noDebtorIrns = string.Join(", ", selectedCases.Where(x => noDebtorCaseKeys.Contains(x.CaseKey)).Select(x => x.Irn).Distinct().ToArray());
                errors.Add(new CreateBillValidationError { CaseReference = noDebtorIrns, ErrorCode = "AC138" });
            }

            if (validationType == CreateBillValidationType.SingleBill)
            {
                if (requests.Where(x => !x.CaseKey.HasValue).Select(x => x.DebtorKey).Distinct().Count() > 1)
                {
                    errors.Add(new CreateBillValidationError { ErrorCode = "AC114" });
                }

                if (requests.Any(x => x.CaseKey.HasValue) && requests.Any(x => !x.CaseKey.HasValue))
                {
                    errors.Add(new CreateBillValidationError { ErrorCode = "AC115" });
                }

                var internalCaseType = _siteControlReader.Read<string>(SiteControls.CaseTypeInternal);
                if (!string.IsNullOrWhiteSpace(internalCaseType))
                {
                    if (selectedCases.Any(x => x.TypeId == internalCaseType)
                        && selectedCases.Any(x => x.TypeId != internalCaseType))
                    {
                        errors.Add(new CreateBillValidationError { ErrorCode = "AC116" });
                    }
                }

                var wipSplitDebtor = _siteControlReader.Read<bool>(SiteControls.WIPSplitMultiDebtor);
                if (wipSplitDebtor)
                {
                    if (requests.Where(x => x.AllocatedDebtorKey.HasValue).Select(x => x.AllocatedDebtorKey).Distinct().Count() > 1)
                    {
                        errors.Add(new CreateBillValidationError { ErrorCode = "AC219" });
                    }

                    var activeNameCount = selectedCases.Where(x => x.NameTypeId == KnownNameTypes.Debtor && !x.NameExpiryDate.HasValue)
                                                       .Select(x => x.NameNo)
                                                       .Distinct()
                                                       .Count();
                    if (!errors.Any(x => x.ErrorCode == "AC114") && activeNameCount > 1)
                    {
                        errors.Add(new CreateBillValidationError { ErrorCode = "AC114" });
                    }
                }
            }

            return errors.Distinct();
        }
    }

    public class CreateBillValidationError
    {
        public string CaseReference { get; set; }
        public string ErrorCode { get; set; }
    }

    public class CreateBillRequest
    {
        public int? DebtorKey { get; set; }
        public int? CaseKey { get; set; }
        public int? AllocatedDebtorKey { get; set; }
    }
}