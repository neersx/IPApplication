using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Accounting.Work
{
    public interface IWipStatusEvaluator
    {
        Task<WipStatusEnum> GetWipStatus(int entryNo, int employeeNo);
    }

    public class WipStatusEvaluator : IWipStatusEvaluator
    {
        readonly IDbContext _dbContext;

        public WipStatusEvaluator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<WipStatusEnum> GetWipStatus(int entryNo, int employeeNo)
        {
            var diary = _dbContext.Set<Diary>().Where(_ => _.EntryNo == entryNo && _.EmployeeNo == employeeNo && _.WipEntityId.HasValue && _.TransactionId.HasValue);
            var wip = _dbContext.Set<WorkInProgress>();

            var details = await (from d in diary
                                 join w in wip on new {EntityNo = d.WipEntityId.Value, TransNo = d.TransactionId.Value} equals new {EntityNo = w.EntityId, TransNo = w.TransactionId} into k1
                                 select new
                                 {
                                     diary = new
                                     {
                                         WipEntityNo = d.WipEntityId, TransNo = d.TransactionId, d.TimeValue, d.DiscountValue
                                     },
                                     wips = k1.Select(w => new
                                     {
                                         IsDiscount = w.IsDiscount == 1, w.Balance, w.Status
                                     })
                                 }).SingleOrDefaultAsync();

            if (details == null)
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            if (!details.wips.Any() && details.diary.TimeValue.GetValueOrDefault() > 0)
            {
                return WipStatusEnum.Billed;
            }

            if (details.wips.Any() && details.wips.All(_ => _.IsDiscount))
            {
                return WipStatusEnum.Adjusted;
            }

            if (details.wips.Any(_ => _.Status == TransactionStatus.Locked))
            {
                return WipStatusEnum.Locked;
            }

            if (details.wips.Any(_ => !_.IsDiscount && _.Balance != details.diary.TimeValue || _.IsDiscount && _.Balance != details.diary.DiscountValue * -1))
            {
                return WipStatusEnum.Adjusted;
            }

            var workHistory = await (from w in _dbContext.Set<WorkHistory>()
                                     where w.TransactionId == details.diary.TransNo 
                                           && w.EntityId == details.diary.WipEntityNo 
                                           && w.TransactionType == TransactionType.Bill
                                     select w).AnyAsync();

            return workHistory ? WipStatusEnum.Billed : WipStatusEnum.Editable;
        }
    }

    public enum WipStatusEnum
    {
        Editable,
        Locked,
        Billed,
        Adjusted
    }

    public static class KnownWipStatusErrors
    {
        public const string Locked = "AC146";
        public const string Billed = "AC149";
        public const string Adjusted = "AC150";
    }
}