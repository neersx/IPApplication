using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Analytics
{
    public interface IServerTransactionDataQueue
    {
        Task<IEnumerable<T>> Dequeue<T>(params string[] eventTypes) where T : RawEventData, new();
    }

    public class ServerTransactionDataQueue : IServerTransactionDataQueue
    {
        readonly IRepository _repository;

        public ServerTransactionDataQueue(IRepository repository)
        {
            _repository = repository;
        }

        public async Task<IEnumerable<T>> Dequeue<T>(params string[] eventTypes) where T : RawEventData, new() 
        {
            var raw = await (from e in _repository.Set<ServerTransactionalDataSink>()
                             where eventTypes.Contains(e.Event)
                             select new T
                             {
                                 Id = e.Id,
                                 Value = e.Value
                             })
                .ToArrayAsync();

            var ids = raw.Select(_ => _.Id).ToArray();
            var maxDeleted = 1000;
            while (ids.Any())
            {
                var interimIds = ids.Take(maxDeleted).ToArray();
                await _repository.DeleteAsync(from r in _repository.Set<ServerTransactionalDataSink>()
                                              where interimIds.Contains(r.Id)
                                              select r);
                ids = ids.Except(interimIds).ToArray();
            }

            return raw;
        }
    }

    public class RawEventData
    {
        public long Id { get; set; }

        public string Value { get; set; }
    }
}