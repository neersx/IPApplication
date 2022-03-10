using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.CaseSupportData
{
    public interface IRenewalStatuses
    {
        IEnumerable<KeyValuePair<int, string>> Get(string q, bool isPending, bool isRegistered, bool isDead);
    }

    public class RenewalStatuses : IRenewalStatuses
    {
        readonly ICaseStatuses _caseStatuses;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public RenewalStatuses(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver, ICaseStatuses caseStatuses)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (securityContext == null) throw new ArgumentNullException("securityContext");
            if (preferredCultureResolver == null) throw new ArgumentNullException("preferredCultureResolver");
            if (caseStatuses == null) throw new ArgumentNullException("caseStatuses");

            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _caseStatuses = caseStatuses;
        }

        public IEnumerable<KeyValuePair<int, string>> Get(string q, bool isPending, bool isRegistered, bool isDead)
        {
            if (!_securityContext.User.IsExternalUser)
                return _caseStatuses.Get(q, true, isPending, isRegistered, isDead);

            q = q ?? string.Empty;

            Func<ExternalRenewalStatusListItem, bool> statusFilter;

            if ((isDead || isPending) && isRegistered)
                statusFilter = a => a.LiveFlag == isPending || a.RegisteredFlag == true;
            else if (!isDead && !isPending && isRegistered)
                statusFilter = a => a.RegisteredFlag == true;
            else if (!isDead && isPending)
                statusFilter = a => a.LiveFlag == true;
            else if (isDead && !isPending)
                statusFilter = a => a.LiveFlag == false;
            else if (isDead)
                statusFilter = a => a.LiveFlag != null;
            else
                statusFilter = a => true;

            var filters = new[]
                          {
                              statusFilter,
                              a => a.StatusDescription.StartsWith(q, StringComparison.OrdinalIgnoreCase)
                          };

            var results = _dbContext.GetExternalRenewalStatuses(
                                                                _securityContext.User.Id,
                                                                _preferredCultureResolver.Resolve())
                                    .Where(a => filters.All(filter => filter(a)))
                                    .ToArray();

            return results.OrderBy(a => a.StatusDescription)
                          .Select(a => new KeyValuePair<int, string>(a.StatusKey, a.StatusDescription));
        }
    }
}