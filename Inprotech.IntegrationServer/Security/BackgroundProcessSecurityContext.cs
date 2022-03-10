using System;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.IntegrationServer.Security
{
    public class BackgroundProcessSecurityContext : ISecurityContext
    {
        const string BackgroundProcessIdentitySiteControlRequired =
            @"'{0}' site control value is required for background process to proceed.";

        const string BackgroundProcessIdentitySiteControlIncorrect =
            @"'{0}' site control value must point to a valid user Login Id.";

        readonly ISiteControlReader _siteControlReader;
        readonly IDbContext _dbContext;
        readonly WebSecurityContext _webSecurityContext;

        User _user;

        public BackgroundProcessSecurityContext(ISiteControlReader siteControlReader, IDbContext dbContext, WebSecurityContext webSecurityContext)
        {
            _siteControlReader = siteControlReader;
            _dbContext = dbContext;
            _webSecurityContext = webSecurityContext;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1065:DoNotRaiseExceptionsInUnexpectedLocations")]
        public User User
        {
            get
            {
                if (_user != null)
                    return _user;

                // Integration Server hosts external access APIs
                // The x-username custom will be validated and a user entity returns.
                // the identity will also flow through transaction recordal and any
                // stored procedure calls.

                _user = _webSecurityContext.User;
                if (_user != null)
                    return _user;

                // The BackgroundProcessSecurityContext is designed to be used in the Integration Server 
                // specifically for performing background processes which involves making changes to data.
                // The identity discovered below will be used to retrieve data via stored procedures and 
                // data changes are recorded in LOGIDENTITY column for areas where audit trail is required.

                var username = _siteControlReader.Read<string>(SiteControls.BackgroundProcessLoginId);
                if (string.IsNullOrWhiteSpace(username))
                    throw new ApplicationException(
                        string.Format(BackgroundProcessIdentitySiteControlRequired, SiteControls.BackgroundProcessLoginId));

                _user = _dbContext.Set<User>()
                    .Include(_ => _.Name)
                    .SingleOrDefault(_ => _.UserName == username);

                if (_user == null)
                    throw new ApplicationException(
                        string.Format(BackgroundProcessIdentitySiteControlIncorrect, SiteControls.BackgroundProcessLoginId));

                return _user;
            }
        }

        public int IdentityId => User.Id;
    }
}