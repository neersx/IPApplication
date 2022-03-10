using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.ExternalApplications;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Security.Authorization
{
    public class ExpiredAccessTokens
    {
        readonly IRepository _repository;
        readonly Func<DateTime> _now;

        public ExpiredAccessTokens(IRepository repository, Func<DateTime> now)
        {
            _repository = repository;
            _now = now;
        }
        
        public async Task Remove()
        {
            var nowUtc = _now().ToUniversalTime();

            await _repository.DeleteAsync(_repository.Set<OneTimeToken>().Where(_ => nowUtc > _.ExpiryDate));
        }
    }
}