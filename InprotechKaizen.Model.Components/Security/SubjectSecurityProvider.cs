using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Security
{
    public class SubjectSecurityProvider : ISubjectSecurityProvider
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly ISubjectSecurityProviderCache _subjectSecurityProviderCache;
        readonly Func<DateTime> _clock;

        public SubjectSecurityProvider(IDbContext dbContext, ISecurityContext securityContext, ISubjectSecurityProviderCache subjectSecurityProviderCache, Func<DateTime> clock)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _subjectSecurityProviderCache = subjectSecurityProviderCache;
            _clock = clock;
        }

        IEnumerable<SubjectAccess> ListAvailableSubjects()
        {
            return AvailableSubjects().Values;
        }

        IDictionary<short, SubjectAccess> AvailableSubjects()
        {
            var identityId = _securityContext.User.Id;
            return _subjectSecurityProviderCache.Resolve(x =>
            {
                return AvailableSubjectsFromDb()
                    .ToDictionary(k => k.TopicId, v => v);
            }, identityId);
        }

        public IQueryable<SubjectAccess> AvailableSubjectsFromDb()
        {
            var today = _clock().Date;

            var subjects = _dbContext.PermissionsGranted(_securityContext.User.Id, "DATATOPIC", null, null, today)
                                     .Where(_ => _.CanSelect);

            return from t in subjects
                   select new SubjectAccess
                   {
                       TopicId = (short)t.ObjectIntegerKey,
                       CanSelect = t.CanSelect
                   };
        }

        public bool HasAccessToSubject(ApplicationSubject subject)
        {
            return ListAvailableSubjects().Any(v => v.TopicId == (short)subject);
        }
    }
}