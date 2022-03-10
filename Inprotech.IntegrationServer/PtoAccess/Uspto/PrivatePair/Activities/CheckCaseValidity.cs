using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Persistence;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public interface ICheckCaseValidity
    {
        Task IsValid(string applicationNumber);
    }

    public class CheckCaseValidity : ICheckCaseValidity
    {
        readonly IRepository _repository;
        readonly ICorrelationIdUpdator _correlationIdUpdator;

        public CheckCaseValidity(IRepository repository, ICorrelationIdUpdator correlationIdUpdator)
        {
            _repository = repository;
            _correlationIdUpdator = correlationIdUpdator;
        }

        public Task IsValid(string applicationNumber)
        {
            var @case =
                _repository.Set<Case>()
                    .SingleOrDefault(
                        _ =>
                            string.Equals(_.ApplicationNumber, applicationNumber) && _.Source == DataSourceType.UsptoPrivatePair);
            return Task.Run(() => _correlationIdUpdator.UpdateIfRequired(@case));
        }
    }
}