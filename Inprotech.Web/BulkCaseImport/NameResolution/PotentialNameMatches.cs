using System;
using System.Collections.Generic;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Cases.BulkCaseImport;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.BulkCaseImport.NameResolution
{
    public interface IPotentialNameMatches
    {
        IEnumerable<PotentialNameMatchItem> For(
            string name,
            string givenName,
            int? restrictToOffice,
            bool? useStreetAddress,
            bool? removeNoiseChars,
            string restrictByNameType);
    }

    public class PotentialNameMatches : IPotentialNameMatches
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        
        public PotentialNameMatches(IDbContext dbContext, ISecurityContext securityContext,
            IPreferredCultureResolver preferredCultureResolver)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (securityContext == null) throw new ArgumentNullException("securityContext");
            if (preferredCultureResolver == null) throw new ArgumentNullException("preferredCultureResolver");
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public IEnumerable<PotentialNameMatchItem> For(
            string name,
            string givenName,
            int? restrictToOffice,
            bool? useStreetAddress,
            bool? removeNoiseChars,
            string restrictByNameType)
        {
            return _dbContext.GetPotentialNameMatches(
                _securityContext.User.Id,
                _preferredCultureResolver.Resolve(),
                name,
                givenName,
                restrictToOffice,
                useStreetAddress,
                removeNoiseChars,
                restrictByNameType);
        }
    }
}