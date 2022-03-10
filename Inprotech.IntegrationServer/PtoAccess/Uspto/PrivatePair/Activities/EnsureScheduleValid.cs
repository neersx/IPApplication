using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Integration.Innography.PrivatePair;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public interface IEnsureScheduleValid
    {
        Task ValidateRequiredSettings(Session session);
    }

    public class EnsureScheduleValid : IEnsureScheduleValid
    {
        readonly IInnographyPrivatePairSettings _privatePairSettings;
        readonly Func<HostInfo> _hostInfoResolver;

        public EnsureScheduleValid(IInnographyPrivatePairSettings privatePairSettings, Func<HostInfo> hostInfoResolver)
        {
            _privatePairSettings = privatePairSettings;
            _hostInfoResolver = hostInfoResolver;
        }

        public Task ValidateRequiredSettings(Session session)
        {
            var setting = _privatePairSettings.Resolve();
            if (!setting.PrivatePairSettings.IsAccountSettingsValid)
                throw new ArgumentException("Unable to access Private PAIR as private pair account details could not be found");

            var dbIdentifier = _hostInfoResolver().DbIdentifier;
            if (!string.Equals(setting.ValidEnvironment, dbIdentifier, StringComparison.CurrentCultureIgnoreCase))
            {
                throw new InvalidOperationException($"This schedule has been blocked from execution: '{dbIdentifier}' is not where sponsorship details were originally added, i.e. '{setting.ValidEnvironment}'.");
            }

            return Task.FromResult(0);
        }
    }
}
