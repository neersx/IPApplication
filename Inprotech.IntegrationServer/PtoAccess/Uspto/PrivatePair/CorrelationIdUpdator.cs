using System;
using Inprotech.Integration;
using Inprotech.Integration.Persistence;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public interface ICorrelationIdUpdator
    {
        void UpdateIfRequired(Case @case);
        void CheckIfValid(Case @case);
    }

    public class CorrelationIdUpdator : ICorrelationIdUpdator
    {
        readonly IRepository _repository;
        readonly ICaseCorrelationResolver _caseCorrelationResolver;
        readonly Func<DateTime> _now;

        public CorrelationIdUpdator(IRepository repository,
            ICaseCorrelationResolver caseCorrelationResolver,
            Func<DateTime> now)
        {
            _repository = repository;
            _caseCorrelationResolver = caseCorrelationResolver;
            _now = now;
        }

        public void CheckIfValid(Case @case)
        {
            if (@case == null || @case.Source != DataSourceType.UsptoPrivatePair) return;

            var newCorrelationId = _caseCorrelationResolver.Resolve(@case.ApplicationNumber, out bool areMultipleCases);

            if (areMultipleCases)
                throw new MultiplePossibleInprotechCasesException();

            if (newCorrelationId != @case.CorrelationId)
                throw new CorrespondingCaseChangedException();
        }

        public void UpdateIfRequired(Case @case)
        {
            if (@case == null || @case.Source != DataSourceType.UsptoPrivatePair) return;

            var newCorrelationId = _caseCorrelationResolver.Resolve(@case.ApplicationNumber, out bool areMultipleCases);

            if (newCorrelationId != @case.CorrelationId)
            {
                @case.CorrelationId = newCorrelationId;
                @case.UpdatedOn = _now();
                _repository.SaveChanges();
            }

            if (areMultipleCases)
                throw new MultiplePossibleInprotechCasesException();
        }
    }
}