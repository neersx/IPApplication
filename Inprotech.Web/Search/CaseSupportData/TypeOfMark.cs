using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.CaseSupportData
{
    public interface ITypeOfMark
    {
        IEnumerable<KeyValuePair<int, string>> Get();
    }

    public class TypeOfMark : ITypeOfMark
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public TypeOfMark(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver)
        {
            if(dbContext == null) throw new ArgumentNullException("dbContext");
            if(securityContext == null) throw new ArgumentNullException("securityContext");
            if(preferredCultureResolver == null) throw new ArgumentNullException("preferredCultureResolver");

            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public IEnumerable<KeyValuePair<int, string>> Get()
        {
            return _dbContext.GetTypeOfMarkList(
                                           _securityContext.User.Id,
                                           _preferredCultureResolver.Resolve(),
                                           _securityContext.User.IsExternalUser)
                             .Select(a => new KeyValuePair<int, string>(a.Key, a.Description));
        }
    }
}