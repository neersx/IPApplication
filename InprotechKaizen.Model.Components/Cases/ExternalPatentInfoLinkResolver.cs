using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface IExternalPatentInfoLinkResolver
    {
        bool Resolve(string caseRef, string countryCode, string number, out Uri externalLink);
        bool Resolve(string caseRef, int docItemId, out Uri externalLink);

        Dictionary<int, Uri> ResolveOfficialNumbers(string caseRef, int[] docItems);

        Dictionary<(string countryCode, string officialNumber), Uri> ResolveRelatedCases(string caseRef, (string countryCode, string officialNumber)[] countryOfficialNumbers);
    }

    public class ExternalPatentInfoLinkResolver : IExternalPatentInfoLinkResolver
    {
        readonly IDbContext _dbContext;
        readonly IDocItemRunner _docItemRunner;
        readonly ISecurityContext _securityContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public ExternalPatentInfoLinkResolver(IDbContext dbContext, ISecurityContext securityContext, IDocItemRunner docItemRunner, ITaskSecurityProvider taskSecurityProvider)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _docItemRunner = docItemRunner;
            _taskSecurityProvider = taskSecurityProvider;
        }

        public bool Resolve(string caseRef, int docItemId, out Uri externalLink)
        {
            var res = ResolveOfficialNumbers(caseRef, new[] { docItemId });
            return res.TryGetValue(docItemId, out externalLink);
        }

        public bool Resolve(string caseRef, string countryCode, string number, out Uri externalLink)
        {
            var res = ResolveRelatedCases(caseRef, new[] {(countryCode, number)});
            return res.TryGetValue((countryCode, number), out externalLink);
        }

        public Dictionary<int, Uri> ResolveOfficialNumbers(string caseRef, int[] docItems)
        {
            if (string.IsNullOrWhiteSpace(caseRef)) throw new ArgumentNullException(nameof(caseRef));

            var user = _securityContext.User;
            if (user.IsExternalUser || !docItems.Any() || !_taskSecurityProvider.HasAccessTo(ApplicationTask.ViewExternalPatentInformation))
                return new Dictionary<int, Uri>();

            var numbers = new Dictionary<int, Uri>();
            var p = DefaultDocItemParameters.ForDocItemSqlQueries();
            p["gstrEntryPoint"] = caseRef;
            p["gstrUserId"] = user.Id;

            foreach (var docItemKey in docItems.Distinct())
            {
                var result = _docItemRunner.Run(docItemKey, p).ScalarValueOrDefault<string>();

                if (string.IsNullOrWhiteSpace(result) || !Uri.TryCreate(result, UriKind.Absolute, out var externalLink))
                    continue;

                numbers.Add(docItemKey, externalLink);
            }

            return numbers;
        }

        public Dictionary<(string countryCode, string officialNumber), Uri> ResolveRelatedCases(string caseRef, (string countryCode, string officialNumber)[] countryOfficialNumbers)
        {
            if (string.IsNullOrWhiteSpace(caseRef)) throw new ArgumentNullException(nameof(caseRef));

            var numbers = new Dictionary<(string countryCode, string officialNumber), Uri>();
            var user = _securityContext.User;
            if (user.IsExternalUser
                || !countryOfficialNumbers.Any()
                || !_taskSecurityProvider.HasAccessTo(ApplicationTask.ViewExternalPatentInformation))
                return numbers;

            var item = (from d in _dbContext.Set<DocItem>()
                              join sc in _dbContext.Set<SiteControl>() on SiteControls.LinkFromRelatedOfficialNumber equals sc.ControlId into sc1
                              from sc in sc1
                              where sc.StringValue == d.Name
                              select new
                              {
                                  d.Id,
                                  d.Name
                              }).SingleOrDefault();

            if (item == null) return numbers;

            var p = DefaultDocItemParameters.ForDocItemSqlQueries();
            p["gstrEntryPoint"] = caseRef;
            p["gstrUserId"] = user.Id;

            foreach (var kvp in countryOfficialNumbers.Distinct())
            {
                if (string.IsNullOrEmpty(kvp.countryCode) || string.IsNullOrEmpty(kvp.officialNumber))
                    continue;

                p["p1"] = kvp.countryCode;
                p["p2"] = kvp.officialNumber.Replace("-", string.Empty);
                var result = _docItemRunner.Run(item.Id, p).ScalarValueOrDefault<string>();

                if (string.IsNullOrWhiteSpace(result) || !Uri.TryCreate(result, UriKind.Absolute, out var externalLink))
                    continue;

                numbers.Add(kvp, externalLink);
            }

            return numbers;
        }
    }
}