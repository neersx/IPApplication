using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Rules.ScreenDesigner.Cases
{
    public interface ICaseScreenDesignerSearch
    {
        IEnumerable<CaseScreenDesignerListItem> Search(SearchCriteria filter);
        IEnumerable<CaseScreenDesignerListItem> Search(int[] ids);
        IEnumerable<CodeDescription> GetFilterDataForColumnResult(IEnumerable<CaseScreenDesignerListItem> result, string column);

    }

    public class CaseScreenDesignerSearch : ICaseScreenDesignerSearch
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly ICommonQueryService _commonQueryService;
        public CaseScreenDesignerSearch(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver, ICommonQueryService commonQueryService)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (securityContext == null) throw new ArgumentNullException("securityContext");
            if (preferredCultureResolver == null) throw new ArgumentNullException("preferredCultureResolver");

            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _commonQueryService = commonQueryService;
        }

        public IEnumerable<CaseScreenDesignerListItem> Search(SearchCriteria filter)
        {
            return _dbContext.CaseScreenDesignerSearch(_securityContext.User.Id,
                                                       _preferredCultureResolver.Resolve(),
                                                       filter);
        }

        public IEnumerable<CaseScreenDesignerListItem> Search(int[] ids)
        {
            return _dbContext.CaseScreenDesignerSearchByIds(_securityContext.User.Id,
                                                       _preferredCultureResolver.Resolve(),
                                                       ids);
        }
        public IEnumerable<CodeDescription> GetFilterDataForColumnResult(IEnumerable<CaseScreenDesignerListItem> result, string field)
        {
            if (string.IsNullOrWhiteSpace(field)) return new List<CodeDescription>();

            switch (field.ToLower())
            {
                case "jurisdiction":
                    return result
                           .Where(_ => !string.IsNullOrWhiteSpace(_.JurisdictionDescription))
                           .OrderBy(_ => _.JurisdictionDescription)
                           .Select(
                                   _ =>
                                       _commonQueryService.BuildCodeDescriptionObject(_.JurisdictionCode, _.JurisdictionDescription))
                           .Distinct();
                case "program":
                    return result
                           .Where(_ => !string.IsNullOrWhiteSpace(_.ProgramId))
                           .OrderBy(_ => _.ProgramName)
                           .Select(_ => _commonQueryService.BuildCodeDescriptionObject(_.ProgramId, _.ProgramName))
                           .Distinct();
            }
            return new List<CodeDescription>();
        }
    }
}