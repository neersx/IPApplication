using System.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public interface ICaseCorrelationResolver
    {
        int? Resolve(string applicationNumber, out bool areMultipleCases);
    }

    public class CaseCorrelationResolver : ICaseCorrelationResolver
    {
        readonly IInprotechCaseResolver _inprotechCaseResolver;

        public CaseCorrelationResolver(IInprotechCaseResolver inprotechCaseResolver)
        {
            _inprotechCaseResolver = inprotechCaseResolver;
        }

        public int? Resolve(string applicationNumber, out bool areMultipleCases)
        {
            var eligibleCases = _inprotechCaseResolver.ResolveUsing(applicationNumber).ToArray();

            areMultipleCases = eligibleCases.Length > 1;
            if (!eligibleCases.Any() || areMultipleCases)
                return null;

            if (eligibleCases.Length == 1)
                return eligibleCases.First().CaseKey;

            return null;
        }
    }
}