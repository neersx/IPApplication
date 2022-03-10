using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.CaseSupportData
{
    public interface IOffices
    {
        IEnumerable<KeyValuePair<string, string>> Get();
    }

    public class Offices : IOffices
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public Offices(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public IEnumerable<KeyValuePair<string, string>> Get()
        {
            var results = _dbContext.GetOffices(_securityContext.User.Id,
                                                _preferredCultureResolver.Resolve(),
                                                _securityContext.User.IsExternalUser);

            return results.Select(_ => new KeyValuePair<string, string>(_.OfficeKey.ToString(), _.OfficeDescription));
        }
    }
}