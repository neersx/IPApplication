using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration.KeepOnTopNotes;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.KeepOnTopNotes.Kot16
{
    public class KeepOnTopNotesView : IKeepOnTopNotesView
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly IDisplayFormattedName _formattedName;
        readonly ISiteControlReader _siteControlReader;

        public KeepOnTopNotesView(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ISiteControlReader siteControlReader,
                                  ISecurityContext securityContext, IDisplayFormattedName formattedName)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _siteControlReader = siteControlReader;
            _securityContext = securityContext;
            _formattedName = formattedName;
        }

        public async Task<IEnumerable<KotNotesItem>> GetKotNotesForCase(int caseId, string program)
        {
            var culture = _preferredCultureResolver.Resolve();
            var allowedKot = GetAllowedKot(KnownKotTypes.Case, program);
            var roles = _securityContext.User.Roles;

            var kotHavingCaseType = from k in allowedKot
                                  join ck in _dbContext.Set<KeepOnTopCaseType>() on k.Id equals ck.KotTextTypeId into ck1
                                  from ck in ck1.DefaultIfEmpty()
                                  join c in _dbContext.Set<Case>() on caseId equals c.Id
                                  where ck == null || ck.CaseTypeId == c.TypeId 
                                  select k.Id;

            var firstKotCaseTextInCase = from ct in _dbContext.Set<CaseText>()
                                         where (ct.IsLongText == 1 && ct.LongText != null || ct.IsLongText != 1 && ct.ShortText != null) && ct.CaseId == caseId
                                         group ct by ct.Type
                                         into ctg
                                         select ctg.OrderByDescending(_ => _.Number).FirstOrDefault();

            var interimResults = await (from k in allowedKot
                                        join tt in _dbContext.Set<TextType>() on k.TextTypeId equals tt.Id
                                        join ct in firstKotCaseTextInCase on k.TextTypeId equals ct.Type
                                        join c in _dbContext.Set<Case>() on ct.CaseId equals c.Id
                                        join cs in _dbContext.Set<Status>() on c.StatusCode equals cs.Id into cs1
                                        from cs in cs1.DefaultIfEmpty()
                                        where kotHavingCaseType.Contains(k.Id)
                                              && (!string.IsNullOrEmpty(ct.ShortText) || !string.IsNullOrEmpty(ct.LongText))
                                              && (!k.IsRegistered && !k.IsDead && !k.IsPending || c.CaseStatus == null
                                                                                               || k.IsPending && cs.LiveFlag == 1 && (cs.RegisteredFlag == 0 || cs.RegisteredFlag == null)
                                                                                               || k.IsRegistered && cs.RegisteredFlag == 1
                                                                                               || k.IsDead && (cs.LiveFlag == 0 || cs.LiveFlag == null))
                                        select new
                                        {
                                            k.Id,
                                            Note = ct.IsLongText == 1
                                                ? DbFuncs.GetTranslation(null, ct.LongText, ct.LongTextTId, culture)
                                                : DbFuncs.GetTranslation(ct.ShortText, null, ct.ShortTextTId, culture),
                                            k.BackgroundColor,
                                            CaseRef = c.Irn,
                                            TextType = DbFuncs.GetTranslation(null, tt.TextDescription, tt.TextDescriptionTId, culture)
                                        }).ToArrayAsync();

            var kotWithRolesAllowed = (from k in interimResults
                           join rk in _dbContext.Set<KeepOnTopRole>() on k.Id equals rk.KotTextTypeId into rk1
                           from rk in rk1.DefaultIfEmpty()
                           where (rk == null && !_securityContext.User.IsExternalUser) || (rk != null && roles.Any(r => r.Id == rk.RoleId))
                           select k.Id).Distinct();

            var results = interimResults.Where(_ => kotWithRolesAllowed.Contains(_.Id))
                          .Select(_ => new KotNotesItem
                          {
                              Note = _.Note,
                              BackgroundColor = _.BackgroundColor,
                              CaseRef = _.CaseRef,
                              TextType = _.TextType
                          });

            var caseNamesNotes = await GetKotNotesForCaseNames(caseId, program, roles);
            return caseNamesNotes != null ? results.Concat(caseNamesNotes) : results;
        }

        async Task<IEnumerable<KotNotesItem>> GetKotNotesForCaseNames(int caseId, string program, ICollection<Role> roles)
        {
            var culture = _preferredCultureResolver.Resolve();
            var userId = _securityContext.User.Id;
            var isExternalUser = _securityContext.User.IsExternalUser;
            var screenControlName = _siteControlReader.Read<string>(SiteControls.CRMScreenControlProgram) ?? string.Empty;

            var kotCase = await _dbContext.Set<Case>().FirstOrDefaultAsync(_ => _.Id == caseId);
            if (kotCase == null) return null;

            var screenControlNameTypes =
                await (from c in _dbContext.Set<Case>()
                       join ct in _dbContext.Set<CaseType>() on c.TypeId equals ct.Code
                       where ct.CrmOnly == true && c.Id == caseId
                       select c).AnyAsync()
                    ? await _dbContext.GetScreenControlNameTypes(userId, caseId, screenControlName).ToArrayAsync()
                    : new string[0];

            var allowedKot = GetAllowedKot(KnownKotTypes.Name, program);

            var allowedCaseNames = from cn in _dbContext.Set<CaseName>()
                                   join cnt in _dbContext.Set<NameType>() on cn.NameTypeId equals cnt.NameTypeCode
                                   join fnt in _dbContext.FilterUserNameTypes(userId, culture, isExternalUser, false)
                                       on cn.NameTypeId equals fnt.NameType
                                   join ipn in _dbContext.Set<ClientDetail>() on cn.NameId equals ipn.Id into ipn1
                                   from ipn in ipn1.DefaultIfEmpty()
                                   where cn.CaseId == caseId
                                   select new
                                   {
                                       cn.CaseId,
                                       cn.NameId,
                                       cn.NameTypeId,
                                       NameTypeDesc = cnt.Name,
                                       NameTypeDescTid = cnt.NameTId,
                                       Correspondence = ipn != null ? ipn.Correspondence : null,
                                       CorrespondenceTid = ipn != null ? ipn.CorrespondenceTid : null
                                   };

            var configuredKot = from k in allowedKot
                                join tt in _dbContext.Set<TextType>() on k.TextTypeId equals tt.Id
                                join nk in _dbContext.Set<KeepOnTopNameType>() on k.Id equals nk.KotTextTypeId into nk1
                                from nk in nk1.DefaultIfEmpty()
                                select new
                                {
                                    k.Id,
                                    k.BackgroundColor,
                                    k.TextTypeId,
                                    tt.TextDescription,
                                    tt.TextDescriptionTId,
                                    nk.NameTypeId
                                };

            var interimResults = await (from k in configuredKot
                                        join cn in allowedCaseNames on caseId equals cn.CaseId
                                        join txt in _dbContext.Set<NameText>() on new { Id = cn.NameId, tt = k.TextTypeId } equals new { txt.Id, tt = txt.TextType } into txt1
                                        from txt in txt1.DefaultIfEmpty()
                                        where k.NameTypeId == null || k.NameTypeId == cn.NameTypeId
                                              && (txt != null && !string.IsNullOrEmpty(txt.Text) ||
                                                  (cn != null && CorrespondenceNameTypes.NameTypes.Contains(k.TextTypeId) && !string.IsNullOrEmpty(cn.Correspondence)))
                                              && (!screenControlNameTypes.Any() || screenControlNameTypes.Contains(cn.NameTypeId))
                                        select new
                                        {
                                            k.Id,
                                            cn.NameId,
                                            NameTypes = DbFuncs.GetTranslation(null, cn.NameTypeDesc, cn.NameTypeDescTid, culture),
                                            Note = txt != null
                                                ? DbFuncs.GetTranslation(null, txt.Text, txt.TextTid, culture)
                                                : DbFuncs.GetTranslation(null, cn.Correspondence, cn.CorrespondenceTid, culture),
                                            k.BackgroundColor,
                                            k.TextTypeId,
                                            TextType = DbFuncs.GetTranslation(null, k.TextDescription, k.TextDescriptionTId, culture)
                                        }).Where(_ => !string.IsNullOrEmpty(_.Note)).ToArrayAsync();

            var kotWithRolesAllowed = (from k in interimResults
                                       join rk in _dbContext.Set<KeepOnTopRole>() on k.Id equals rk.KotTextTypeId into rk1
                                       from rk in rk1.DefaultIfEmpty()
                                       where (rk == null && !_securityContext.User.IsExternalUser) || (rk != null && roles.Any(r => r.Id == rk.RoleId))
                                       select k.Id).Distinct();

            var result = interimResults.Where(_ => kotWithRolesAllowed.Contains(_.Id))
                                        .GroupBy(_ => new { _.NameId, _.TextTypeId }).Select(_ => new KotNotesItem
                                        {
                                            NameId = _.First().NameId,
                                            NameTypes = string.Join(", ", _.Select(nt => nt.NameTypes)),
                                            Note = _.First().Note,
                                            BackgroundColor = _.First().BackgroundColor,
                                            TextType = _.First().TextType
                                        }).ToArray();

            await GetFormattedName(result);

            return result;
        }

        public async Task<IEnumerable<KotNotesItem>> GetKotNotesForName(int nameId, string program)
        {
            var culture = _preferredCultureResolver.Resolve();
            var roles = _securityContext.User.Roles;
            var allowedKot = GetAllowedKot(KnownKotTypes.Name, program);

            var nameWithCorrespondenceInstructions = from n in _dbContext.Set<Name>()
                                                     join cd in _dbContext.Set<ClientDetail>() on n.Id equals cd.Id into cd1
                                                     from cd in cd1.DefaultIfEmpty()
                                                     select new
                                                     {
                                                         n.Id,
                                                         Correspondence = cd != null ? cd.Correspondence : null,
                                                         CorrespondenceTid = cd != null ? cd.CorrespondenceTid : null
                                                     };
            var nameTypesAllowed = from ntc in _dbContext.Set<NameTypeClassification>()
                                   join nt in _dbContext.Set<NameType>() on ntc.NameTypeId equals nt.NameTypeCode
                                   where ntc.IsAllowed == 1 && ntc.NameId == nameId
                                   select new
                                   {
                                       ntc.NameId,
                                       ntc.NameTypeId,
                                       NameTypeDesc = nt.Name,
                                       NameTypeDescTid = nt.NameTId
                                   };

            var caseNameTypesUsedForName = (from cn in _dbContext.Set<CaseName>()
                                           join cnt in _dbContext.Set<NameType>() on cn.NameTypeId equals cnt.NameTypeCode
                                           where cn.NameId == nameId
                                           select new
                                           {
                                               cn.NameTypeId, 
                                               NameTypeDesc = cnt.Name,
                                               NameTypeDescTid = cnt.NameTId
                                           }).Distinct();

            var configuredKot = from k in allowedKot
                                join tt in _dbContext.Set<TextType>() on k.TextTypeId equals tt.Id
                                join nk in _dbContext.Set<KeepOnTopNameType>() on k.Id equals nk.KotTextTypeId into nk1
                                from nk in nk1.DefaultIfEmpty()
                                select new
                                {
                                    k.Id,
                                    k.BackgroundColor,
                                    k.TextTypeId,
                                    tt.TextDescription,
                                    tt.TextDescriptionTId,
                                    nk.NameTypeId
                                };

            var interimResults = await (from k in configuredKot
                                        join n in nameWithCorrespondenceInstructions on nameId equals n.Id
                                        join nt in _dbContext.Set<NameText>() on new { n.Id, type = k.TextTypeId } equals new { nt.Id, type = nt.TextType } into nt1
                                        from nt in nt1.DefaultIfEmpty()
                                        join cn in caseNameTypesUsedForName on k.NameTypeId equals cn.NameTypeId into cn1
                                        from cn in cn1.DefaultIfEmpty()
                                        join ntc in nameTypesAllowed on k.NameTypeId equals ntc.NameTypeId into ntc1
                                        from ntc in ntc1.DefaultIfEmpty()
                                        where (k.NameTypeId == null || cn != null || ntc != null)
                                              && ((nt != null && !string.IsNullOrEmpty(nt.Text)) 
                                                  || (CorrespondenceNameTypes.NameTypes.Contains(k.TextTypeId) && !string.IsNullOrEmpty(n.Correspondence)))
                                        select new
                                        {
                                            k.Id,
                                            NameId = n.Id,
                                            NameTypes = cn != null ? DbFuncs.GetTranslation(null, cn.NameTypeDesc, cn.NameTypeDescTid, culture) :
                                                DbFuncs.GetTranslation(null, ntc.NameTypeDesc, ntc.NameTypeDescTid, culture),
                                            Note = nt != null
                                                ? DbFuncs.GetTranslation(null, nt.Text, nt.TextTid, culture)
                                                : DbFuncs.GetTranslation(null, n.Correspondence, n.CorrespondenceTid, culture),
                                            k.BackgroundColor,
                                            k.TextTypeId,
                                            TextType = DbFuncs.GetTranslation(null, k.TextDescription, k.TextDescriptionTId, culture)
                                        }).Where(_ => !string.IsNullOrEmpty(_.Note)).ToArrayAsync();

            var kotWithRolesAllowed = (from k in interimResults
                                       join rk in _dbContext.Set<KeepOnTopRole>() on k.Id equals rk.KotTextTypeId into rk1
                                       from rk in rk1.DefaultIfEmpty()
                                       where (rk == null && !_securityContext.User.IsExternalUser) || (rk != null && roles.Any(r => r.Id == rk.RoleId))
                                       select k.Id).Distinct();

            var result = interimResults.Where(_ => kotWithRolesAllowed.Contains(_.Id))
                                        .GroupBy(_ => new { _.NameId, _.TextTypeId }).Select(_ => new KotNotesItem
                                        {
                                            NameId = _.First().NameId,
                                            NameTypes = string.Join(", ", _.Select(nt => nt.NameTypes)),
                                            Note = _.First().Note,
                                            BackgroundColor = _.First().BackgroundColor,
                                            TextType = _.First().TextType
                                        }).ToArray();

            await GetFormattedName(result);

            return result;
        }

        IQueryable<KeepOnTopTextType> GetAllowedKot(string type, string program)
        {
            var kotProgram = (KotProgram)Enum.Parse(typeof(KotProgram), program);
            return _dbContext.Set<KeepOnTopTextType>().Where(_ => _.Type == type
                                                                  && (kotProgram == KotProgram.Case && _.CaseProgram
                                                                       || kotProgram == KotProgram.Name && _.NameProgram
                                                                       || kotProgram == KotProgram.Billing && _.BillingProgram
                                                                       || kotProgram == KotProgram.TaskPlanner && _.TaskPlannerProgram
                                                                       || kotProgram == KotProgram.Time && _.TimeProgram));
        }

        async Task GetFormattedName(KotNotesItem[] result)
        {
            if (!result.Any())
            {
                return;
            }
            var nameIds = result.Where(_ => _.NameId.HasValue).Select(_ => _.NameId.Value).ToArray();
            var formattedNames = await _formattedName.For(nameIds);
            foreach (var r in result)
            {
                if (r.NameId == null) continue;

                r.Name = formattedNames?.Get(r.NameId.Value).Name;
            }
        }
    }
}