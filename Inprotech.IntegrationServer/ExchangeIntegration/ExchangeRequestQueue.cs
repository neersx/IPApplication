using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.ExchangeIntegration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.ExchangeIntegration
{
    public interface IRequestQueue
    {
        Task<ExchangeRequest> NextRequest();
        Task Completed(long id);
        Task Failed(long id, string message, short status);
    }

    public class ExchangeRequestQueue : IRequestQueue
    {
        readonly IDbContext _dbContext;

        public ExchangeRequestQueue(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<ExchangeRequest> NextRequest()
        {
            using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var request = await _dbContext.Set<ExchangeRequestQueueItem>()
                                              .Where(_ => _.StatusId == (short) ExchangeRequestStatus.Ready)
                                              .OrderBy(_ => _.Id)
                                              .FirstOrDefaultAsync();

                if (request == null)
                {
                    return null;
                }

                request.StatusId = KnownStatuses.Success;
                request.ErrorMessage = null;

                await _dbContext.SaveChangesAsync();

                tcs.Complete();

                return new ExchangeRequest
                {
                    Id = request.Id,
                    StaffId = request.StaffId,
                    SequenceDate = request.SequenceDate,
                    RequestTypeId = request.RequestTypeId,
                    RequestType = (ExchangeRequestType) request.RequestTypeId,
                    UserId = request.IdentityId,
                    Context = Guid.NewGuid()
                };
            }
        }

        public async Task Completed(long id)
        {
            using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var model = await _dbContext
                                  .Set<ExchangeRequestQueueItem>()
                                  .SingleAsync(_ => _.Id == id);

                _dbContext.Set<ExchangeRequestQueueItem>().Remove(model);
                await _dbContext.SaveChangesAsync();
                tcs.Complete();
            }
        }

        public async Task Failed(long id, string message, short status)
        {
            using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var model = await _dbContext
                                  .Set<ExchangeRequestQueueItem>()
                                  .SingleAsync(_ => _.Id == id);

                model.StatusId = status;
                model.ErrorMessage = message;
                await _dbContext.SaveChangesAsync();
                tcs.Complete();
            }
        }
    }

    public class ExchangeRequest
    {
        public long Id { get; set; }
        public int StaffId { get; set; }
        public DateTime SequenceDate { get; set; }
        public short RequestTypeId { get; set; }
        public ExchangeRequestType RequestType { get; set; }
        public int? UserId { get; set; }
        public Guid Context { get; set; }
    }
}