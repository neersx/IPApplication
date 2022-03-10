using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Web.Accounting.VatReturns
{
    public interface IVatReturnStore
    {
        void Add(int entityId, string periodId, dynamic data, bool isSuccessful, string taxNumber);
        VatReturn GetVatReturnResponse(string vrn, string periodId);
        IEnumerable<VatReturn> GetLogData(string vrn, string periodId);
        bool HasLogErrors(string vrn, string periodId);
    }

    public class VatReturnStore : IVatReturnStore
    {
        readonly IDbContext _dbContext;

        public VatReturnStore(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public void Add(int entityId, string periodId, dynamic data, bool isSuccessful, string taxNumber)
        {
            _dbContext.Set<VatReturn>().Add(new VatReturn
                                            {
                                                EntityId = entityId,
                                                PeriodId = periodId,
                                                Data = JsonConvert.SerializeObject(data),
                                                IsSubmitted = isSuccessful,
                                                TaxNumber = taxNumber
                                            });

            _dbContext.SaveChanges();
        }

        public VatReturn GetVatReturnResponse(string vrn, string periodId)
        {
            return _dbContext.Set<VatReturn>().FirstOrDefault(v => v.TaxNumber == vrn && v.PeriodId == periodId && v.IsSubmitted);
        }

        public IEnumerable<VatReturn> GetLogData(string vrn, string periodId)
        {
            return _dbContext.Set<VatReturn>().Where(v => v.TaxNumber == vrn && v.PeriodId == periodId).OrderByDescending(_ => _.LastModified).ToArray();
        }

        public bool HasLogErrors(string vrn, string periodId)
        {
            var logs = _dbContext.Set<VatReturn>().Where(v => v.TaxNumber == vrn && v.PeriodId == periodId);
            if (!logs.Any()) return false;
            return !logs.Any(q => q.IsSubmitted);
        }
    }
}