using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Portal
{
    public interface ILinksResolver
    {
        Task<LinksViewModel[]> Resolve();
    }

    public class LinksResolver : ILinksResolver
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IUriHelper _uriHelper;
        readonly ISecurityContext _securityContext;

        public LinksResolver(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver, IUriHelper uriHelper)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _uriHelper = uriHelper;
        }

        public async Task<LinksViewModel[]> Resolve()
        {
            var user = _securityContext.User;
            var culture = _preferredCultureResolver.Resolve();

            var m = ProcessLinks(await ResolveMyLinks(user.Id, culture).ToArrayAsync());
            var q = ProcessLinks(await ResolveQuickLinks(user, culture).ToArrayAsync());

            return new[] { m, q }.Where(_ => _.Links.Any()).ToArray();
        }

        LinksViewModel ProcessLinks(IEnumerable<InterimLink> links)
        {
            var result = new LinksViewModel();

            foreach (var q in links.OrderBy(_ => _.DisplaySequence).Distinct(new InterimLinkComparer()))
            {
                if (!_uriHelper.TryAbsolute(q.RawUrl, out var r))
                {
                    continue;
                }
                result.Group = q.LinkType;

                result.Links.Add(new LinksModel
                {
                    Title = q.Title,
                    Tooltip = q.Tooltip,
                    Url = r
                });
            }

            return result;
        }

        IQueryable<InterimLink> ResolveMyLinks(int userId, string culture)
        {
            return from l in _dbContext.Set<Link>()
                   join tc in _dbContext.Set<TableCode>() on l.CategoryId equals tc.Id
                   where l.CategoryId == (int)LinksCategory.MyLinks && l.IdentityId == userId
                   orderby l.DisplaySequence
                   select new InterimLink
                   {
                       RawUrl = l.Url,
                       DisplaySequence = l.DisplaySequence,
                       LinkType = DbFuncs.GetTranslation(tc.Name, null, tc.NameTId, culture),
                       Tooltip = DbFuncs.GetTranslation(l.Description, null, l.DescriptionTid, culture),
                       Title = DbFuncs.GetTranslation(l.Title, null, l.TitleTid, culture)
                   };
        }

        IQueryable<InterimLink> ResolveQuickLinks(User user, string culture)
        {
            var isExternal = (bool?)user.IsExternalUser;
            var accessAccountId = (int?)user.AccessAccount.Id;
            var links = _dbContext.Set<Link>();
            var quickLinks = _dbContext.Set<TableCode>().Where(_ => _.Id == (int)LinksCategory.Quicklinks);

            return from l in links
                   join q in quickLinks on l.CategoryId equals q.Id
                   join specific in links on new { a = accessAccountId, c = q.Id } equals new { a = specific.AccessAccountId, c = specific.CategoryId } into specific1
                   from specific in specific1.DefaultIfEmpty()
                   join general in links on new { a = (int?)null, e = isExternal, c = q.Id } equals new { a = general.AccessAccountId, e = general.IsExternal, c = general.CategoryId } into general1
                   from general in general1.DefaultIfEmpty()
                   where specific != null && specific.Id == l.Id || specific == null && general != null && general.Id == l.Id
                   select new InterimLink
                   {
                       RawUrl = l.Url,
                       DisplaySequence = l.DisplaySequence,
                       LinkType = DbFuncs.GetTranslation(q.Name, null, q.NameTId, culture),
                       Tooltip = DbFuncs.GetTranslation(l.Description, null, l.DescriptionTid, culture),
                       Title = DbFuncs.GetTranslation(l.Title, null, l.TitleTid, culture)
                   };
        }

        public class InterimLink
        {
            public string Title { get; set; }

            public string Tooltip { get; set; }

            public string LinkType { get; set; }

            public string RawUrl { get; set; }

            public int DisplaySequence { get; set; }
        }

        public class InterimLinkComparer : IEqualityComparer<InterimLink>
        {
            public bool Equals(InterimLink x, InterimLink y)
            {
                if (ReferenceEquals(x, null)) return false;

                if (ReferenceEquals(x, y)) return true;

                return x.LinkType == y.LinkType &&
                       x.RawUrl == y.RawUrl &&
                       x.Title == y.Title &&
                       x.Tooltip == y.Tooltip &&
                       x.DisplaySequence == y.DisplaySequence;
            }

            public int GetHashCode(InterimLink obj)
            {
                return new
                {
                    obj.RawUrl,
                    obj.LinkType,
                    obj.Title,
                    obj.Tooltip,
                    obj.DisplaySequence
                }.GetHashCode();
            }
        }
    }
}